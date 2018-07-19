%% Export extracted waters edge to shapefile for start and end of key periods
%
%   Reads in data from 'outputs\PhotoDatabase.mat' and 
%   'outputs\ShortlistPhotos.mat' which have been generated by the
%   ImageAnalysis script.
%
%   This script relies on the imageAnalysis2GIS function.
%
%   See also: IMAGEANALYSIS, IMAGEANALYSIS2GIS.

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

%% Load data

load('outputs\PhotoDatabase.mat');
load('outputs\ShortlistPhotos.mat')

%% Export 

Alphabet = num2cell('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
PhotoDay = dateshift(ShortlistPhotos.UniqueTime,'start','day');
for PeriodNo = 1:size(Config.KeyDates,1)
    fprintf('Outputing gis data for period %s\n', Alphabet{PeriodNo})
    
    OutputFolder = fullfile('outputs', sprintf('Period%s', Alphabet{PeriodNo}));
    if ~exist(OutputFolder,'dir')
        mkdir(OutputFolder);
    end
    
    StartEndLabel = {'Start','End'};
    for StartEnd = 1:2
        % Select the next quality photo after the date of interest
        PhotoNo = find(PhotoDay == Config.KeyDates(PeriodNo,StartEnd) & ...
                       ShortlistPhotos.WetBdyOK, 1);
        % Generate the required inputs for imageAnalysis2GIS
        FileName = sprintf('Period%s_%s_%s', Alphabet{PeriodNo}, ...
                           StartEndLabel{StartEnd}, ...
                           datestr(ShortlistPhotos.UniqueTime(PhotoNo),'yyyy-mm-dd_HH-MM-SS'));
        FileName = fullfile(OutputFolder, FileName);
        Cam1No = ShortlistPhotos.Cam1Photo(PhotoNo);
        Cam1Image = imread(fullfile(Config.DataFolder, Config.PhotoFolder, ...
                           Photos.FileSubDir{Cam1No}, [Photos.FileName{Cam1No}, '.jpg']));
        Cam2No = ShortlistPhotos.Cam2Photo(PhotoNo);
        Cam2Image = imread(fullfile(Config.DataFolder, Config.PhotoFolder, ...
                           Photos.FileSubDir{Cam2No}, [Photos.FileName{Cam2No}, '.jpg']));
        % Output the WetBdy and projected images to GIS
        imageAnalysis2GIS(Config, FileName, Cam1Image, Cam2Image, ...
                          ShortlistPhotos.LagoonLevel(PhotoNo), ...
                          ShortlistPhotos.Twist(PhotoNo,:), ...
                          ShortlistPhotos.WetBdy{PhotoNo})
    end
end