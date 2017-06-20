% Image Pre processing for hapua fixed camera images
% Richard Measures 2015
%
% Basic process:
% - genPhotoDataTable
% - photoQuality

addpath(genpath('functions'))
addpath('inputs')

%% Input info

% Main data drive/folder
%DataFolder = 'C:\Projects\Hurunui';
%DataFolder = '\\engcad4\GISdump\Richard\';
%DataFolder = 'H:\Hapua\Individual_Hapua\Hurunui\';
DataFolder = 'E:\Hurunui';

% Photo directory containing all images
PhotoFolder = '\PhotoRecord\ImageStore';

% Processed Lagoon TS
LagoonTsCsv = '\Matlab\OutletFlow\LagoonTS.csv';

% % Wave data exported from Tideda
% WaveCSV1 = '\TimeseriesData\WaveData1.csv';
% WaveCSV2 = '\TimeseriesData\WaveData2.csv';
% 
% % Calculated outlet channel dimensions
% ChannelTsCsv = '\OutletFlow\ChannelTable_3pars';

% Quality thresholds
SharpThresh = 2.5;
ContrastThresh = 20;
BrightThresh = 50;

% Foreground/BackgroundMasks
load('FgBgMask1.mat')
load('FgBgMask2.mat')

% Camera distortion and projection settings
load('CamSettings')

% Seed pixels for water ID
SeedPixel1 = [1628, 1013];
SeedPixel2 = [1334, 950];

%% Find available images and extract key information
AllPhotos = genPhotoDataTable(fullfile(DataFolder,PhotoFolder));

%% Make cut down list (30min rather than 15min)
[~ ,~ ,~ ,~ ,CaptureMins ,~ ] = datevec(AllPhotos.CaptureTime);
Photos = AllPhotos(CaptureMins==30 | CaptureMins==0,:);

%% Generate quality metrics and assess quality

% generate metrics
PhotosPrevious = load(fullfile(DataFolder,'\PhotoRecord\PhotoDatabase.mat'));
PhotosPrevious = struct2table(PhotosPrevious.Photos);

Photos = photoQuality(fullfile(DataFolder,PhotoFolder),Photos,PhotosPrevious);
%Photos = photoQuality(fullfile(DataFolder,PhotoFolder),Photos);

% assess quality
Photos.QualityOk = Photos.Sharpness > SharpThresh & ...
                   Photos.Contrast > ContrastThresh & ...
                   Photos.Brightness > BrightThresh;
               
% Save photo database as generating metrics takes a long time
save(fullfile(DataFolder,'\PhotoRecord\PhotoDatabase.mat'),...
     'Photos')
 
% load(fullfile(DataFolder,'\PhotoRecord\PhotoDatabase.mat'));
 
%% Sort images
[TimeMatchedPhotos] = timeMatchPhotos(Photos);

%% Read in timeseries data

% Read lagoon time series (already processed)
LagoonTS = readtable(fullfile(DataFolder,LagoonTsCsv));

% % Read channel dimensions (already processed)
% ChannelTS = readtable(fullfile(DataFolder,ChannelTsCsv));
% 
% % Read wavedata
% WaveTS = readTidedaCsv(fullfile(DataFolder,WaveCSV1));
% WaveTS2 = readTidedaCsv(fullfile(DataFolder,WaveCSV2));
% 
% % Combine wavedata into 1 table
% WaveTS = [WaveTS, WaveTS2(:,2:end)]; % if this line doesn't work check tideda exports for same time period and synchronised to 30min intervals
% clear WaveTS2

% Calculate long shore transport potential

%% Assign lagoon level info to image times
TimeMatchedPhotos.LagoonLevel = interp1(LagoonTS.DateTime, ...
                                        LagoonTS.WL, ...
                                        TimeMatchedPhotos.UniqueTime, ...
                                        'linear', nan);
    
% Save TimeMatchedPhotos table
save(fullfile(DataFolder,'\PhotoRecord\TimeMatchedPhotos.mat'),...
     'TimeMatchedPhotos')
 
% load(fullfile(DataFolder,'\PhotoRecord\TimeMatchedPhotos.mat'));
 
%% Make a cut down list of times with quality images from both cameras

% remove times with missing level data
ShortlistPhotos = TimeMatchedPhotos(~isnan(TimeMatchedPhotos.LagoonLevel),:);

% remove low quality photos
for ii=1:size(ShortlistPhotos,1)
    if ~isnan(ShortlistPhotos.Cam1Photo(ii));
        if ~Photos.QualityOk(ShortlistPhotos.Cam1Photo(ii));
            ShortlistPhotos.Cam1Photo(ii) = nan;
        end
    end
    if ~isnan(ShortlistPhotos.Cam2Photo(ii));
        if ~Photos.QualityOk(ShortlistPhotos.Cam2Photo(ii));
            ShortlistPhotos.Cam2Photo(ii) = nan;
        end
    end
end

% remove times with 1 missing or low quality image
ShortlistPhotos = ShortlistPhotos(~isnan(ShortlistPhotos.Cam1Photo) & ...
                                  ~isnan(ShortlistPhotos.Cam2Photo), :);

%% Make a list of daily high tide and low tide images

% Set standard WL for selection of consistent images
StandardWL = 1.5;

% Loop through days and identify high tide and low tide images
PhotoDates = floor(ShortlistPhotos.UniqueTime);
PhotoDays = unique(PhotoDates);

HT = nan(size(PhotoDays));
LT = nan(size(PhotoDays));

for ii = 1:size(PhotoDays)
    TodaysPhotos = PhotoDates == PhotoDays(ii);
    
    % ID high tide image
    [~,HT(ii)] = max(ShortlistPhotos.LagoonLevel +100 * TodaysPhotos);

    % ID low tide image
    [~,LT(ii)] = min(ShortlistPhotos.LagoonLevel -100 * TodaysPhotos);
    
    % ID standard tide image
    [~,ST(ii)] = min(abs(ShortlistPhotos.LagoonLevel - StandardWL) + ...
                     999 * ~TodaysPhotos);
end

HighTidePhotos = ShortlistPhotos(HT,:);
LowTidePhotos = ShortlistPhotos(LT,:);
StdTidePhotos = ShortlistPhotos(ST,:);

save(fullfile(DataFolder,'\PhotoRecord\HighTidePhotos.mat'),...
     'HighTidePhotos')
save(fullfile(DataFolder,'\PhotoRecord\LowTidePhotos.mat'),...
     'LowTidePhotos')
save(fullfile(DataFolder,'\PhotoRecord\StdTidePhotos.mat'),...
     'StdTidePhotos')
 
clear PhotoDates PhotoDays HT LT ST TodaysPhotos

% load(fullfile(DataFolder,'\PhotoRecord\LowTidePhotos.mat'))
% load(fullfile(DataFolder,'\PhotoRecord\HighTidePhotos.mat'))
% load(fullfile(DataFolder,'\PhotoRecord\StdTidePhotos.mat'))

%% Animate Lowtide and high tide images
animatePhotos('DailyLowTide', fullfile(DataFolder,PhotoFolder), Photos, ...
              LowTidePhotos, [], [], [], 2, true);
          
animatePhotos('DailyHighTide', fullfile(DataFolder,PhotoFolder), Photos, ...
              HighTidePhotos, [], [], [], 2, true);
          
animatePhotos('DailyStdTide', fullfile(DataFolder,PhotoFolder), Photos, ...
              StdTidePhotos, [], [], [], 2, true);

%% Loop through images and extract waters edge

NoOfDays = size(StdTidePhotos,1);

% Create variables to hold outputs. 
% first check if they exist in Photos table
if ~ismember('Twist', Photos.Properties.VariableNames)
    Photos.Twist = cell(size(Photos.FileName));
end
if ~ismember('WetBdy', Photos.Properties.VariableNames)
    Photos.WetBdy = cell(size(Photos.FileName));
end

% Loop through specific images only
% Cam1Photos = StdTidePhotos.Cam1Photo;
% Cam2Photos = StdTidePhotos.Cam2Photo;
% WL = StdTidePhotos.LagoonLevel;

% Loop through all (shortlisted/quality) images
Cam1Photos = ShortlistPhotos.Cam1Photo;
Cam2Photos = ShortlistPhotos.Cam2Photo;
WL = ShortlistPhotos.LagoonLevel;

Photo1FileName = fullfile(DataFolder, PhotoFolder, ...
                          Photos.FileSubDir(Cam1Photos), ...
                          strcat(Photos.FileName(Cam1Photos), ...
                                 '.jpg'));
Photo2FileName = fullfile(DataFolder, PhotoFolder, ...
                          Photos.FileSubDir(Cam2Photos), ...
                          strcat(Photos.FileName(Cam2Photos), ...
                                 '.jpg'));
Twist1 = Photos.Twist(Cam1Photos);
Twist2 = Photos.Twist(Cam2Photos);
WetBdy1 = Photos.WetBdy(Cam1Photos);
WetBdy2 = Photos.WetBdy(Cam2Photos);
                             
[Twist1, WetBdy1] = LagoonEdgePosition(Photo1FileName, ...
                                       WL, Cam1, ...
                                       FgBgMask1, SeedPixel1, ...
                                       Twist1, WetBdy1);
[Twist2, WetBdy2] = LagoonEdgePosition(Photo2FileName, ...
                                       WL, Cam2, ...
                                       FgBgMask2, SeedPixel2, ...
                                       Twist1, WetBdy2); 
                                       %NOTE this uses twist1 as an input

% Put variables into photos table
Photos.Twist(Cam1Photos) = Twist1;
Photos.Twist(Cam2Photos) = Twist2;
Photos.WetBdy(Cam1Photos) = WetBdy1;
Photos.WetBdy(Cam2Photos) = WetBdy2;

% Clean up
clear Cam1Photos Cam2Photos Photo1FileName Photo2FileName Twist1 Twist2 ...
    WetBdy1 WetBdy2

% Save
save(fullfile(DataFolder,'\PhotoRecord\PhotoDatabase.mat'),...
     'Photos')
 
    
%% Extract cross-section barrier backshore position

%polyxpoly


