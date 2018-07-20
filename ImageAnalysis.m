%IMAGEANALYSIS   Image processing for Hurunui hapua timelapse imagery
%   This script runs the main image processing workflow to analyse fixed
%   camera timelapse imagery from the Hurunui Hapua. 
%
%   Key outputs from the script are:
%      - 'outputs\PhotoDatabase.mat' a database of photos including quality
%        metrics.
%      - 'outputs\ShortlistPhotos.mat' a database of quality image pairs
%        including calculated lagoon waters edge location and width at
%        transects.
%   
%   The workflow involves:
%      - Cataloging the photos (genPhotoDataTable).
%      - Assessing photo quality to screen out low quality images 
%        (photoQuality).
%      - Sorting images into time-matched pairs (timeMatchPhotos).
%      - Reading in timeseries data and assigning lagoon level to each
%        image.
%      - Identifying fixed objects in images to correct for camera
%        movement, identifying waters edge, and projecting onto a flat
%        plane at the elevation of the lagoon water surface 
%        (lagoonEdgePosition).
%      - Filtering to remove inconsistent waters edge or camera orientation
%        measurements (propDistLT).
%      - Measuring lagoon width at specific measurement transects based on 
%        the identified waters edge location (measureLagoonWidth).
%      
%   Pre-requisits to run this script are:
%      - Configuration parameters in HurunuiAnalysisConfig set up correctly
%      - Photos labeled by capture time and saved within a single directory
%        (sub-directories are allowed). The directory structure created by 
%        the OrganiseImages script is ideal but other structures would also 
%        work.
%      - Timeseries data processed by the TimeseriesAnalysis script (the
%        script stores output to 'outputs\LagoonTS.csv' which is then read 
%        in by ImageAnalysis).
%
%   See Also: HURUNUIANALYSISCONFIG, ORGANISEIMAGES, GENPHOTODATATABLE, 
%             PHOTOQUALITY, TIMEMATCHPHOTOS, LAGOONEDGEPOSITION,
%             PROPDISTLT, MEASURELAGOONWIDTH, TIMESERIESANALYSIS.

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% get screensize for plot setups
ScrSz = get(groot, 'ScreenSize');

%% Read in timeseries data

% Read lagoon time series (already processed by TimeseriesAnalysis)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

%% Find available images and extract key information
AllPhotos = genPhotoDataTable(fullfile(Config.DataFolder,Config.PhotoFolder));

%% Make cut down list (30min rather than 15min)
[~ ,~ ,~ ,~ ,CaptureMins ,~ ] = datevec(AllPhotos.CaptureTime);
Photos = AllPhotos(CaptureMins==30 | CaptureMins==0,:);

clear AllPhotos CaptureMins

%% Generate quality metrics and assess quality

% See if there are any previously calculated
if exist('outputs\PhotoDatabase.mat','file')
    % Re-use previously calculated metrics to avoid duplication of effort
    PhotosPrevious = load('outputs\PhotoDatabase.mat');
    PhotosPrevious = PhotosPrevious.Photos;
    Photos = photoQuality(fullfile(Config.DataFolder,Config.PhotoFolder), ...
                          Photos,PhotosPrevious);
else
    % generate metrics from scratch
    Photos = photoQuality(fullfile(Config.DataFolder,Config.PhotoFolder), ...
                          Photos);
end

% assess quality
Photos.QualityOk = Photos.Sharpness > Config.SharpThresh & ...
                   Photos.Contrast > Config.ContrastThresh & ...
                   Photos.Brightness > Config.BrightThresh;

% tidy up
clear PhotosPrevious

% Save photo database as generating metrics takes a long time
save('outputs\PhotoDatabase.mat','Photos','-v7.3')
 
% load('outputs\PhotoDatabase.mat');

%% Summarise number of quality images per month as a check
BinEdges = dateshift(min(Photos.CaptureTime),'start','month'): ...
           caldays(1): ...
           dateshift(max(Photos.CaptureTime),'end','month');
figure
plot(BinEdges(1:end-1)', ...
     [histcounts(Photos.CaptureTime(Photos.CameraNo==1),BinEdges)', ...
      histcounts(Photos.CaptureTime(Photos.CameraNo==2),BinEdges)', ...
      histcounts(Photos.CaptureTime(Photos.CameraNo==1&Photos.QualityOk),BinEdges)', ...
      histcounts(Photos.CaptureTime(Photos.CameraNo==2&Photos.QualityOk),BinEdges)'])
legend({'Camera 1 images', 'Camera 2 images', ...
        'Camera 1 quality images', 'Camera 2 quality images'})
ylabel('Number of images/day')
 
%% Sort images into mtched pairs
[TimeMatchedPhotos] = timeMatchPhotos(Photos);

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
    if ~isnan(ShortlistPhotos.Cam1Photo(ii))
        if ~Photos.QualityOk(ShortlistPhotos.Cam1Photo(ii))
            ShortlistPhotos.Cam1Photo(ii) = nan;
        end
    end
    if ~isnan(ShortlistPhotos.Cam2Photo(ii))
        if ~Photos.QualityOk(ShortlistPhotos.Cam2Photo(ii))
            ShortlistPhotos.Cam2Photo(ii) = nan;
        end
    end
end

% remove times with 1 missing or low quality image
ShortlistPhotos = ShortlistPhotos(~isnan(ShortlistPhotos.Cam1Photo) & ...
                                  ~isnan(ShortlistPhotos.Cam2Photo), :);
                              
clear ii

%% Loop through images, measure twist and extract waters edge

% Create variables to hold outputs. 
% (first check if they exist in ShortlistPhotos table)
if ~ismember('Twist', ShortlistPhotos.Properties.VariableNames)
    ShortlistPhotos.Twist = nan(height(ShortlistPhotos),3);
end
if ~ismember('WetBdy', ShortlistPhotos.Properties.VariableNames)
    ShortlistPhotos.WetBdy = cell(height(ShortlistPhotos),1);
end

% Import previous data if available
if exist('outputs\ShortlistPhotos.mat','file')
    OldShortlistPhotos = load('outputs\ShortlistPhotos.mat');
    OldShortlistPhotos = OldShortlistPhotos.ShortlistPhotos;
    % find matching data
    [~,IA,IB] = intersect(OldShortlistPhotos.UniqueTime, ...
                          ShortlistPhotos.UniqueTime,'stable');
    ShortlistPhotos(IB,{'Twist','WetBdy'}) = OldShortlistPhotos(IA,{'Twist','WetBdy'});
    clear OldShortlistPhotos
end

TimeNoToProcess = find(cellfun(@isempty,ShortlistPhotos.WetBdy));
NoToProcess = size(TimeNoToProcess,1);

% limit the number of timesteps processed at a time so that if I need to
% break the process I can get the results out... Pareval might be better?
IterationLimit = 70;

ii = 1;
while ii <= NoToProcess
    ThisLoop = TimeNoToProcess(ii : min(ii+IterationLimit-1, NoToProcess))';
    ii = min(ii+IterationLimit-1, NoToProcess) + 1;
    
    Cam1Photos = ShortlistPhotos.Cam1Photo(ThisLoop);
    Cam2Photos = ShortlistPhotos.Cam2Photo(ThisLoop);
    WL = ShortlistPhotos.LagoonLevel(ThisLoop);

    Photo1FileName = fullfile(Config.DataFolder, Config.PhotoFolder, ...
                              Photos.FileSubDir(Cam1Photos), ...
                              strcat(Photos.FileName(Cam1Photos), '.jpg'));
    Photo2FileName = fullfile(Config.DataFolder, Config.PhotoFolder, ...
                              Photos.FileSubDir(Cam2Photos), ...
                              strcat(Photos.FileName(Cam2Photos), '.jpg'));
    Twist1 = ShortlistPhotos.Twist(ThisLoop,:);
    WetBdy1 = ShortlistPhotos.WetBdy(ThisLoop);
    WetBdy2 = ShortlistPhotos.WetBdy(ThisLoop);
    
    fprintf('Camera1: ')
    [Twist1, WetBdy1] = lagoonEdgePosition(Photo1FileName, ...
                                           WL, Config.Cam1, ...
                                           Config.FgBgMask1, ...
                                           Config.SeedPixel1, ...
                                           Twist1, WetBdy1);
    
    Twist2 = [Twist1(:,1),-Twist1(:,2),-Twist1(:,3)];
    fprintf('Camera2: ')
    [ ~    , WetBdy2] = lagoonEdgePosition(Photo2FileName, ...
                                           WL, Config.Cam2, ...
                                           Config.FgBgMask2, ...
                                           Config.SeedPixel2, ...
                                           Twist2, WetBdy2); 

    % Put variables into ShortlistPhotos table
    ShortlistPhotos.Twist(ThisLoop,:) = Twist1;
    ShortlistPhotos.WetBdy(ThisLoop) = ...
        cellfun(@(a,b) [a;nan(1,2);b], WetBdy1, WetBdy2, ...
                'UniformOutput', false);
    % ShortlistPhotos.WetBdy(isempty(WetBdy1) && isempty(WetBdy2)) = [];
    
    % Report progress
    fprintf('Extracting waters edge. %i out of %i completed\n', ...
            ii-1, NoToProcess)
end
    
% Clean up
clear Cam1Photos Cam2Photos WL Photo1FileName Photo2FileName Twist1 ...
    Twist2 WetBdy1 WetBdy2 IterationLimit NoToProcess ThisLoop ii ...
    TimeNoToProcess

% Save
save('outputs\ShortlistPhotos.mat','ShortlistPhotos','-v7.3')
 
% load('outputs\ShortlistPhotos.mat')

%% QA on twist results

% calculate proportion of surrounding points within threshold tolerance
WindowSize = 15;
PixelThreshold = 15;
PropThreshold = 0.35;
PropDistLT = propDistLT([ShortlistPhotos.Twist(:,1), ...
                         ShortlistPhotos.Twist(:,2)*2], ...
                        WindowSize, PixelThreshold, true);

ShortlistPhotos.TwistOK = PropDistLT > PropThreshold;

% view filtering results
figure('Position', [(ScrSz(3)/2)-600, ScrSz(4)/2-200, 1200, 400]);
orient landscape
plot(ShortlistPhotos.UniqueTime(ShortlistPhotos.TwistOK), ...
       ShortlistPhotos.Twist(ShortlistPhotos.TwistOK,1), 'bx', ...
     ShortlistPhotos.UniqueTime(~ShortlistPhotos.TwistOK), ...
       ShortlistPhotos.Twist(~ShortlistPhotos.TwistOK,1), 'rx', ...
     ShortlistPhotos.UniqueTime(ShortlistPhotos.TwistOK), ...
       ShortlistPhotos.Twist(ShortlistPhotos.TwistOK,2), 'b+', ...
     ShortlistPhotos.UniqueTime(~ShortlistPhotos.TwistOK), ...
       ShortlistPhotos.Twist(~ShortlistPhotos.TwistOK,2), 'r+');
legend('valid TwistX','outlier TwistX','valid TwistY', 'outlier TwistY')
ylabel('Twist (pixels)')
export_fig 'outputs\TwistQA.pdf' -pdf

clear WindowSize PixelThreshold PropDistLT

%% simple QA on WetBdy results
WetBdySize = cellfun(@(x) size(x,1), ShortlistPhotos.WetBdy);
ShortlistPhotos.WetBdyOK = WetBdySize>1000;
clear WetBdySize

%% Extract cross-section barrier backshore position

% create column in ShortlistPhotos table to hold outputs if not already present
% note: allows up to 5 intersection points per transect
MaxIntersections = 5;
if ~any(strcmp('Offsets', ShortlistPhotos.Properties.VariableNames))
    ShortlistPhotos.Offsets = nan(size(ShortlistPhotos,1), ...
                                  size(Config.Transects,1), ...
                                  MaxIntersections);
end

% only process timesteps which pass quality checks
TimesToProcess = ShortlistPhotos.TwistOK & ShortlistPhotos.WetBdyOK;

% Calculate the offsets for all times and transects
[ShortlistPhotos.Offsets(TimesToProcess,:,:)] = ...
    measureLagoonWidth(ShortlistPhotos(TimesToProcess,:), ...
                       Config.Transects, false);

save('outputs\ShortlistPhotos.mat','ShortlistPhotos','-v7.3')

% tidy up
clear TimesToProcess

%% QA on Offsets

% calculate proportion of surrounding points within threshold tolerance
ShortlistPhotos.OffsetOK = nan(size(ShortlistPhotos.Offsets));
OffsetOK = false(size(ShortlistPhotos.Offsets));
WindowSize = 100;
OffsetThreshold = 6; % in metres
PropThreshold = 0.5; % proportion which must be within threshold distance
for TransectNo = 1:size(ShortlistPhotos.Offsets,2)
    ProportionOK = propDistLT(permute(ShortlistPhotos.Offsets(:,TransectNo,:), [1,3,2]), ...
                              WindowSize, OffsetThreshold, false);

    OffsetOK(:,TransectNo,:) = permute(ProportionOK > PropThreshold,[1,3,2]);
end
ShortlistPhotos.OffsetOK(OffsetOK) = ShortlistPhotos.Offsets(OffsetOK);

save('outputs\ShortlistPhotos.mat','ShortlistPhotos','-v7.3')
% ShortlistPhotos.WetBdy = []; save('ShortlistPhotos_small.mat','ShortlistPhotos');

clear WindowSize OffsetThreshold PropThreshold ProportionOK OffsetOK

%% plot the filtered Offset time series
for TransectNo = 1:13 %size(ShortlistPhotos.Offsets,2);
    figure('Position', [(ScrSz(3)/2)-660+10*(TransectNo-1), ...
                        ScrSz(4)/2-100+10*(TransectNo-1), 1200, 400],...
           'PaperOrientation', 'landscape');
    AllDataH = plot(ShortlistPhotos.UniqueTime, ...
                    permute(ShortlistPhotos.Offsets(:,TransectNo,:),[1,3,2]), ...
                    'x', 'color', [0.85,0.85,0.85], 'MarkerSize', 4);
    hold on
    QADataH = plot(ShortlistPhotos.UniqueTime, ...
                   permute(ShortlistPhotos.OffsetOK(:,TransectNo,:),[1,3,2]), ...
                   'bx', 'MarkerSize', 6);
    hold off
    title(sprintf('Transect %i',TransectNo))
    ylabel('Lagoon width (m)')
    ylim([0,250])
    set(gca, 'YTick', 0:50:250)
    legend([AllDataH(1), QADataH(1)], ...
           {'All width data','Width data passing QA/consistency check'})
%     if TransectNo == 1
%         export_fig 'outputs\Offsets.pdf' -pdf
%     else
%         export_fig 'outputs\Offsets.pdf' -pdf -append
%     end
%     close
end
clear TransectNo AllDataH QADataH

%% Make a list of daily high tide and low tide images

% Loop through days and identify high tide and low tide images
PhotoDates = dateshift(ShortlistPhotos.UniqueTime,'start','day');
UniquePhotoDates = unique(PhotoDates);

HT = nan(size(UniquePhotoDates));
LT = nan(size(UniquePhotoDates));
ST = nan(size(UniquePhotoDates));

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

% load('outputs\LowTidePhotos.mat')
% load('outputs\HighTidePhotos.mat')
% load('outputs\StdTidePhotos.mat')

%% Plot offsets for std tide
figure('Position', [1, ScrSz(4)/2, ScrSz(3), 300]);
plot(ShortlistPhotos.UniqueTime, ShortlistPhotos.OffsetOK, 'x')
ylabel('Offset to barrier backshore (m)')

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
