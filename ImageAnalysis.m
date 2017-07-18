% Image Pre processing for hapua fixed camera images
% Richard Measures 2015
%
% Basic process:
% - genPhotoDataTable
% - photoQuality

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

%% Find available images and extract key information
AllPhotos = genPhotoDataTable(fullfile(Config.DataFolder,Config.PhotoFolder));

%% Make cut down list (30min rather than 15min)
[~ ,~ ,~ ,~ ,CaptureMins ,~ ] = datevec(AllPhotos.CaptureTime);
Photos = AllPhotos(CaptureMins==30 | CaptureMins==0,:);

clear AllPhotos

%% Load previously calculated metrics to avoid duplication of effort
PhotosPrevious = load('outputs\PhotoDatabase.mat');
PhotosPrevious = PhotosPrevious.Photos;

%% Generate quality metrics and assess quality

% generate metrics
Photos = photoQuality(fullfile(Config.DataFolder,Config.PhotoFolder), ...
                      Photos,PhotosPrevious);
%Photos = photoQuality(fullfile(Config.DataFolder,Config.PhotoFolder), ...
%                      Photos);

% assess quality
Photos.QualityOk = Photos.Sharpness > Config.SharpThresh & ...
                   Photos.Contrast > Config.ContrastThresh & ...
                   Photos.Brightness > Config.BrightThresh;

% tidy up
clear PhotosPrevious

% Save photo database as generating metrics takes a long time
save('outputs\PhotoDatabase.mat','Photos','-v7.3')
 
% load('outputs\PhotoDatabase.mat');
 
%% Sort images
[TimeMatchedPhotos] = timeMatchPhotos(Photos);

%% Read in timeseries data

% Read lagoon time series (already processed)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

%% Assign lagoon level info to image times
TimeMatchedPhotos.LagoonLevel = interp1(LagoonTS.DateTime, ...
                                        LagoonTS.WL, ...
                                        TimeMatchedPhotos.UniqueTime, ...
                                        'linear', nan);

%% Create timelapse
animatePhotos('outputs/HurunuiTimeLapse', ...
              fullfile(Config.DataFolder, Config.PhotoFolder), Photos, ...
              TimeMatchedPhotos, LagoonTS, 24, true);
                                    
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
% break the process I can get the results out... Pareval might be better?
IterationLimit = 70;
NoToProcess = size(ShortlistPhotos,1);

for ii = [IterationLimit:IterationLimit:NoToProcess,NoToProcess]
    ThisLoop = ii-(IterationLimit-1):1:ii;
    Cam1Photos = ShortlistPhotos.Cam1Photo(ThisLoop);
    Cam2Photos = ShortlistPhotos.Cam2Photo(ThisLoop);
    WL = ShortlistPhotos.LagoonLevel(ThisLoop);

    Photo1FileName = fullfile(Config.DataFolder, Config.PhotoFolder, ...
                              Photos.FileSubDir(Cam1Photos), ...
                              strcat(Photos.FileName(Cam1Photos), '.jpg'));
    Photo2FileName = fullfile(Config.DataFolder, Config.PhotoFolder, ...
                              Photos.FileSubDir(Cam2Photos), ...
                              strcat(Photos.FileName(Cam2Photos), '.jpg'));
    Twist1 = Photos.Twist(Cam1Photos);
    %Twist2 = Photos.Twist(Cam2Photos);
    Twist2 = cellfun(@(x) [x(1),-x(2)], Twist1, 'UniformOutput', false);
    WetBdy1 = Photos.WetBdy(Cam1Photos);
    WetBdy2 = Photos.WetBdy(Cam2Photos);

    [Twist1, WetBdy1] = LagoonEdgePosition(Photo1FileName, ...
                                           WL, Config.Cam1, ...
                                           Config.FgBgMask1, ...
                                           Config.SeedPixel1, ...
                                           Twist1, WetBdy1);
    
    [Twist2, WetBdy2] = LagoonEdgePosition(Photo2FileName, ...
                                           WL, Config.Cam2, ...
                                           Config.FgBgMask2, ...
                                           Config.SeedPixel2, ...
                                           Twist2, WetBdy2); 

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
clear Cam1Photos Cam2Photos WL Photo1FileName Photo2FileName Twist1 Twist2 ...
    WetBdy1 WetBdy2 IterationLimit NoToProcess ThisLoop ii

% Save
save('outputs\PhotoDatabase.mat','Photos','-v7.3')
 

%% QA on twist results
ShortlistPhotos.TwistX = cellfun(@(x) x(1,1), Photos.Twist(ShortlistPhotos.Cam1Photo));
ShortlistPhotos.TwistY = cellfun(@(x) x(1,2), Photos.Twist(ShortlistPhotos.Cam1Photo));

WindowSize = 20;

PropDistLT = propTwistDistLT(ShortlistPhotos.TwistX, ShortlistPhotos.TwistY*2, 20, 20);

Outliers = PropDistLT < 0.35;

% view filtering results
plot(ShortlistPhotos.UniqueTime(~Outliers), ShortlistPhotos.TwistX(~Outliers), 'bx', ...
     ShortlistPhotos.UniqueTime(Outliers), ShortlistPhotos.TwistX(Outliers), 'rx', ...
     ShortlistPhotos.UniqueTime(~Outliers), ShortlistPhotos.TwistY(~Outliers), 'b+', ...
     ShortlistPhotos.UniqueTime(Outliers), ShortlistPhotos.TwistY(Outliers), 'r+');
legend('valid TwistX','outlier TwistX','valid TwistY', 'outlier TwistY')
ylabel('Twist (pixels)')

%% Extract cross-section barrier backshore position

% create column in ShortlistPhotos table to hold outputs if not already present
if ~any(strcmp('Offsets', ShortlistPhotos.Properties.VariableNames))
    ShortlistPhotos.Offsets = nan(size(ShortlistPhotos,1), ...
                                  size(Config.Transects,1));
end

% only process timesteps with WetBdy for both cameras
TimesToProcess = ~cellfun(@isempty,Photos.WetBdy(ShortlistPhotos.Cam1Photo)) & ...
                 ~cellfun(@isempty,Photos.WetBdy(ShortlistPhotos.Cam2Photo));
PhotosToProcess = ShortlistPhotos(TimesToProcess,:);

% Calculate the offsets for all times and transects
[ShortlistPhotos.Offsets(TimesToProcess,:)] = ...
    measureLagoonWidth(PhotosToProcess, Photos, Config.Transects, false);

% tidy up
clear TimesToProcess PhotosToProcess

%% plot the offset TS
plot(ShortlistPhotos.UniqueTime, ShortlistPhotos.Offsets(:,7), 'x')

%% Make a list of daily high tide and low tide images

% Loop through days and identify high tide and low tide images
PhotoDates = dateshift(ShortlistPhotos.UniqueTime,'start','day');
UniquePhotoDates = unique(PhotoDates);

HT = nan(size(UniquePhotoDates));
LT = nan(size(UniquePhotoDates));

for ii = 1:size(UniquePhotoDates)
    TodaysPhotos = PhotoDates == UniquePhotoDates(ii);
    
    % ID high tide image
    [~,HT(ii)] = max(ShortlistPhotos.LagoonLevel +100 * TodaysPhotos);

    % ID low tide image
    [~,LT(ii)] = min(ShortlistPhotos.LagoonLevel -100 * TodaysPhotos);
    
    % ID standard tide image
    [~,ST(ii)] = min(abs(ShortlistPhotos.LagoonLevel - Config.StandardWL) + ...
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
 
clear PhotoDates UniquePhotoDates HT LT ST TodaysPhotos

% load(outputs\LowTidePhotos.mat')
% load(outputs\HighTidePhotos.mat')
% load(outputs\StdTidePhotos.mat')

%% Animate Lowtide and high tide images
animatePhotos('outputs\DailyLowTide', ...
              fullfile(Config.DataFolder,Config.PhotoFolder), Photos, ...
              LowTidePhotos, LagoonTS, 2, true);
          
animatePhotos('outputs\DailyHighTide', ...
              fullfile(Config.DataFolder,Config.PhotoFolder), Photos, ...
              HighTidePhotos, LagoonTS, 2, true);
          
animatePhotos('outputs\DailyStdTide', ...
              fullfile(Config.DataFolder,Config.PhotoFolder), Photos, ...
              StdTidePhotos, LagoonTS, 2, true);
