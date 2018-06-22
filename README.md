# TDT_matlab_tools 


Matlab-based tool to process neurophysiological data collected with Tucker-Davis Technologies (TDT) device.

Shaobo Guan, developed at Sheinberg lab at Brown University
2017-05-01

# Summery

This repository contains two separate tools

1. folder `TDT2PLX2TDT`: used to concatenage TDT blocks and convert to Plexon format for spike sorting (Plexon Offline Sorter) and convert the sortcode back to TDT blocks
2. folder `OnlineVisualizer`: used to visualize event-triggered responses (LFP) and (spks) online.

Acknowledgement:
* The TDT2PLX2TDT is developed on top of OpenDeveloper (an official tool provided by TDT) and TDT2PLX (developed by Daniel Stolzberg, see https://danielstolzberg.wordpress.com/)
* The OnlineVisualizer is developed with the help of SynapseSDK

I hope you find the tools useful.

# 1. tool TDT2PLX2TDT

## 1.1 Motivation

I usually record multiple blocks of data of the same set of neurons.  When I am doing spike sorting, I need to **concatenate these blocks together** before sorting for efficiency and consistency.  
Idealy, I want to use Plexon Offline sorter, the most popular spike sorting software.  
However, TDT does not provide such tools, so I made one to streamline the data processing pipeline for our lab.

## 1.2 How it works

The tool contains two major functions: `TDT2PLX` and `PLX2TDT` works as a "roundtrip"

* `TDT2PLX`: it reads in all spikes (waveforms, timestamps and event-id) of selected TDT blocks, and generate one single `.plx` file.  The spikes from different blocks are concatenated according to the order when you select blocks.  It also generated a `.dat` file that records the name of blocks for this conversion.
* `PLX2TDT`: it reads the sorted `.plx` file, and place a sortcode for every spike in the TDT blocks and sotre the sortcodes under `./sort` in the block folder, with sortname `PLX`.  This is done correctly through matching the blockname and the event-id of spikes

## 1.3 How to use it

### 1.3.1 setup before use

1. Make sure you have installed OpenDeveloper and ActiveX Controls from TDT (http://www.tdt.com/support/downloads.html), which is required to read TDT data
2. Download the TDT2PLX2TDT folder, add this folder and its subfolders to the defalt serch path of Matlab
3. optional, open file `set_default_path.mat` under `TDT2PLX2TDT` and provide your computer name and default path of data

        ```
        % path for plx files, local, (location where PLX is generated as the output of TDT2PLX)
        DEFAULT_PLX_PATH = 'D:/PLX_combined/';  
        % path for TDT tanks, local, (location of TDT tanks where TDT2PLX reads data in)
        DEFAULT_TANK_PATH = 'T:/synapse_Tanks/'; 
        % path on lab server for tdt tank, remote, (location to backup data after spike sorting)
        DEFAULT_TANK_PATH_STORE = 'L:/projects/encounter/data/TDT';
        % path on lab server for mat files, remote (location to convert data to mat format for analysis)
        DEFAULT_MAT_PATH_STORE = 'L:/tdt/export_mat';
        ```

### 1.3.2 daily workflow

Example script can be found in `TDT2PLX2TDT_script.mat` under `TDT2PLX2TDT` folder

1. Open Matlab and enter the folder `TDT2PLX2TDT`, run `set_default_data_path;`
2. run `TDT2PLX('', {}, 'PLXDIR', DEFAULT_PLX_PATH);`: it asks you to first select the TDT tank and then select the TDT blocks of interest through a gui, after some processing, it will generate a `.plx` and a `.dat` file in the default plx folder
3. to spike sorting in Plexon Offline Sorter
3. run `PLX2TDT('');`: it asks you to choose the `.plx` file containing the sorted spikes, and it will convert the sortcode and store the updated sortcode back to the TDT blocks automatically
4. if you want to upload data to a remote server, run `dataman_TDT('dat','tdt','plx');`: it will ask you to provide the `.dat` file, and it will back up TDT block (containing the new sortcode), and the `.plx` file to the remote server.  If you want to also convert TDT blocks to `.mat` and upload to remote data server, run `dataman_TDT('dat','tdt', 'sev','plx', 'mat')`;

that's it.

# 2. OnlineVisualizer

## 2.1 Motivation

When I stared using laminar prboes, I feel that it is necesary to plot the profile of evoked potential along the probe in order to know where the electrodes are relative to cortex.  This tool is developed to plot the recorded singal online to guide the electrode placenment.

![Alt text](./OnlineVisualizer/example_figure_for_this_gui.PNG?raw=true "example profile of a laminar probe")


## 2.2 How it works

* We first tell the online_signal_viewer.mat 1) the name of the aglignment event (i.e. the evetn around which the neural signal is averages, e.g. image onset for visual area, movment onset of motor area), 2) the name of LFP signas, 3) the name of spike signals.  These names have the match the names used in the Synapse circuit.
* The program detects whether the Syanpse software is in Preview/Recording mode, if true, it will look for the onset of the alignment event in a loop.
* Once an event is detected, it will take both LFP and spk data around the event (e.g. from -100 ms to +500 ms relative to the event) from every channel and store it in a rotating buffer.
* the average evoked response will be plotted 
* once the current Synapse block is finished (mode set to id), it will detect the termination and stop looking for new events and wait for the starting of the next block

## 2.3 How to use it

### 2.3.1 setup before use

1. Make sure TDT Synapse API is enabled (under Synapse->Menu->Prefernce)
2. Download the `OnlineVisualizer` folder and add it to Matlab search path
3. set the names in file `Online_signal_viewer.mat` under folder `OnlineVisualizer`

        ```
        t_window = [-0.1, 0.5];  % time window relative to stim onset, in sec
        t_binsize_spk= 0.010;         % time window to bin spikes, in sec
        N_ave_max    = 1000;           % number of trials to average
        NameEvtAlign = 'stim';   % the name of event used to align the signals
        NameSignalCntn = 'LFPs'; % the name of continuous signals, e.g., LFP
        NameSignalSnip = 'eSpk'; % the name of snip signals      , e.g., spikes
        ```

### 2.3.2 daily usage

1. Start Matlab, enter the `OnlineVisualizer` folder and run `Online_signal_viewer.mat`
2. Do recording using Syanpse as usual, the online viewer will plot the averaged evoked response of all channels.
3. Switching to Idle andn back to Preview/Record will refresh the current plot
4. GUI controllers: used to adjust 1) how many recent events used to do average, 2) scale of LFP and spikes (PSTH), 3) smoothness of LFP and spikes (PSTH), 3) which channels to watch.  Feel free to play with them

That's it.


GGHF (good luck and have fun!)







