%% Produce animations of key periods

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

%% Load data

% Read image data (processed by ImageAnalysis)
load('outputs\PhotoDatabase.mat');
load('outputs\ShortlistPhotos.mat')

% Read time series data (already processed by TimeseriesAnalysis)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

%% Generate videos

Alphabet = num2cell('ABCDEFGHIJKLMNOPQRSTUVWXYZ');

OutputFolder = fullfile('outputs', 'videos');
if ~exist(OutputFolder,'dir')
    mkdir(OutputFolder);
end

for PeriodNo = 1%:size(Config.KeyPeriods,1)
    fprintf('Producing video for period %s\n', Alphabet{PeriodNo})
    
    PhotoSelectMask = ShortlistPhotos.UniqueTime >= Config.KeyPeriods(PeriodNo,1) & ...
                      ShortlistPhotos.UniqueTime <= Config.KeyPeriods(PeriodNo,2);
    PhotosForVideo = ShortlistPhotos(PhotoSelectMask, :);
    
    FileName = sprintf('Period%s_%s', Alphabet{PeriodNo}, ...
                       datestr(Config.KeyPeriods(PeriodNo,1),'yyyy-mm-dd'));
    FileName = fullfile(OutputFolder, FileName);
    
    animatePhotos(FileName, ...
                  fullfile(Config.DataFolder,Config.PhotoFolder), Photos, ...
                  PhotosForVideo, Config, LagoonTS, 12, true);

end