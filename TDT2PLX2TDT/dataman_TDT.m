function dataman_TDT(varargin)

% aim:         convert all TDT blocks of the same day to mat file
% requires:    my_TDT2mat.m, OpenDeveloper from TDT
% example:
%     data source:
%     dataman_TDT()
%       --  convert today's all blocks
%     dataman_TDT('2014/07/30')
%       --  convert all blocks recorded from 2014/07/30
%     dataman_TDT('dat')
%       --  convert all blocks indicated by the dat file
%     
%     data to backup/upload
%       -- 'tdt': tdt blocks
%       -- 'plx': the plx files for spike sorting
%       -- 'sev': backup the sev files stored in the RS4 streamer
%     dataman_TDT('dat','tdt','plx');
% ---------- Shaobo Guan, 2014-0730, WED ----------
% Sheinberg lab, Brown University, USA, Shaobo_Guan@brown.edu

set_default_data_path;

% default date to convert
date_convert = date;
if length(varargin)>=1
    date_convert = varargin{1};
end

% determine which files to upload based on input
tf_upload_plx = false;
tf_upload_tdt = false;
tf_upload_mat = false;
tf_backup_sev = false;
for i=1:length(varargin)
    switch lower(varargin{i})
        case 'plx'
            tf_upload_plx = true;
        case 'tdt'
            tf_upload_tdt = true;
        case 'mat'
            tf_upload_mat = true;
        case 'sev'
            tf_backup_sev = true;
    end
end

set_default_data_path;
% default remote disk location to upload converted date
dir_store = DEFAULT_MAT_PATH_STORE;

if strcmp(date_convert, 'dat')
    [datfilename, datfilepath] = uigetfile('D:\PLX_combined\*.dat', 'Select the .dat file');
    datfilename = fullfile(datfilepath, datfilename);
    fprintf('the dat file selected is: %s \n', datfilename);    
    
    fid=fopen(datfilename);
    name_tank_blocks=textscan(fid, '%s');
    fclose(fid);

    tank = name_tank_blocks{1}{1};
    blocks = name_tank_blocks{1}(2:end);
    name_block_cell = blocks;
    
    % copy .dat and .plx file to shared disk
    [~, datfilename_no_ext]=fileparts(datfilename);
    
    if tf_upload_plx
        copyfile([fullfile(datfilepath, datfilename_no_ext) ,'*'], dir_store);
        display('file copied: ');
        dir([fullfile(datfilepath, datfilename_no_ext) ,'*']);
    end
else

    % location of data tank
    tank = uigetdir(DEFAULT_TANK_PATH);
    % tank = 'T:\tdt_tanks\PowerPac_32C';

    % translate the date to posivle strings contained in the file name    
    str_date = {datestr(date_convert, 'mmddyy'), datestr(date_convert, 'yyyy-mmdd')};

    % get the block names to convert
    name_block_cell = {};
    for i=1:length(str_date)
        name_block_strc = dir([tank, '/*', str_date{i} ,'*']);
        name_block_cell = [name_block_cell, {name_block_strc.name}];
    end

end

% display block names to convert
display([10, 'the blocks to be converted/uploaed/backuped are: ', 10, '----------']);
for i=1:length(name_block_cell)
    display(name_block_cell{i});
end
display(['----------', 10]);

%% convert/upload/back up


% upload tdt blocks to the shared disk
if tf_upload_tdt
    [~,name_tank,~] = fileparts(tank);
    tank_store = fullfile(DEFAULT_TANK_PATH_STORE, name_tank);
    if exist( tank_store ) ~=7
        mkdir( tank_store );
        if exist(fullfile(tank,'desktop.ini'))
            copyfile(fullfile(tank,'desktop.ini'), fullfile(tank_store,'desktop.ini'));
        end
    end
    for i=1:length(name_block_cell)
        copyfile( fullfile(tank, blocks{i}), fullfile(tank_store, blocks{i}));
        display(['copied block: ', blocks{i}]);
    end
    if strcmp(date_convert, 'dat') && tf_upload_plx
        copyfile([fullfile(datfilepath, datfilename_no_ext) ,'*'], tank_store);
        display('spike sorting related files copied: ');
        dir(tank_store);
    end
end

% convert using my_TDT2mat
if tf_upload_mat
    name_converted = {};
    for i=1:length(name_block_cell)
        display(['converting: ',name_block_cell{i}]);

         [~, name_save]= my_TDT2mat(tank,...
             name_block_cell{i}, 'EXCLUDE', {}, 'NODATA', false,...
             'SORTNAME', 'PLX', 'SAVE', true, 'VERBOSE', false);


        name_converted = [name_converted, {name_save}];
        display(['generated : ', name_converted{i}, 10]); 
    end
    
    % upload covnerted file

    display([10, 'the blocks successfully uploaded are: ', 10, '----------']);
    for i=1:length(name_converted)
        % upload covnerted file
        movefile([name_converted{i},'.mat'], dir_store);
        % display block names to upload
        display(name_converted{i});
    end
    display(['----------', 10]);

end


% backup sev files to the local disk array
if tf_backup_sev
    [~,name_tank,~] = fileparts(tank);
    tank_store = fullfile(DEFAULT_BACKUP_PATH_STORE, name_tank);
    if exist( tank_store ) ~=7
        mkdir( tank_store );
        if exist(fullfile(tank,'desktop.ini'))
            copyfile(fullfile(tank,'desktop.ini'), fullfile(tank_store,'desktop.ini'));
        end
    end
    for i=1:length(name_block_cell)
        copyfile( fullfile(tank, blocks{i}), fullfile(tank_store, blocks{i}));
        try
            copyfile( fullfile(DEFAULT_SEV_PATH,name_tank, blocks{i}, '*.sev'), fullfile(tank_store, blocks{i}));
            display(['copied block inlcuding sev fiels: ', blocks{i}]);
        catch
            display(['copied block does not have sev files for block: ', blocks{i}]);
        end
    end
    if strcmp(date_convert, 'dat') && tf_upload_plx
        copyfile([fullfile(datfilepath, datfilename_no_ext) ,'*'], tank_store);
        display('spike sorting related files copied: ');
        dir(tank_store);
    end
end


display(['data converting and uploading finished']);

end