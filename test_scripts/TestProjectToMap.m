% Test/calibrate image projection and wet edge ID against surveyed WE

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('..\functions'))
addpath(genpath('..\inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% get screensize for plot setups
ScrSz = get(groot, 'ScreenSize');

%% Specify camera settings
% Config.Cam1.Resolution = [2592,1944];      % Image size [across,down] (pixels)
% Config.Cam1.Bearing    = 192.5;            % Bearing of center of image (degrees)
% Config.Cam1.Pitch      = -21.4;            % Altitude angle of image center (usually negative as this indicates the image is looking down of horizontal)
% Config.Cam1.Roll       = +2.03;            % Roll angle of camera (clockwise = positive)
% Config.Cam1.ViewWidth  = 63.0;             % width of field of view (degrees)
% Config.Cam1.Height     = 7.55 + 26.476;    % elevation of camera
% Config.Cam1.Easting    = 1623524.9;        % Easting of camera
% Config.Cam1.Northing   = 5249500.7;        % Northing of camera
% Config.Cam1.k          = +0.240;           % k value for barrel distortion correction as used for lensdistort
% 
% Config.Cam2.Resolution = Cam1.Resolution;
% Config.Cam2.Bearing    = 062.5;
% Config.Cam2.Pitch      = -23.40;
% Config.Cam2.Roll       = +0.80;
% Config.Cam2.ViewWidth  = 67;
% Config.Cam2.Height     = Cam1.Height;
% Config.Cam2.Easting    = Cam1.Easting;
% Config.Cam2.Northing   = Cam1.Northing;
% Config.Cam2.k          = +0.325;

%% try simple distortion correction with checkerboard images
% Cam1Folder = ('E:\Hurunui\PhotoRecord\checkerboard images\camera1');
% Cam2Folder = ('E:\Hurunui\PhotoRecord\checkerboard images\camera2');
% Cam1Images = dir(fullfile(Cam1Folder,'*.jpg'));
% Cam2Images = dir(fullfile(Cam1Folder,'*.jpg'));
% 
% for ImageNo = 1:size(Cam1Images,1)
%     % load test image
%     TestImage1 = imread(fullfile(Cam1Folder,Cam1Images(ImageNo,1).name));
%     % imshow(TestImage)
% 
%     % try lensdistort function 
%     % note: requires Image_Toolbox license
%     % TestCorrected = lensdistort(TestImage1, -0.187, 'bordertype', 'fit');
%     % figure
%     % imshow(TestCorrected)
% 
%     Cam1.PixelPositions = ProjectImage(Cam1,WL,TestImage1);
% end

%% Project image Test 1

% load test image
% TestImage1 = imread('H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2015\10\Hurunui1\Hurunui1_15-10-07_15-28-48-75.jpg');
% TestImage2 = imread('H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2015\10\Hurunui2\Hurunui2_15-10-07_15-28-52-74.jpg');
TestImage1 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui1_15-10-07_15-28-48-75.jpg');
TestImage2 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui2_15-10-07_15-28-52-74.jpg');

% load surveyed waters edge
% SurveyPts = readRtkSurveyCsv('H:\Hapua\Individual_Hapua\Hurunui\Survey\2015-10-07 barrier RTK\Survey_Pts_Beach_Barrier_Oct15.csv');
SurveyPts = readRtkSurveyCsv('E:\Hurunui\Survey\2015-10-07 barrier RTK\Survey_Pts_Beach_Barrier_Oct15.csv');
LagoonWE = SurveyPts(3:108,:);
MouthWE = SurveyPts(117:131,:);
WL = mean(LagoonWE.Elevation);

% find wet edges
[WetMask1, WetBdy1] = WetDry2(TestImage1, Config.FgBgMask1, [1628, 1013], [], false);
[WetMask2, WetBdy2] = WetDry2(TestImage2, Config.FgBgMask2, [1334, 950], [], false);

% convert WetBdys to easting northing
[BdyEasting1, BdyNorthing1] = ...
    ProjectToMap(Config.Cam1, WL, [], WetBdy1(:,1), WetBdy1(:,2));
[BdyEasting2, BdyNorthing2] = ...
    ProjectToMap(Config.Cam2, WL, [], WetBdy2(:,1), WetBdy2(:,2));
WetBdy1 = [BdyEasting1, BdyNorthing1];
WetBdy2 = [BdyEasting2, BdyNorthing2];

% Remove backshore part of WetBdy polygon to leave polyline along barrier
WetBdy1 = cleanWetBdy(WetBdy1);
WetBdy2 = cleanWetBdy(WetBdy2);

% display projected image as surface
figure('Position', [(ScrSz(3)/2)-700, ScrSz(4)/2-300, 1400, 400]);
plotProjected(TestImage1,[0,0],WL,Config.Cam1,Config.FgBgMask1);
hold on
plotProjected(TestImage2,[0,0],WL,Config.Cam2,Config.FgBgMask2);

% overlay surveyed waters edge
hold on
SurveyH = plot([MouthWE.Easting;LagoonWE.Easting], ...
               [MouthWE.Northing;LagoonWE.Northing], 'c-');
hold off

% calculate offsets along transects and add them and WetBdy to plot
WetBdy = [WetBdy1; ...
          nan(1,2); ...
          WetBdy2];
Transects = m_shaperead('100mTransects_NZTM');
Transects = Transects.ncst(23:39);
Transects = cellfun(@flipud, Transects, 'UniformOutput', false);
hold on
[Offsets, OffsetsH] = measureOffsets(WetBdy,Transects,true);
hold off

% Tidy up the plot for export
view(45,90)
xlim([1622800,1624300])
ylim([5248600,5250200])
set(gca,'Position',[-0.6 -2.1 2.2 5])
axis off
legend([SurveyH;OffsetsH([1,2,4])], ...
       {'Surveyed waters edge', ...
        'Image analysis waters edge', ...
        'Measurement transects', ...
        'Measured offset'}, ...
       'Position',[0.81 0.06 0.17 0.28], ...
       'FontSize',11)

% export_fig 'outputs\TestImage1.pdf' -pdf

%% Project image 2

% load test image
TestImage1 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui1_15-08-26_14-29-58-86.jpg');
TestImage2 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui2_15-08-26_14-15-00-30.jpg');

% WL at time of image, corrected to LVD
WL = 2.411 + Config.LagoonOffset;

% Wateredge calibration, digitised from SFM orthophoto
WatersEdge = m_shaperead('E:\Hurunui\GIS\Survey\2015-08-26 minor error\WetAreaPolygon');
WatersEdge = WatersEdge.ncst{1,1};

% Ground control points
GCPS = m_shaperead('E:\Hurunui\GIS\Survey\2015-08-26 minor error\GCPs');
GCPS = cell2mat(GCPS.ncst);

% Measure pole twist
Twist = MeasureTwist1(TestImage1,true);

% find wet edges
[WetMask1, WetBdyPx1] = WetDry2(TestImage1, Config.FgBgMask1, [1628, 1013], Twist, true);
[WetMask2, WetBdyPx2] = WetDry2(TestImage2, Config.FgBgMask2, [1334, 950], [Twist(1),-Twist(2)], false);

% convert WetBdys to easting northing
[BdyEasting1, BdyNorthing1] = ...
    ProjectToMap(Config.Cam1, WL, Twist, WetBdyPx1(:,1), WetBdyPx1(:,2));
[BdyEasting2, BdyNorthing2] = ...
    ProjectToMap(Config.Cam2, WL, [Twist(1),-Twist(2)], WetBdyPx2(:,1), WetBdyPx2(:,2));
WetBdy1 = [BdyEasting1, BdyNorthing1];
WetBdy2 = [BdyEasting2, BdyNorthing2];

% Remove backshore part of WetBdy polygon to leave polyline along barrier
WetBdy1 = cleanWetBdy(WetBdy1);
WetBdy2 = cleanWetBdy(WetBdy2);

% display projected image as surface
figure('Position', [(ScrSz(3)/2)-700, ScrSz(4)/2-300, 1400, 400]);
plotProjected(TestImage1,Twist,WL,Config.Cam1,Config.FgBgMask1);
hold on
plotProjected(TestImage2,[Twist(1),-Twist(2)],WL,Config.Cam2,Config.FgBgMask2);
hold off

% overlay SFM waters edge and Ground Control
hold on
SurveyH = plot(WatersEdge(:,1), WatersEdge(:,2), 'b-');
GcpsH = plot(GCPS(:,1), GCPS(:,2), 'cx');
hold off

% calculate offsets along transects and add them and WetBdy to plot
WetBdy = [WetBdy1; ...
          nan(1,2); ...
          WetBdy2];

Transects = m_shaperead('100mTransects_NZTM');
Transects = Transects.ncst(23:39);
Transects = cellfun(@flipud, Transects, 'UniformOutput', false);
hold on
[Offsets, OffsetsH] = measureOffsets(WetBdy,Transects,true);
hold off

% Tidy up the plot for export
view(45,90)
xlim([1622800,1624300])
ylim([5248600,5250200])
set(gca,'Position',[-0.6 -2.1 2.2 5])
axis off
legend([SurveyH;OffsetsH([1,2,4])], ...
       {'Surveyed waters edge', ...
        'Image analysis waters edge', ...
        'Measurement transects', ...
        'Measured offset'}, ...
       'Position',[0.81 0.06 0.17 0.28], ...
       'FontSize',11)
