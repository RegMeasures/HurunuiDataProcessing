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
DataFolder = 'C:\Projects\Hurunui';
%DataFolder = '\\engcad4\GISdump\Richard\';
%DataFolder = 'H:\Hapua\Individual_Hapua\Hurunui\';
%DataFolder = 'E:\Hurunui';

% Photo directory containing all images
PhotoFolder = '\PhotoRecord\ImageStore';

% Processed Lagoon TS
LagoonTsCsv = 'outputs\LagoonTS.csv';

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

clear AllPhotos

%% Load previously calculated metrics to avoid duplication of effort
PhotosPrevious = load('outputs\PhotoDatabase.mat');
PhotosPrevious = PhotosPrevious.Photos;

%% Generate quality metrics and assess quality

% generate metrics
Photos = photoQuality(fullfile(DataFolder,PhotoFolder),Photos,PhotosPrevious);
%Photos = photoQuality(fullfile(DataFolder,PhotoFolder),Photos);

% assess quality
Photos.QualityOk = Photos.Sharpness > SharpThresh & ...
                   Photos.Contrast > ContrastThresh & ...
                   Photos.Brightness > BrightThresh;

% tidy up
clear PhotosPrevious

% Save photo database as generating metrics takes a long time
save('outputs\PhotoDatabase.mat','Photos')
 
% load('outputs\PhotoDatabase.mat');
 
%% Sort images
[TimeMatchedPhotos] = timeMatchPhotos(Photos);

%% Read in timeseries data

% Read lagoon time series (already processed)
LagoonTS = readtable(LagoonTsCsv);
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

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

%% Create timelapse
animatePhotos('outputs/HurunuiTimeLapse', fullfile(DataFolder,PhotoFolder), Photos, ...
              TimeMatchedPhotos, LagoonTS, [], [], 24, true);
                                    
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
PhotoDates = dateshift(ShortlistPhotos.UniqueTime,'start','day');
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

save('outputs\HighTidePhotos.mat',...
     'HighTidePhotos');
save('outputs\LowTidePhotos.mat',...
     'LowTidePhotos');
save('outputs\StdTidePhotos.mat',...
     'StdTidePhotos');
 
clear PhotoDates PhotoDays HT LT ST TodaysPhotos

% load(outputs\LowTidePhotos.mat')
% load(outputs\HighTidePhotos.mat')
% load(outputs\StdTidePhotos.mat')

%% Animate Lowtide and high tide images
animatePhotos('outputs\DailyLowTide', fullfile(DataFolder,PhotoFolder), Photos, ...
              LowTidePhotos, LagoonTS, [], [], 2, true);
          
animatePhotos('outputs\DailyHighTide', fullfile(DataFolder,PhotoFolder), Photos, ...
              HighTidePhotos, LagoonTS, [], [], 2, true);
          
animatePhotos('outputs\DailyStdTide', fullfile(DataFolder,PhotoFolder), Photos, ...
              StdTidePhotos, LagoonTS, [], [], 2, true);

%% Loop through images and extract waters edge

% Create variables to hold outputs. 
% (first check if they exist in Photos table)
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


% limit the number of timesteps processed at a time so that if I need to
% break the process I can get out the results... Pareval might be better?
IterationLimit = 70;
NoToProcess = size(ShortlistPhotos,1);

for ii = [IterationLimit:IterationLimit:NoToProcess,NoToProcess];
    % Loop through all (shortlisted/quality) images
    ThisLoop = ii-(IterationLimit-1):1:ii;
    Cam1Photos = ShortlistPhotos.Cam1Photo(ThisLoop);
    Cam2Photos = ShortlistPhotos.Cam2Photo(ThisLoop);
    WL = ShortlistPhotos.LagoonLevel(ThisLoop);

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
%     [Twist2, WetBdy2] = LagoonEdgePosition(Photo2FileName, ...
%                                            WL, Cam2, ...
%                                            FgBgMask2, SeedPixel2, ...
%                                            Twist1, WetBdy2); 
%                                            %NOTE this uses twist1 as an input

    % Put variables into photos table
    Photos.Twist(Cam1Photos) = Twist1;
    Photos.Twist(Cam2Photos) = Twist2;
    Photos.WetBdy(Cam1Photos) = WetBdy1;
    Photos.WetBdy(Cam2Photos) = WetBdy2;
    
    % Report progress
    fprintf('Extracting waters edge. %i out of %i completed\n', ...
            ii, NoToProcess)
end
    
% Clean up
clear Cam1Photos Cam2Photos Photo1FileName Photo2FileName Twist1 Twist2 ...
    WetBdy1 WetBdy2 IterationLimit ThisLoop ii

% Save
save('outputs\PhotoDatabase.mat','Photos')
 
%% Extract lagoon area

%polyarea

%% Extract cross-section barrier backshore position

%polyxpoly


