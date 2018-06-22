function Online_signal_viewer


% # ######## Preference for the Online Viewer ##########
t_window = [-0.1, 0.5];  % time window relative to stim onset, in sec
t_binsize_spk= 0.010;         % time window to bin spikes, in sec
N_ave_max    = 1000;           % number of trials to average
NameEvtAlign = 'stim';   % the name of event used to align the signals
NameSignalCntn = 'LFPs'; % the name of continuous signals, e.g., LFP
NameSignalSnip = 'eSpk'; % the name of snip signals      , e.g., spikes


% ----- Synapse API object for finding avtive tanks -----
SY = SynapseAPI('localhost');

% activeX control object for reading data from active blocks
TT = actxcontrol('TTank.X');
TT.ConnectServer('Local', 'Me');
% hide the activeX conrtol figure
set(gcf,'Visible','off')

% ===== set plot window layout =====

% figure and its close request function
h_fig = figure('Position', [50,50, 800,800]);
set(h_fig, 'CloseRequestFcn', @my_closereq)
function my_closereq(src,callbackdata)  % action uppon clicking close button
    if getappdata(h_fig, 'tf_run')
        setappdata(h_fig, 'tf_run', false)
    else
        delete(h_fig)
    end
end

axes_left = 0.05;
axes_right= 0.75;
axes_width= axes_right-axes_left;
uictrl_left = 0.78;
uictrl_right= 0.98;
uictrl_width = (uictrl_right-uictrl_left)/2;

% axes for plotting LFP
h_axe_lfp = axes('Position',[axes_left 0.05 (axes_width)/2 0.90]);
h_axe_spk = axes('Position',[axes_left+axes_width/2 0.05 axes_width/2 0.90]);

% text for showing system state
h_sys_state_txt = uicontrol('Style', 'text', 'String', 'Mode', 'FontWeight', 'Bold', ...
        'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.97 uictrl_width 0.03]);
h_block_name_txt = uicontrol('Style', 'text', 'String', 'Name Block', ...
        'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.95 uictrl_width 0.03]);
h_evt_count_txt = uicontrol('Style', 'text', 'String', sprintf('total events : %0.0f',0), ...
        'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.92 uictrl_width*2 0.03]);

% use recent events to calculate average
h_N_ave_sld = uicontrol('Style', 'slider',...
        'Min',1,'Max',N_ave_max,'Value', N_ave_max,...
        'Units','normalized','Position', [uictrl_left 0.87 uictrl_width*1.5 0.03]);
h_N_ave_txt = uicontrol('Style', 'text', 'String', sprintf('use recent : %0.0f',N_ave_max), ...
        'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.90 uictrl_width*2 0.03]);

    
% slider and text for adjusting scale
h_lfp_scale_sld = uicontrol('Style', 'slider',...
        'Min',0.00001,'Max',0.001,'Value', 0.0002,...
        'Units','normalized','Position', [uictrl_left 0.58 uictrl_width/2 0.20]);
h_spk_scale_sld = uicontrol('Style', 'slider',...
        'Min',1.0,'Max',300.0,'Value', 50,...
        'Units','normalized','Position', [uictrl_left+uictrl_width 0.58 uictrl_width/2 0.20]);
h_lfp_scale_txt = uicontrol('Style', 'text', ...
        'String', sprintf('LFP\nrange'), 'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.78 uictrl_width 0.06]);
h_spk_scale_txt = uicontrol('Style', 'text', ...
        'String', sprintf('spk\nrange'), 'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left+uictrl_width 0.78 uictrl_width 0.06]);


% slider and text for adjusting t smooth
h_lfp_smooth_sld = uicontrol('Style', 'slider',...
        'Min',0.0,'Max',0.10,'Value', 0.0,...
        'Units','normalized','Position', [uictrl_left 0.28 uictrl_width/2 0.20]);
h_spk_smooth_sld = uicontrol('Style', 'slider',...
        'Min',0.0,'Max',0.10,'Value', 0.0,...
        'Units','normalized','Position', [uictrl_left+uictrl_width 0.28 uictrl_width/2 0.20]);
h_lfp_smooth_txt = uicontrol('Style', 'text', ...
        'String', sprintf('LFP\nsmooth'), 'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.48 uictrl_width 0.06]);
h_spk_smooth_txt = uicontrol('Style', 'text', ...
        'String', sprintf('spk\nsmooth'), 'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left+uictrl_width 0.48 uictrl_width 0.06]);


% slider and text for adjusting chan zoom
h_ch_center_sld = uicontrol('Style', 'slider',...
        'Min',1,'Max',2,'Value', 1,...
        'Units','normalized','Position', [uictrl_left 0.05 uictrl_width/2 0.15]);
h_ch_range_sld = uicontrol('Style', 'slider',...
        'Min',1,'Max',2,'Value', 2,...
        'Units','normalized','Position', [uictrl_left+uictrl_width 0.05 uictrl_width/2 0.15]);
h_ch_show_txt = uicontrol('Style', 'text', ...
        'String', sprintf('channels : []'), 'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.22 uictrl_width*2 0.02]);
h_ch_center_txt = uicontrol('Style', 'text', ...
        'String', sprintf('offset'), 'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left 0.20 uictrl_width 0.02]);
h_ch_range_txt = uicontrol('Style', 'text', ...
        'String', sprintf('range'), 'HorizontalAlignment', 'left', ...
        'Units','normalized','Position', [uictrl_left+uictrl_width 0.20 uictrl_width 0.02]);
    
% text for showing evetn count
%h_spk_smooth_txt = uicontrol('Style', 'text', ...
%        'String', sprintf('event number'), 'HorizontalAlignment', 'left', ...
%        'Units','normalized','Position', [uictrl_left+uictrl_width 0.50 uictrl_width 0.06]);

    

% set UI control data to be changed on the run
setappdata(h_fig, 'tf_run', true);


while getappdata(h_fig, 'tf_run')   % Loop for openning blocks
    pause(2.0);
    
    % ----- Get current tank/block and open it -----
    CurrentTankName  = SY.getCurrentTank();
    TT.OpenTank(CurrentTankName, 'R');
    CurrentBlockName = '';
    if SY.getMode()>=2    
        CurrentBlockName = SY.getCurrentBlock();
    end
    
    set(h_sys_state_txt, 'String', SY.getModeStr())
    set(h_block_name_txt, 'String', CurrentBlockName)
    
    if strcmp( CurrentBlockName, '' ) || ~any(CurrentBlockName)
        disp('no active block')
        continue     % skip the following operations of no active blocks
    else             % select current active block
        disp(CurrentBlockName);
        TT.SelectBlock(CurrentBlockName);
    end
    
    % ===== Calculate the number of samples in the time window =====
    % read the alignment event
    TT.SetGlobalV('T1', 0); % from beginning
    TT.SetGlobalV('T2', 0); % to end
    Counter = 0;            % couter of event onset
    N_evt = TT.ReadEventsSimple(NameEvtAlign);   % number of trials
    
    % read the a sample continuous signal to determine its dimension
    TT.SetGlobalV('T1', t_window(1));
    TT.SetGlobalV('T2', t_window(2));
    clear waves
    clear lfps_store
    clear spks_store
    waves = TT.ReadWavesV(NameSignalCntn);

    if size(waves(:))==1   % if for some reason does not get the right size, try in the next loop
        disp('LFP can not be properlly read, please wait for ~10s')
        continue
    end
    TT.ReadEventsSimple(NameSignalCntn);
    SamplingRate = TT.ParseEvInfoV(1,1,9);
    
    % data sctutre to store the stim aligned lfp/spk traces
    N_ts = size(waves,1);
    N_ch = size(waves,2);
    lfps_store = nan(N_ts, N_ch, N_ave_max); % [N_ts,N_ch,N_trials]
    
    t_bin_edge = t_window(1):t_binsize_spk:t_window(2);
    t_bin_ctr = diff(t_bin_edge)+t_bin_edge(1:end-1);
    N_bin = length(t_bin_ctr);
    spks_store = nan(N_bin, N_ch, N_ave_max); % [N_ts,N_ch,N_trials]
    
    % plot traces a place holder
    ts = (1:N_ts)/SamplingRate + t_window(1);   % time axis
    ts_span = ts(end)-ts(1);
    ch_plot_shift_lfp = - ones(N_ts,1)*(1:N_ch);   % for plotting
    ch_plot_shift_spk = - ones(N_bin,1)*(1:N_ch);   % for plotting
    
    h_lfp_plot = plot(h_axe_lfp, ts,  zeros(N_ts, N_ch)+ch_plot_shift_lfp );
    h_spk_plot = plot(h_axe_spk, t_bin_ctr,  zeros(N_bin, N_ch)+ch_plot_shift_spk );
    
    
    xlim(h_axe_lfp, [ts(1)-0.002*ts_span, ts(end)+0.002*ts_span]);
    ylim(h_axe_lfp, [-N_ch-1, 0]);
    xlim(h_axe_spk, [t_bin_edge(1), t_bin_edge(end)]);
    ylim(h_axe_spk, [-N_ch-1, 0]);
    
    title(h_axe_lfp, 'LFP')
    grid(h_axe_lfp, 'on');
    xlabel(h_axe_lfp, 'time');
    ylabel(h_axe_lfp, 'ch');

    title(h_axe_spk, 'spikes')
    grid(h_axe_spk, 'on');
    xlabel(h_axe_spk, 'time');
    set(h_axe_spk, 'YTickLabel', {});
    
    set(h_ch_center_sld, 'Max', N_ch, 'Value', (N_ch+1)/2);
    set(h_ch_range_sld, 'Max', N_ch-1, 'Value', N_ch-1);
    
    while SY.getMode()>=2 && getappdata(h_fig, 'tf_run')
        pause(0.10);
        
        % ----- update UI control object -----
        set(h_sys_state_txt, 'String', SY.getModeStr())
        set(h_block_name_txt, 'String', CurrentBlockName)
        set(h_evt_count_txt, 'String', sprintf('total events : %0.0f',Counter));
        
        N_ave = round(get(h_N_ave_sld, 'Value'));
        set(h_N_ave_txt, 'String', sprintf('use recent : %0.0f', N_ave));
        
        plot_scale_lfp = get(h_lfp_scale_sld,'Value');
        set(h_lfp_scale_txt, 'String', sprintf('LFP\nrange\n%0.0f uV',plot_scale_lfp*1000000) );
        plot_scale_spk = get(h_spk_scale_sld,'Value');
        set(h_spk_scale_txt, 'String', sprintf('spk\nrange\n%0.0f spk/s',plot_scale_spk) );
        
        plot_smooth_lfp = get(h_lfp_smooth_sld,'Value');
        plot_smooth_lfp_N = max(ceil(plot_smooth_lfp*SamplingRate),1);
        plot_smooth_lfp = plot_smooth_lfp_N/SamplingRate; 
        set(h_lfp_smooth_txt, 'String', sprintf('LFP\nsmooth\n%0.0f ms',plot_smooth_lfp*1000) );
        plot_smooth_spk = get(h_spk_smooth_sld,'Value');
        plot_smooth_spk_N = max(ceil(plot_smooth_spk/t_binsize_spk), 1);
        plot_smooth_spk = plot_smooth_spk_N *t_binsize_spk;
        set(h_spk_smooth_txt, 'String', sprintf('spk\nsmooth\n%0.0f ms',plot_smooth_spk*1000) );
        
        ch_center = get(h_ch_center_sld, 'Value');
        ch_range  = get(h_ch_range_sld,  'Value');
        ch_min = round(ch_center-ch_range/2);
        ch_max = round(ch_center+ch_range/2);
        set(h_ch_show_txt, 'String', sprintf('channels: [%0.0f, %0.0f]', ch_min, ch_max));
        set(h_axe_lfp, 'yLim',[-ch_max-1, -ch_min+1]);
        set(h_axe_spk, 'yLim',[-ch_max-1, -ch_min+1]);
        
        % read the events to align the trials
        TT.SetGlobalV('T1', 0);
        TT.SetGlobalV('T2', 0);
        t_valid = TT.GetValidTimeRangesV;
        N_evt= TT.ReadEventsSimple(NameEvtAlign);
        
        
        if N_evt-Counter>N_ave_max   % set the counter to the trial to be read (skip some events)
            Counter=N_evt-N_ave_max;
        end
        if N_evt>Counter         % if new trials arrive
            for i= (Counter+1):N_evt     % for every new trial
                i_in_store = mod(i-1,N_ave_max)+1;  % index of trial in rotation buffer
                t_align = TT.ParseEvInfoV(i-1, 1, 6);
                if t_align + t_window(2) < t_valid(2)  % if the full interval around the event is available
                    Counter=Counter+1;
                    TT.SetGlobalV('T1', t_align + t_window(1));
                    TT.SetGlobalV('T2', t_align + t_window(2)+0.1);
                    
                    % lfp
                    waves = TT.ReadWavesV(NameSignalCntn);
                    lfps_store(:,:,i_in_store) = waves(1:size(lfps_store,1),:);
                    
                    % spk
                    N_spks = TT.ReadEventsSimple(NameSignalSnip);
                    spks_ch = TT.ParseEvInfoV(0, N_spks, 4); % channel
                    spks_sc = TT.ParseEvInfoV(0, N_spks, 4); % sortcode
                    spks_ts = TT.ParseEvInfoV(0, N_spks, 6)-t_align; % timestamps
                    for i_ch = 1:N_ch
                        spks_store(:,i_ch,i_in_store) = histcounts(spks_ts(spks_ch==i_ch), t_bin_edge);
                    end
                    
                    disp(Counter);
                end
            end
        end
        
        if Counter <= N_ave
            N_ave_use = 1:Counter;
        else
            i_in_store_cur = mod(Counter-1, N_ave_max)+1;
            if i_in_store_cur - N_ave >= 0
                N_ave_use = i_in_store_cur - N_ave +1 : i_in_store_cur;
            else
                N_ave_use = [1:i_in_store_cur, N_ave_max-(N_ave-i_in_store_cur)+1: N_ave_max];
            end
        end
        lfp_ave = nanmean(lfps_store(:,:,N_ave_use),3)/plot_scale_lfp;
        lfp_ave_smooth = smoothdata(lfp_ave, 'gaussian', plot_smooth_lfp_N);
        lfp_ave_plot = lfp_ave_smooth + ch_plot_shift_lfp;
        spk_ave = nanmean(spks_store(:,:,N_ave_use),3)/t_binsize_spk/plot_scale_spk;
        spk_ave_smooth = smoothdata(spk_ave, 'gaussian', plot_smooth_spk_N);
        spk_ave_plot = spk_ave_smooth + ch_plot_shift_spk;
        for i_lfp_plot = 1:length(h_lfp_plot)
            set(h_lfp_plot(i_lfp_plot), 'YData', lfp_ave_plot(:,i_lfp_plot));
            set(h_spk_plot(i_lfp_plot), 'YData', spk_ave_plot(:,i_lfp_plot));
        end

        
    end
end

% cleaning up
delete(h_fig);
TT.CloseTank;
TT.ReleaseServer;

end