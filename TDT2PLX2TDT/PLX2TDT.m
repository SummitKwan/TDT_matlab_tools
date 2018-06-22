function PLX2TDT(plxfilename)
% 
% aim:         get the sort code from a single combined plx file and write
%                back to the tanks
% requires:    TDT OpenDeveloper, PLX SDK, TDT2mat
% based on:    script provided by Daniel Stolzberg
% improvement: 1) gui select plx file
%              2) support any naming convention for blocks
%              3) tank name(with path) and block names are storeed in a
%              separate .dat file whose file name is storeed in the comment
%              field of plx file
% example:
%     PLX2TDT('D:\PLX_combined\PLX_2014-0812_1159-01_sorted');
%       or:
%     PLX2TDT('')
% 
% ---------- Shaobo Guan, 2014-0808, FRI ----------
% Sheinberg lab, Brown University, USA, Shaobo_Guan@brown.edu
%
% 
% 
% PLX2TDT(plxfilename)
%
% Convert plx file generated from sorting data with Plexon Offline Sorter
% and update appropriate TDT tank.
%
% Tank must be registered.
%
%   parameter         default value
%   SERVER              'Local'                 TDT server
%   BLOCKROOT           'Block'                 TDT Block root name
%   SORTNAME            'Pooled'                TDT Sort name
%   SORTCONDITION       'PlexonOSv2'            TDT Sort condition
%   EVENT               (depends)               If not specified, then the
%                                               event will be automatically
%                                               chosen from tank.
%
% See also, TDT2PLX
%
% DJS 2013
%
% Daniel.Stolzberg at gmail dot com

% defaults are modifiable using varargin parameter, value pairs
SERVER        = 'Local';
BLOCKROOT     = 'Block';
SORTNAME      = 'PLX';
SORTCONDITION = 'PlexonOSv3';
EVENT         = [];

% [[[[[[[[[[ gui select dat file
if isempty(plxfilename)
    set_default_data_path;
    plx_loc_ini = DEFAULT_PLX_PATH;
    [plxfilename, plxfilepath] = uigetfile([plx_loc_ini,'*.plx'], 'Select the .plx file');
    plxfilename = fullfile(plxfilepath, plxfilename);
    fprintf('the plx file selected is: %s \n', plxfilename);    
end
% ]]]]]]]]]]

% load and reconfigure plexon data
[tscounts, ~] = plx_info(plxfilename,1);

tscounts(:,1) = []; % remove empty channel


[npossunits,nchans] = size(tscounts);

n    = zeros(size(tscounts));
ts   = cell(1,nchans);
unit = cell(1,nchans);
for i = 1:nchans

    fprintf('\n\tChannel %d\n',i)
    for j = 1:npossunits
        if ~tscounts(j,i), continue; end
        [n(j,i),~,t,~] = plx_waves(plxfilename,i,j-1);
        fprintf('\t\tunit %d\t# spikes:% 8d\n',j-1,n(j,i))
        
        ts{i}   = [ts{i}; t(:)];
        unit{i} = [unit{i}; ones(n(j,i),1) * (j-1)];
    end
    
    [ts{i},sidx] = sort(ts{i});
    unit{i}      = unit{i}(sidx);
end



% parse plxfilename for tank and block info
% [[[[[[[[[[
[~,~,~,name_store] = plx_information(plxfilename);
datfilename = fullfile(fileparts(plxfilename),[name_store,'.dat']);

fid=fopen(datfilename);
name_tank_blocks=textscan(fid, '%s');
fclose(fid);

tank = name_tank_blocks{1}{1};
blocks = name_tank_blocks{1}(2:end);

SORTCONDITION = name_store;
% ]]]]]]]]]]


% [~,filename,~] = fileparts(plxfilename);
% k = strfind(filename,'blocks');
% tank = filename(1:k-2);
% bstr = filename(k+6:end);
% c = textscan(bstr,'_%d');
% blocks = cell2mat(c)';


% establish connection tank
TTXfig = figure('Visible','off','HandleVisibility','off');
TTX = actxcontrol('TTank.X','Parent',TTXfig);

if ~TTX.ConnectServer(SERVER, 'Me')
    error(['Problem connecting to Tank server: ' SERVER])
end

if ~TTX.OpenTank(tank, 'W')
    CloseUp(TTX,TTXfig);
    error(['Problem opening tank: ' tank]);
end



% update Tank with new Plexon sort codes
for b = 1:length(blocks)
    blockname = blocks{b};
    if ~TTX.SelectBlock(blockname)
        CloseUp(TTX,TTXfig)
        error('Unable to select block ''%s''',blockname)
    end
    
    d = TDT2mat(tank,blockname,'type',3,'VERBOSE',false);
    
    if isempty(EVENT)
        if isempty(d.snips)
            warning('No spiking events found in "%s"',blocks{i})
            continue
        end
        EVENT = fieldnames(d.snips);
        EVENT = EVENT{1};
    end
    
    d = d.snips.(EVENT);
    
    channels = unique(d.chan);
    
    fprintf('Updating sort "%s" on %s of %s\n',SORTNAME,blockname,tank)
    
    
    for ch = channels'
        ind = d.chan == ch;
        k = sum(ind);
        
        fprintf('\tChannel %d,\t%d units with% 8d spikes ...', ...
            ch,length(unique(unit{ch}(1:k))),k)
        

        SCA = uint32([d.index(ind); unit{ch}(1:k)']);
        SCA = SCA(:)';
        
        success = TTX.SaveSortCodes(SORTNAME,EVENT,ch,SORTCONDITION,SCA);
        
        if success
            fprintf(' SUCCESS\n')
        else
            fprintf(' FAILED\n')
        end
        
        d.index(ind)  = [];
        d.chan(ind)   = [];
        unit{ch}(1:k) = [];
        
    end
end

fprintf('finished updating all sort code\n')

CloseUp(TTX,TTXfig)




function CloseUp(TTX,TTXfig)
TTX.CloseTank;
TTX.ReleaseServer;
close(TTXfig);
