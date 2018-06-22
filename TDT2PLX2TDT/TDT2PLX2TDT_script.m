cd('L:/tdt/export_mat/TDT2PLX2TDT');
set_default_data_path;
addpath(genpath('Matlab Offline Files SDK'))
%% TDT2PLX
TDT2PLX('', {}, 'PLXDIR', DEFAULT_PLX_PATH);

%% PLX2TDT
PLX2TDT('');

%% upload TDT tank
dataman_TDT('dat','tdt','plx');

%% upload TDT tank and convert to mat
dataman_TDT('dat','tdt' ,'mat','plx');

%% backup block and sev (on RS4 streamer) files to locak disk array
dataman_TDT('dat','sev','plx');

%% convert to matlab format and upload to shared disk
dataman_TDT('dat','mat');

%% do all works
dataman_TDT('dat','tdt', 'sev','plx', 'mat');


%% Get computer name
getenv('COMPUTERNAME')

%% if no dat file
dataman_TDT('2016/09/17')


%% copy retreat files
list_tanks = dir(DEFAULT_TANK_PATH);
for i=1:length(list_tanks)
    list_blks = dir(fullfile(DEFAULT_TANK_PATH, list_tanks(i).name));
    for j=1:length(list_blks)
        if ~isempty(regexp( list_blks(j).name, '.*retreat.*'))
           disp(list_tanks(i).name)
           disp(list_blks(j).name)
           if exist(fullfile(DEFAULT_TANK_PATH_STORE, list_tanks(i).name, list_blks(j).name),'file')==7
               disp('already exist')
           else
               disp('copy block to remote store')
               copyfile(fullfile(DEFAULT_TANK_PATH, list_tanks(i).name, list_blks(j).name), fullfile(DEFAULT_TANK_PATH_STORE, list_tanks(i).name, list_blks(j).name) )
           end
        end
    end
end
disp('finished')
