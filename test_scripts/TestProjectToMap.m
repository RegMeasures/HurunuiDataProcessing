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

% run the test and plot all figures
testProjectToMapLooper(Config,TestImage1,TestImage2,WL, ...
                       [MouthWE.Easting, MouthWE.Northing; ...
                        LagoonWE.Easting, LagoonWE.Northing])

%% Project image 2

% load test image
TestImage1 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui1_15-08-26_14-29-58-86.jpg');
TestImage2 = imread('E:\Hurunui\PhotoRecord\HighRes\Hurunui2_15-08-26_14-15-00-30.jpg');

% WL at time of image, corrected to LVD
WL = 2.411 + Config.LagoonOffset;

% Wateredge calibration, digitised from SFM orthophoto
WatersEdge = m_shaperead('E:\Hurunui\GIS\Survey\2015-08-26 minor error\WetAreaPolygon');
WatersEdge = WatersEdge.ncst{1,1};

% run the test and plot all figures
testProjectToMapLooper(Config, TestImage1, TestImage2, WL, WatersEdge)

%% Project image Test 3

% load test image
% TestImage1 = imread('H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2015\10\Hurunui1\Hurunui1_15-10-07_15-28-48-75.jpg');
% TestImage2 = imread('H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2015\10\Hurunui2\Hurunui2_15-10-07_15-28-52-74.jpg');
TestImage1 = imread('Hurunui1_17-07-26_13-00-00-00.jpg');
TestImage2 = imread('Hurunui2_17-07-26_13-00-00-00.jpg');

% WL at time of image, corrected to LVD
WL = 2.411 + Config.LagoonOffset;

% Wateredge calibration from RTK survey
WatersEdge = m_shaperead('E:\Hurunui\GIS\Survey\2017-07-26 bathy&RTK\2017-07-26_Survey_WatersEdge');
WatersEdge = cell2mat(WatersEdge.ncst);

% run the test and plot all figures
testProjectToMapLooper(Config,TestImage1,TestImage2,WL, ...
                       WatersEdge)
