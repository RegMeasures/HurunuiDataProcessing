% Generate animation of Hurunui Images

%% Input info

% Main data drive/folder
DataFolder = 'C:\Projects\Hurunui';
%DataFolder = '\\engcad4\GISdump\Richard\';

% Photo directory containing all images
PhotoFolder = '\PhotoRecord\ImageStore';

% Photo databases
Photos = (fullfile(DataFolder,'\PhotoRecord\PhotoDatabase.mat'));
TimeMatchedPhotos = load(fullfile(DataFolder,'\PhotoRecord\TimeMatchedPhotos.mat'));

% Processed Lagoon TS
LagoonTsCsv = '\Matlab\OutletFlow\LagoonTS.csv';

% Wave data exported from Tideda
WaveCSV1 = '\TimeseriesData\WaveData1.csv';
WaveCSV2 = '\TimeseriesData\WaveData2.csv';

% Calculated outlet channel dimensions
ChannelTsCsv = '\OutletFlow\ChannelTable_3pars';

% Quality thresholds
SharpThresh = 1;
ContrastThresh = 20;
BrightThresh = 50;

%% Read in timeseries data

% Read lagoon time series (already processed)
LagoonTS = readtable(fullfile(DataFolder,LagoonTsCsv));

% Read channel dimensions (already processed)
ChannelTS = readtable(fullfile(DataFolder,ChannelTsCsv));

% Read wavedata
WaveTS = readTidedaCsv(fullfile(DataFolder,WaveCSV1));
WaveTS2 = readTidedaCsv(fullfile(DataFolder,WaveCSV2));

% Combine wavedata into 1 table
WaveTS = [WaveTS, WaveTS2(:,2:end)]; % if this line doesn't work check tideda exports for same time period and synchronised to 30min intervals
clear WaveTS2

% Calculate long shore transport potential

%% record timelapse movie

% get reduced list of files - only include timsteps with both cameras
%     VidPhotos = TimeMatchedPhotos(~isnan(TimeMatchedPhotos.Cam1Photo) & ~isnan(TimeMatchedPhotos.Cam2Photo),:);

% or just include all timesteps where at least one camera has an image
VidPhotos = TimeMatchedPhotos;

