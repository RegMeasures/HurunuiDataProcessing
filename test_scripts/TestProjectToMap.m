% Test/calibrate image projection and wet edge ID against surveyed WE

%% Setup
% Add required directories (and subdirectories)
addpath(genpath('..\functions'))
addpath(genpath('..\inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% Remove masks for test purposes
Config.FgBgMask1 = false(size(Config.FgBgMask1));
Config.FgBgMask2 = false(size(Config.FgBgMask2));

% get screensize for plot setups
ScrSz = get(groot, 'ScreenSize');

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
TestImage1 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2015\10\Hurunui1\Hurunui1_15-10-06_15-28-21-50.jpg'));
TestImage2 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2015\10\Hurunui2\Hurunui2_15-10-06_13-28-25-74.jpg'));

% load surveyed waters edge
SurveyPts = readRtkSurveyCsv(fullfile(Config.DataFolder,'Survey\2015-10-06 barrier RTK\Survey_Pts_Beach_Barrier_Oct15.csv'));
LagoonWE = SurveyPts(3:108,:);
MouthWE = SurveyPts(117:131,:);
WL = mean(LagoonWE.Elevation);

% run the test and plot all figures
[Twist,WetBdy,Offsets] = ...
    testProjectToMapLooper(Config,TestImage1,TestImage2,WL, ...
                           [MouthWE.Easting, MouthWE.Northing; ...
                            LagoonWE.Easting, LagoonWE.Northing]);
                        
% write projected outputs to GIS
imageAnalysis2GIS(Config, '..\outputs\15-10-06_1530', ...
                  TestImage1, TestImage2, WL, Twist, WetBdy, Offsets)

%% Project image 2

% load test image
TestImage1 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2015\08\Hurunui1\Hurunui1_15-08-26_14-29-58-86.jpg'));
TestImage2 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2015\08\Hurunui2\Hurunui2_15-08-26_14-15-00-30.jpg'));

% WL at time of image, corrected to LVD
WL = 2.411 + Config.LagoonOffset;

% Wateredge calibration, digitised from SFM orthophoto
WatersEdge = m_shaperead(fullfile(Config.DataFolder,'GIS\Survey\2015-08-26 minor error\WetAreaPolygon'));
WatersEdge = WatersEdge.ncst{1,1};

% run the test and plot all figures
testProjectToMapLooper(Config, TestImage1, TestImage2, WL, WatersEdge)

% write projected outputs to GIS
imageAnalysis2GIS(Config, '..\outputs\15-08-26_1430', ...
                  TestImage1, TestImage2, WL, Twist, WetBdy, Offsets)

%% Project image 3

% load test image
TestImage1 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2017\05\Hurunui1\Hurunui1_17-05-24_12-45-47-15.jpg'));
TestImage2 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2017\05\Hurunui2\Hurunui2_17-05-24_12-45-00-62.jpg'));

% WL at time of image, corrected to LVD
WL = 2.512 + Config.LagoonOffset;

% Wateredge calibration, digitised from SFM orthophoto
WatersEdge = m_shaperead(fullfile(Config.DataFolder,'\GIS\Survey\2017-05-24 barrier RTK\WatersEdge_2017-05-24'));
WatersEdge = [cell2mat(WatersEdge.ncst(1:77,1)); nan(1,2); cell2mat(WatersEdge.ncst(79:end-2,1))];

% run the test and plot all figures
testProjectToMapLooper(Config, TestImage1, TestImage2, WL, WatersEdge)

% write projected outputs to GIS
imageAnalysis2GIS(Config, '..\outputs\17-05-24_1245', ...
                  TestImage1, TestImage2, WL, Twist, WetBdy, Offsets)

%% Project image 4

% load test image
TestImage1 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2017\07\Hurunui1\Hurunui1_17-07-26_13-32-11-53.jpg'));
TestImage2 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2017\07\Hurunui2\Hurunui2_17-07-26_13-32-03-49.jpg'));

% WL at time of image, corrected to LVD
WL = 1.900 + Config.LagoonOffset;

% Wateredge calibration from RTK survey
WatersEdge = m_shaperead(fullfile(Config.DataFolder,'GIS\Survey\2017-07-26 bathy&RTK\2017-07-26_Survey_WatersEdge'));
WatersEdge = cell2mat(WatersEdge.ncst);

% run the test and plot all figures
Twist = testProjectToMapLooper(Config,TestImage1, TestImage2, WL, WatersEdge);

% write projected outputs to GIS
imageAnalysis2GIS(Config, '..\outputs\17-07-26_0915', ...
                  TestImage1, TestImage2, WL, Twist, WetBdy, Offsets)
                   
%% Buzz saw space-for-time substituion example
% load test image
TestImage1 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2016\12\Hurunui1\Hurunui1_16-12-13_08-36-13-03.jpg'));
TestImage2 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2016\12\Hurunui2\Hurunui2_16-12-13_08-35-50-93.jpg'));

% WL at time of image, corrected to LVD
WL = 2.354 + Config.LagoonOffset;

% run the test and plot all figures
testProjectToMapLooper(Config,TestImage1,TestImage2,WL)
