% 
% aim:         specify default path baded on current computer
% 
% ---------- Shaobo Guan, 2016-0818, THU ----------
% Sheinberg lab, Brown University, USA, Shaobo_Guan@brown.edu

NAME_COMPUTER = getenv('COMPUTERNAME');
switch NAME_COMPUTER
    case 'BOOTH1_SORTER'
        % path for plx files, local
        DEFAULT_PLX_PATH = 'D:/PLX_combined/';  
        % path for TDT tanks, local
        DEFAULT_TANK_PATH = 'T:/synapse_Tanks/';
        % path on lab server for tdt tank, remote
        DEFAULT_TANK_PATH_STORE = 'L:/projects/encounter/data/TDT';
        % path on lab server for mat files, remote
        DEFAULT_MAT_PATH_STORE = 'L:/tdt/export_mat';
        % path on RS4 streamer that stores the sev files
        DEFAULT_SEV_PATH = 'R:';
        % path on backup disk array for large data files including SEV
        DEFAULT_BACKUP_PATH_STORE = 'N:/TDT_with_sev_Dante';
    
    case 'TDTBOOTH2'
        % path for plx files, local
        DEFAULT_PLX_PATH = 'C:/PLX_combined/';  
        % path for TDT tanks, local
        DEFAULT_TANK_PATH = 'C:/TDT/Synapse/Tanks/';
        % path on lab server for tdt tank, remote
        DEFAULT_TANK_PATH_STORE = 'L:/projects/encounter/data/TDT';
        % path on lab server for mat files, remote
        DEFAULT_MAT_PATH_STORE = 'L:/tdt/export_mat';
    
        
    case 'RIG3TDT-PC'
        % path for plx files, local
        DEFAULT_PLX_PATH = 'C:/PLX_files/';  
        % path for TDT tanks, local
        DEFAULT_TANK_PATH = 'C:/TDT/Synapse/Tanks/';
        % path on lab server for tdt tank, remote
        DEFAULT_TANK_PATH_STORE = 'L:/projects/encounter/data/TDT';
        % path on lab server for mat files, remote
        DEFAULT_MAT_PATH_STORE = 'L:/tdt/export_mat';
        
    otherwise
        fprintf('the computer %s is not listed, can not get default paths \n', NAME_COMPUTER);
        DEFAULT_PLX_PATH = './';
        DEFAULT_TANK_PATH = './';
        DEFAULT_TANK_PATH_STORE = './';
        DEFAULT_MAT_PATH_STORE = './';
end
    
