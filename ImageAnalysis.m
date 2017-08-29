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

% get screensize for plot setups
ScrSz = get(groot, 'ScreenSize');

%% Find available images and extract key information
AllPhotos = genPhotoDataTable(fullfile(Config.DataFolder,Config.PhotoFolder));

%% Make cut down list (30min rather than 15min)
[~ ,~ ,~ ,~ ,CaptureMins ,~ ] = datevec(AllPhotos.CaptureTime);
Photos = AllPhotos(CaptureMins==30 | CaptureMins==0,:);

clear AllPhotos

%% Generate quality metrics and assess quality

% generate metrics from scratch
Photos = photoQuality(fullfile(Config.DataFolder,Config.PhotoFolder), ...
                      Photos);
                  
% Or alternatively re-use previously calculated metrics to avoid duplication of effort
%PhotosPrevious = load('outputs\PhotoDatabase.mat');
%PhotosPrevious = PhotosPrevious.Photos;
%Photos = photoQuality(fullfile(Config.DataFolder,Config.PhotoFolder), ...
%                      Photos,PhotosPrevious);

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

%% Loop through images, measure twist and extract waters edge

NoToProcess = size(ShortlistPhotos,1);

% Create variables to hold outputs. 
% (first check if they exist in ShortlistPhotos table)
if ~ismember('Twist', ShortlistPhotos.Properties.VariableNames)
    ShortlistPhotos.Twist = nan(NoToProcess,2);
end
if ~ismember('WetBdy', ShortlistPhotos.Properties.VariableNames)
    ShortlistPhotos.WetBdy = cell(NoToProcess,1);
end

% limit the number of timesteps processed at a time so that if I need to
% break the process I can get the results out... Pareval might be better?
IterationLimit = 70;

ii = 1;
while ii <= NoToProcess
    ThisLoop = ii : min(ii+IterationLimit-1, NoToProcess);
    ii = ThisLoop(end) + 1;
    
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
    Twist2 = [Twist1(:,1),Twist1(:,2)];
    WetBdy1 = ShortlistPhotos.WetBdy(ThisLoop);
    WetBdy2 = ShortlistPhotos.WetBdy(ThisLoop);
    
    fprintf('Camera1: ')
    [Twist1, WetBdy1] = LagoonEdgePosition(Photo1FileName, ...
                                           WL, Config.Cam1, ...
                                           Config.FgBgMask1, ...
                                           Config.SeedPixel1, ...
                                           Twist1, WetBdy1);
    
    fprintf('Camera2: ')
    [ ~    , WetBdy2] = LagoonEdgePosition(Photo2FileName, ...
                                           WL, Config.Cam2, ...
                                           Config.FgBgMask2, ...
                                           Config.SeedPixel2, ...
                                           Twist2, WetBdy2); 

    % Put variables into ShortlistPhotos table
    ShortlistPhotos.Twist(ThisLoop,:) = Twist1;
    ShortlistPhotos.WetBdy(ThisLoop) = ...
        cellfun(@(a,b) [a;nan(1,2);b], WetBdy1, WetBdy2, ...
                'UniformOutput', false);
    ShortlistPhotos.WetBdy(isempty(WetBdy1) && isempty(WetBdy2)) = [];
    
    % Report progress
    fprintf('Extracting waters edge. %i out of %i completed\n', ...
            ii-1, NoToProcess)
end
    
% Clean up
clear Cam1Photos Cam2Photos WL Photo1FileName Photo2FileName Twist1 Twist2 ...
    WetBdy1 WetBdy2 IterationLimit NoToProcess ThisLoop ii

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

% tidy up
clear TimesToProcess

%% QA on Offsets

% calculate proportion of surrounding points within threshold tolerance
ShortlistPhotos.OffsetOK = nan(size(ShortlistPhotos.Offsets));
OffsetOK = false(size(ShortlistPhotos.Offsets));
WindowSize = 200;
OffsetThreshold = 10;
PropThreshold = 0.4;
for TransectNo = 1:size(ShortlistPhotos.Offsets,2)
    ProportionOK = propDistLT(ShortlistPhotos.Offsets(:,TransectNo,:), ...
                              WindowSize, OffsetThreshold, false);

    OffsetOK(:,TransectNo) = ProportionOK > PropThreshold;
end
ShortlistPhotos.OffsetOK(OffsetOK) = ShortlistPhotos.Offsets(OffsetOK);

clear WindowSize OffsetThreshold PropThreshold ProportionOK OffsetOK

% plot the filtered Offset time series
for TransectNo = 1:size(ShortlistPhotos.Offsets,2);
    figure('Position', [(ScrSz(3)/2)-660+10*(TransectNo-1), ...
                        ScrSz(4)/2-10*(TransectNo-1), 1200, 400],...
           'PaperOrientation', 'landscape');
    plot(ShortlistPhotos.UniqueTime, permute(ShortlistPhotos.Offsets(:,TransectNo,:),[1,3,2]), 'rx', ...
         ShortlistPhotos.UniqueTime, permute(ShortlistPhotos.OffsetOK(:,TransectNo,:),[1,3,2]), 'bx')
    title(sprintf('Transect %i',TransectNo))
    ylabel('Lagoon width (m)')
    ylim([0,200])
    if TransectNo == 1
        export_fig 'outputs\Offests.pdf' -pdf
    else
        export_fig 'outputs\Offests.pdf' -pdf -append
    end
    close
end
clear TransectNo

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
