% Image processing for daily images

addpath functions

%% Input info

% Main data drive/folder
DataFolder = 'C:\Projects\Hurunui';
%DataFolder = '\\engcad4\GISdump\Richard\';

% Photo directory containing all images
PhotoFolder = '\PhotoRecord\ImageStore';

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

%% Find available images and extract key information
AllPhotos = genPhotoDataTable(fullfile(DataFolder,PhotoFolder));

%% Read lagoon time series (already processed)
LagoonTS = readtable(fullfile(DataFolder,LagoonTsCsv));

%% Find high tide and low tide image times

% Get list of unique timestamps
UniqueTime = unique(AllPhotos.CaptureTime);

% Assign lagoon level to each unique time
for ii = 1:size(UniqueTime,1)
    
    
    
end

%% Make cut down list of daily images at high tide & low tide
