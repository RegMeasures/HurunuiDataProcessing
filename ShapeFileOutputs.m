%% Setup
% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Add Open Earth Matlab Toolbox 
% (only need to do this once per matlab session
addpath ..\OpenEarth\matlab\
oetsettings('quiet')

% Read input parameters
Config = HurunuiAnalysisConfig;

%% Load data and process
% load test image
TestImage1 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2015\10\Hurunui1\Hurunui1_15-10-06_15-28-21-50.jpg'));
TestImage2 = imread(fullfile(Config.DataFolder,Config.PhotoFolder,'2015\10\Hurunui2\Hurunui2_15-10-06_13-28-25-74.jpg'));

% load surveyed waters edge
SurveyPts = readRtkSurveyCsv(fullfile(Config.DataFolder,'Survey\2015-10-06 barrier RTK\Survey_Pts_Beach_Barrier_Oct15.csv'));
LagoonWE = SurveyPts(3:108,:);
MouthWE = SurveyPts(117:131,:);
WL = mean(LagoonWE.Elevation);

% Config.FgBgMask1 = false(size(Config.FgBgMask1));
% Config.FgBgMask2 = false(size(Config.FgBgMask2));
               
% Measure pole twist
Twist = MeasureTwist1(TestImage1,Config.Cam1.k,Config.Cam1.Resolution);

% find wet edges
[WetMask1, WetBdy1] = WetDry2(TestImage1, Config.FgBgMask1, ...
                              Config.SeedPixel1, Twist, false);
[WetMask2, WetBdy2] = WetDry2(TestImage2, Config.FgBgMask2, ...
                              Config.SeedPixel2, [Twist(1),-Twist(2)], ...
                              false);

% convert WetBdys to easting northing
[BdyEasting1, BdyNorthing1] = ...
    ProjectToMap(Config.Cam1, WL, Twist, WetBdy1(:,1), WetBdy1(:,2));
[BdyEasting2, BdyNorthing2] = ...
    ProjectToMap(Config.Cam2, WL, [Twist(1),-Twist(2)], ...
                 WetBdy2(:,1), WetBdy2(:,2));
WetBdy1 = [BdyEasting1, BdyNorthing1];
WetBdy2 = [BdyEasting2, BdyNorthing2];

% Remove backshore part of WetBdy polygon to leave polyline along barrier
WetBdy1 = cleanWetBdy(WetBdy1);
WetBdy2 = cleanWetBdy(WetBdy2);

%% Export to GIS for nice figure production

% Export shapefile
shapewrite('outputs\15-10-06_1530_WetBdy.shp', 'polyline', ...
           {WetBdy1;WetBdy2}, {'CamNo'}, [1;2]);

% display projected image as surface ready to export raster
FigH = figure;
MapAx = plotProjected(TestImage1,Twist,WL,Config.Cam1,...
                      Config.FgBgMask1,[]);
hold(MapAx,'on')
plotProjected(TestImage2,[Twist(1),-Twist(2)],WL,Config.Cam2,...
              Config.FgBgMask2,MapAx);

% save to tiff with location info
plot2GeoRaster('outputs\15-10-06_1530_projected.tif',FigH,MapAx)

          
          
