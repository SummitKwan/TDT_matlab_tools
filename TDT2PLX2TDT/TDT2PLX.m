function TDT2PLX(tank,blocks,varargin)
% 
% aim:         convert multiple TDT blocks to a single plx file for sorting
% requires:    TDT OpenDeveloper, PLX SDK, TDT2mat, uipickfiles
% based on:    script provided by Daniel Stolzberg
% improvement: 1) gui select tank and blocks
%              2) support any naming convention for blocks
%              3) time increment for all channels are the same (block 
%              length) for each block
%              3) store tank name(with path) and block names in a separate
%              .dat file and put the dat file name in the comment field of
%              plx file
% example:
%     TDT2PLX('D:\temp\temp_tank', {'Block-1','Block-2'});
%     TDT2PLX('', {});
% 
% ---------- Shaobo Guan, 2014-0808, FRI ----------
% Sheinberg lab, Brown University, USA, Shaobo_Guan@brown.edu
%
% 
% 
% 
% 
% 
% TDT2PLX(TANK,BLOCKS)
% TDT2PLX(...,parameter,'value',..)
%
%   TANK is a string (char) to the absolute path to the tank or the name of
%   a registered tank.
%
%   BLOCKS is a cell array of block names.  All blocks from the specified
%   tank will be selected if left empty (default).
%
%   parameter       default value
%   ---------       -------------
%   PLXDIR          (tank dir)      % Directory to save PLX files
%   SERVER          'Local';        % Tank server
%   EVENT           (depends)       % Event name.  If not specified, then
%                                     the default event will be the first
%                                     snip type event.
%
% See also, PLX2TDT
%
% DJS 2013
%
% Daniel.Stolzberg at gmail dot com


% defaults are modifiable using varargin parameter, value pairs
PLXDIR        = [];
SERVER        = 'Local';
EVENT         = [];

% [[[[[[[[[[ gap interval between blocks, in sec
ts_gap = 30;
% ]]]]]]]]]]

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end


% Select Tank and Blocks
% ========== ==========
% [[[[[[[[[[ gui select tank, Shaobo, 2014-0807
if isempty(tank)
    set_default_data_path;
    tank_loc_ini = DEFAULT_TANK_PATH;
    tank = uigetdir(tank_loc_ini, 'Select one TDT data tank');
    fprintf('the tank selected is: %s \n', tank);
end
% ]]]]]]]]]]

% [[[[[[[[[[ gui select blocks, Shaobo, 2014-0807
if isempty(blocks)
    blocks = uipickfiles('FilterSpec', tank, 'Prompt', 'Select TDT blocks');
    [~, blocks]=cellfun(@fileparts, blocks, 'UniformOutput', false);
    fprintf('the blocks selected are: \n');
    display(blocks(:));
end
% ]]]]]]]]]]

% [[[[[[[[[[ save name of converted tank and block names to a text file
name_store = ['PLX_',datestr(now,'yyyy-mmdd_HHMM')];

% gui confirm
prompt = {'confirm or change file name:'};
dlg_title = 'file name';
num_lines = 1;
def = {name_store};
answer = inputdlg(prompt,dlg_title,num_lines,def);
name_store = answer{1};

fileID_txt = fopen(fullfile(PLXDIR,[name_store,'.dat']),'w');
fwrite(fileID_txt, strjoin( [tank, reshape(blocks,1,[])], char(10)));
fclose(fileID_txt);
% ]]]]]]]]]]

% write plx file
for i = 1:length(blocks)
    fprintf('Retrieving "%s" (%d of %d) ...',blocks{i},i,length(blocks))
    
    d = TDT2mat(tank,blocks{i},'server',SERVER,'VERBOSE',false,'type',3);
    if isempty(EVENT)
        if isempty(d.snips)
            warning('No spiking events found in "%s"',blocks{i})
            continue
        end
        EVENT = fieldnames(d.snips);
        EVENT = EVENT{1};
    end
    
    if isempty(PLXDIR)
        PLXDIR = d.info.tankpath;
    end
    
    d = d.snips.(EVENT);
    
    d.data = d.data * 1e6; % scale for Plexon
    
    channels = unique(d.chan);
    % [[[[[[[[[[ to keep a slot for empty channels
    channels = (1:max(d.chan))';
    % ]]]]]]]]]]
    
    if i == 1
        ts   = cell(512,1);
        wave = cell(512,1);
        sort = cell(512,1);
        k = zeros(512,1);
        ts_increment_before = 0;
        ts_increment_after  = ts_increment_before + d.duration_precise + ts_gap;
    else
        ind = cellfun(@isempty,ts);
        k(~ind) = cellfun(@(x) x(end),ts(~ind));
        ts_increment_before = ts_increment_after;
        ts_increment_after  = ts_increment_before + d.duration_precise + ts_gap;
    end
    
    for ch = channels'
        ind = d.chan == ch;
        n = sum(ind);
        % if ~n, continue; end
        % [[[[[[[[[[ change increment to the length of block
        ts{ch}(end+1:end+n)     = d.ts(ind) + ts_increment_before;
        % ]]]]]]]]]]
        % ts{ch}(end+1:end+n)     = d.ts(ind) + k(ch);
        wave{ch}(end+1:end+n,:) = d.data(ind,:);
        % [[[[[[[[[[ clear sort code
        sort{ch}(end+1:end+n)   = d.sortcode(ind)*0;
        % ]]]]]]]]]]
    end
    
    fs  = d.fs;
    npw = size(d.data,2);
    
    clear d
    fprintf(' done\n')
end

maxts = max(cell2mat(ts'));

emptychs = cellfun(@isempty,ts);
% [[[[[[[[[[ to keep a slot for empty channels
emptychs = (1:length(ts)>max(channels))';
% ]]]]]]]]]]
ts(emptychs)   = [];
wave(emptychs) = [];
sort(emptychs) = [];
validchs = find(~emptychs)';



% get block ids for file name
% [[[[[[[[[[
plxfilename = [name_store,'.plx'];
% ]]]]]]]]]]
fprintf('Writing headers for "%s"\n',plxfilename)
plxfilename = fullfile(PLXDIR,plxfilename);
fid = writeplxrilehdr(plxfilename,fs,length(validchs),npw,maxts, name_store);
for ch = validchs
    writeplxchannelhdr(fid,ch,npw)
end
for i = 1:length(validchs)
    fprintf('\tWriting channel% 3d\t# spikes:% 7d\n',validchs(i),length(ts{i}))
    writeplxdata(fid,validchs(i),fs,ts{i},sort{i},npw,wave{i})
end

fclose(fid);

fprintf('finishied converting TDT to plx file "%s"\n',plxfilename)





function plx_id = writeplxrilehdr(filename,freq,nch,npw,maxts, name_store)
pad256(1:256) = uint8(0);

% create the file and write the file header

plx_id = fopen(filename, 'w');
fwrite(plx_id, 1480936528, 'integer*4');    % 'PLEX' magic code
fwrite(plx_id, 101, 'integer*4');           % the version no.

% [[[[[[[[[[ store the dat filename in the comment field
str_comment = pad256(1:128);
if length(name_store) <=128
    str_comment(1:length(name_store)) = name_store;
end
fwrite(plx_id, str_comment, 'char');      % placeholder for comment
% ]]]]]]]]]]
% fwrite(plx_id, pad256(1:128), 'char');      % placeholder for comment

fwrite(plx_id, freq, 'integer*4');          % timestamp frequency
fwrite(plx_id, nch, 'integer*4');           % no. of DSP channels
fwrite(plx_id, 0, 'integer*4');             % no. of event channels
fwrite(plx_id, 0, 'integer*4');             % no. of A/D (slow-wave) channels
fwrite(plx_id, npw, 'integer*4');           % no. points per waveform
fwrite(plx_id, npw/4, 'integer*4');         % (fake) no. pre-threshold points
[YR, MO, DA, HR, MI, SC] = datevec(now);    % current date & time
fwrite(plx_id, YR, 'integer*4');            % year
fwrite(plx_id, MO, 'integer*4');            % month
fwrite(plx_id, DA, 'integer*4');            % day
fwrite(plx_id, HR, 'integer*4');            % hour
fwrite(plx_id, MI, 'integer*4');            % minute
fwrite(plx_id, SC, 'integer*4');            % second
fwrite(plx_id, 0, 'integer*4');             % fast read (reserved)
fwrite(plx_id, freq, 'integer*4');          % waveform frequency
fwrite(plx_id, maxts*freq, 'double');       % last timestamp
fwrite(plx_id, pad256(1:56), 'char');       % should make 256 bytes

% now the count arrays (with counts of zero)
for i = 1:40
    fwrite(plx_id, pad256(1:130), 'char');    % first 20 are TSCounts, next 20 are WFCounts
end
for i = 1:8
    fwrite(plx_id, pad256(1:256), 'char');    % all of these make up EVCounts
end




function writeplxchannelhdr(plx_id,ch,npw)
% now the single PL_ChanHeader
pad256(1:256) = uint8(0);

% assume simple channel names
DSPname = sprintf('DSP%03d',ch);
SIGname = sprintf('SIG%03d',ch);

fwrite(plx_id, DSPname, 'char');
fwrite(plx_id, pad256(1:32-length(DSPname)));
fwrite(plx_id, SIGname, 'char');
fwrite(plx_id, pad256(1:32-length(SIGname)));
fwrite(plx_id, ch, 'integer*4');            % DSP channel number
fwrite(plx_id, 0, 'integer*4');             % waveform rate limit (not used)
fwrite(plx_id, ch, 'integer*4');            % SIG associated channel number
fwrite(plx_id, ch, 'integer*4');            % SIG reference  channel number
fwrite(plx_id, 1, 'integer*4');             % dummy for gain
fwrite(plx_id, 0, 'integer*4');             % filter off
fwrite(plx_id, -12, 'integer*4');           % (fake) detection threshold value
fwrite(plx_id, 0, 'integer*4');             % sorting method (dummy)
fwrite(plx_id, 0, 'integer*4');             % number of sorted units
for i = 1:10
    fwrite(plx_id, pad256(1:64), 'char');     % filler for templates (5 * 64 * short)
end
fwrite(plx_id, pad256(1:20), 'char');       % template fit (5 * int)
fwrite(plx_id, npw, 'integer*4');           % sort width (template only)
fwrite(plx_id, pad256(1:80), 'char');       % boxes (5 * 2 * 4 * short)
fwrite(plx_id, 0, 'integer*4');             % beginning of sorting window
fwrite(plx_id, pad256(1:128), 'char');      % comment
fwrite(plx_id, pad256(1:44), 'char');       % padding


function writeplxdata(plx_id,ch,freq,ts,units,npw,wave)
% now the spike waveforms, each preceded by a PL_DataBlockHeader
n = length(ts);

for ispike = 1:n
    fwrite(plx_id, 1, 'integer*2');           % type: 1 = spike
    fwrite(plx_id, 0, 'integer*2');           % upper byte of 5-byte timestamp
    fwrite(plx_id, ts(ispike)*freq, 'integer*4');  % lower 4 bytes
    fwrite(plx_id, ch, 'integer*2');          % channel number
    fwrite(plx_id, units(ispike), 'integer*2');  % unit no. (0 = unsorted)
    fwrite(plx_id, 1, 'integer*2');           % no. of waveforms = 1
    fwrite(plx_id, npw, 'integer*2');         % no. of samples per waveform
    
    fwrite(plx_id, wave(ispike, 1:npw), 'integer*2');
end

