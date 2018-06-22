# TDT_matlab_tools 

Matlab-based tool to process neurophysiological data collected with Tucker-Davis Technologies (TDT) device.

Shaobo Guan, developed at Sheinberg lab at Brown University
2017-05-01

## Summery

This repository contains two separate tools

1. folder `TDT2PLX2TDT`: used to concatenage TDT blocks and convert to Plexon format for spike sorting (Plexon Offline Sorter) and convert the sortcode back to TDT blocks
2. folder `OnlineVisualizer`: used to visualize event-triggered responses (LFP) and (spks) online.

Acknowledgement:
* The TDT2PLX2TDT is developed on top of OpenDeveloper (an official tool provided by TDT) and TDT2PLX (developed by Daniel Stolzberg, see https://danielstolzberg.wordpress.com/)
* The OnlineVisualizer is developed with the help of SynapseSDK

I hope you find the tools useful.

## tool TDT2PLX2TDT

### Motivation

I usually record multiple blocks of data of the same set of neurons.  When I am doing spike sorting, I need to **concatenate these blocks together** before sorting for efficiency and consistency.  
Idealy, I want to use Plexon Offline sorter, the most popular spike sorting software.  
However, TDT does not provide such tools, so I made one to streamline the data processing pipeline for our lab.

### How it works

The tool contains two major functions: `TDT2PLX` and `PLX2TDT` works as a "roundtrip"

* `TDT2PLX`: it reads in all spikes (waveforms, timestamps and event-id) of selected TDT blocks, and generate one single `.plx` file.  The spikes from different blocks are concatenated according to the order when you select blocks.  It also generated a `.dat` file that records the name of blocks for this conversion.
* `PLX2TDT`: it reads the sorted `.plx` file, and place a sortcode for every spike in the TDT blocks and sotre the sortcodes under `./sort` in the block folder, with sortname `PLX`.  This is done correctly through matching the blockname and the event-id of spikes

### How to use it

#### set-up

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

#### daily workflow

Example script can be found in `TDT2PLX2TDT_script.mat` under `TDT2PLX2TDT` folder

1. Open Matlab and enter the folder `TDT2PLX2TDT`, run `set_default_data_path;`
2. run `TDT2PLX('', {}, 'PLXDIR', DEFAULT_PLX_PATH);`: it asks you to select tank and blocks of interest through a gui and generted a `.plx` and a `.dat` file in the default plx folder
3. to spike sorting in Plexon Offline Sorter
3. run `PLX2TDT('');`: it asks you to choose the `.plx` file containing the sorted spikes, and it will convert the sortcode and store the updated sortcode back to the TDT blocks automatically
4. if you want to upload data to a remote server, run `dataman_TDT('dat','tdt','plx');`: it will ask you to provide the `.dat` file, and it will back up TDT block (containing the new sortcode), and the `.plx` file to the remote server.  If you want to also convert TDT blocks to `.mat` and upload to remote data server, run `dataman_TDT('dat','tdt', 'sev','plx', 'mat')`;

that's it.




