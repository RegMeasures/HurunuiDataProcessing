% Test/calibrate image projection and wet edge ID against surveyed WE

addpath('functions')
addpath('data')

%% Specify camera settings
load('CamSettings')

% Cam1.Resolution = [2592,1944];      % Image size [across,down] (pixels)
% Cam1.Bearing    = 192.5;            % Bearing of center of image (degrees)
% Cam1.Pitch      = -21.4;            % Altitude angle of image center (usually negative as this indicates the image is looking down of horizontal)
% Cam1.Roll       = +2.03;            % Roll angle of camera (clockwise = positive)
% Cam1.ViewWidth  = 63.0;             % width of field of view (degrees)
% Cam1.Height     = 7.55 + 26.476;    % elevation of camera
% Cam1.Easting    = 1623524.9;        % Easting of camera
% Cam1.Northing   = 5249500.7;        % Northing of camera
% Cam1.k          = +0.240;           % k value for barrel distortion correction as used for lensdistort
% 
% Cam2.Resolution = Cam1.Resolution;
% Cam2.Bearing    = 062.5;
% Cam2.Pitch      = -23.40;
% Cam2.Roll       = +0.80;
% Cam2.ViewWidth  = 67;
% Cam2.Height     = Cam1.Height;
% Cam2.Easting    = Cam1.Easting;
% Cam2.Northing   = Cam1.Northing;
% Cam2.k          = +0.325;

load('FgBgMask1.mat')
load('FgBgMask2.mat')

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
[WetMask1, WetBdy1] = WetDry2(TestImage1, FgBgMask1, [1628, 1013], [], false);
[WetMask2, WetBdy2] = WetDry2(TestImage2, FgBgMask2, [1334, 950], [], false);

% convert WetBdys to easting northing
[BdyEasting1, BdyNorthing1] = ...
    ProjectToMap(Cam1, WL, [], WetBdy1(:,1), WetBdy1(:,2));
[BdyEasting2, BdyNorthing2] = ...
    ProjectToMap(Cam2, WL, [], WetBdy2(:,1), WetBdy2(:,2));

% display projected image as surface
plotProjected(TestImage1,[0,0],WL,Cam1,FgBgMask1);
hold on
plotProjected(TestImage2,[0,0],WL,Cam2,FgBgMask2);

% overlay surveyed waters edge
hold on
plot(LagoonWE.Easting, LagoonWE.Northing, 'r-x')
plot(MouthWE.Easting, MouthWE.Northing, 'g-x')
hold off

% add wet bdy to map
hold on
plot(BdyEasting1,BdyNorthing1,'k-')
plot(BdyEasting2,BdyNorthing2,'k-')
hold off

% zoom to survey data
% xlim([min(SurveyPts.Easting)-50, max(SurveyPts.Easting+50)])
% ylim([min(SurveyPts.Northing)-20,max(SurveyPts.Northing+20)])

% zoom to BdyData
% xlim([min(BdyEasting1)-50, max(BdyEasting1+50)])
% ylim([min(BdyNorthing1)-20,max(BdyNorthing1+20)])


%% Project image 2

% load test image
TestImage1 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui1_15-08-26_14-29-58-86.jpg');
TestImage2 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui2_15-08-26_14-15-00-30.jpg');

% WL at time of image, corrected to LVD
WL = 2.411 - 1.1;

% Wateredge calibration, digitised from SFM orthophoto
WatersEdge = m_shaperead('E:\Hurunui\GIS\Survey\2015-08-26 minor error\WetAreaPolygon');
WatersEdge = WatersEdge.ncst{1,1};

% Ground control points
GCPS = m_shaperead('E:\Hurunui\GIS\Survey\2015-08-26 minor error\GCPs');
GCPS = cell2mat(GCPS.ncst);

% Measure pole twist
Twist = MeasureTwist1(TestImage1);

% find wet edges
[WetMask1, WetBdy1] = WetDry2(TestImage1, FgBgMask1, [1628, 1013], Twist, true);
[WetMask2, WetBdy2] = WetDry2(TestImage2, FgBgMask2, [1334, 950], [Twist(1),-Twist(2)], false);

% convert WetBdys to easting northing
[BdyEasting1, BdyNorthing1] = ...
    ProjectToMap(Cam1, WL, [Twist], WetBdy1(:,1), WetBdy1(:,2));
[BdyEasting2, BdyNorthing2] = ...
    ProjectToMap(Cam2, WL, [Twist(1),-Twist(2)], WetBdy2(:,1), WetBdy2(:,2));

% display projected image as surface
figure
plotProjected(TestImage1,Twist,WL,Cam1,FgBgMask1);
hold on
plotProjected(TestImage2,[Twist(1),-Twist(2)],WL,Cam2,FgBgMask2);

% overlay SFM waters edge and Ground Control
hold on
plot(WatersEdge(:,1), WatersEdge(:,2), 'b-')
plot(GCPS(:,1), GCPS(:,2), 'rx')
hold off

% add wet bdy to map
hold on
plot(BdyEasting1,BdyNorthing1,'k-')
plot(BdyEasting2,BdyNorthing2,'k-')
hold off

% export wet bdy as shapefile
%shapewrite