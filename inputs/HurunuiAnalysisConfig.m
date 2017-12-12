function Config = HurunuiAnalysisConfig()
%HURUNUIANALYSISCONFIG Setup ready to run analysis scripts
%   Config = HURUNUIANALYSISCONFIG

%% Data file locations

% Main data drive/folder
%Config.DataFolder = '\\engcad4\GISdump\Richard\';
%Config.DataFolder = 'E:\Hurunui';
Config.DataFolder = fullfile(getenv('USERPROFILE'),'OneDrive - NIWA',...
                             'Hapua\Hurunui');

% River flow timeseries from ECan web services
Config.HurunuiSH1EcanData = 'http://data.ecan.govt.nz/data/79/Water/River%20stage%20flow%20data%20for%20individual%20site/CSV?SiteNo=65101&Period=All&StageFlow=River%20Flow';

% Lagoon level timeseries exported from NEON
Config.LagoonWLFile = '\TimeseriesData\NIWA_levelData.csv';

% Lagoon hypsometry
Config.HypsometryFile = '\TimeseriesData\LagoonHypsometry.xlsx';

% Sumner sea level
Config.SumnerFile = '\TimeseriesData\SumnerSeaLevel.csv';
Config.SumnerBaroFile = '\TimeseriesData\SumnerBaro.csv';

% Hurunui air pressure
Config.HurunuiTidalConstFile = '\TimeseriesData\Hurunui.cns';
Config.HurunuiBaroFile = '\TimeseriesData\CheviotPressureCliFlow.txt';

% Wave data exported from Tideda
Config.WaveCSV1 = '\TimeseriesData\WaveData1.csv';
Config.WaveCSV2 = '\TimeseriesData\WaveData2.csv';

% Photo directory containing all images
Config.PhotoFolder = '\PhotoRecord\ImageStore';

%% Timing and datum corrections and adjustments

% Vertical offsets
Config.LagoonOffset = -1.1; %conversion from local gauge datum to LVD-37
Config.SumnerOffset = 0;
%SumnerOffset = -9.043; % conversion from CDB to LVD-37

% Time Offsets
Config.TimeZone = 12;
Config.Sumner2Hurunui = 19/60/24; % Hurunui tides roughly 19 minutes after Sumner
Config.SH1_to_lagoon = hours(2.6); % Mandamus to SH1 = ~8 hours (56.5km) SH1 to lagoon = 18.4km therefore 2.6hrs\

%% Image analysis parameters

% Photo quality thresholds
Config.SharpThresh = 2.5;
Config.ContrastThresh = 20;
Config.BrightThresh = 50;

% Foreground/BackgroundMasks
load('FgBgMask1.mat');
load('FgBgMask2.mat');
Config.FgBgMask1 = FgBgMask1;
Config.FgBgMask2 = FgBgMask2;
clear FgBgMask1 FgBgMask2

% Seed pixels for water ID
Config.SeedPixel1 = [1628, 1013];
Config.SeedPixel2 = [1334, 950];

% Set standard WL for selection of consistent images
Config.StandardWL = 1.5;

%% Camera distortion and projection settings
Config.Cam1.Resolution = [2592,1944];      % Image size [across,down] (pixels)
Config.Cam1.Bearing    = 192.5;            % Bearing of center of image (degrees)
Config.Cam1.Pitch      = -21.4;            % Altitude angle of image center (usually negative as this indicates the image is looking down of horizontal)
Config.Cam1.Roll       = +2.03;            % Roll angle of camera (clockwise = positive)
Config.Cam1.ViewWidth  = 63.0;             % width of field of view (degrees)
Config.Cam1.Height     = 7.55 + 26.476;    % elevation of camera
Config.Cam1.Easting    = 1623524.9;        % Easting of camera
Config.Cam1.Northing   = 5249500.7;        % Northing of camera
Config.Cam1.k          = [0.15,0.08];%[+0.240,0];           % k value for barrel distortion correction as used for lensdistort

Config.Cam2.Resolution = Config.Cam1.Resolution;
Config.Cam2.Bearing    = 062.5;
Config.Cam2.Pitch      = -23.50;
Config.Cam2.Roll       = +0.80;
Config.Cam2.ViewWidth  = 67;
Config.Cam2.Height     = Config.Cam1.Height;
Config.Cam2.Easting    = Config.Cam1.Easting;
Config.Cam2.Northing   = Config.Cam1.Northing;
Config.Cam2.k          = [0.1,0.21];%[+0.325,0];

%% Twist search settings

% Edge positions in pixels corresponding to Twist = [0,0,0] 
% note: these are based on Hurunui1_15-10-07_15-28-48-75.jpg
Config.Cam1.H_CalibEdge = 2329;
Config.Cam1.V_CalibEdge = 153;
Config.Cam1.V2_CalibEdge = 113;

% horizontal (cliff) search params
Config.Cam1.H_XPixelMin = 2000; % horizontal search range for cliff edge [px]
Config.Cam1.H_XPixelMax = 2450;
Config.Cam1.H_YPixel = 550;     % vert coord of horiz search line for cliff edge [px]
Config.Cam1.H_YBand = 20;        % search band thickness for cliff edge search [px]
Config.Cam1.H_dSVthresh = 2e-4;  % initial dHSV threshold
Config.Cam1.H_FilterRadius = 5;
Config.Cam1.H_SearchDirection = 1; % 1=search L to R, 0=no search direction, -1=search R to L
Config.Cam1.H_FineSearchMax = 5;% secondary/fine search parameters
Config.Cam1.H_ApplyTwist = true;

% RH vertical (horizon) search parameters
Config.Cam1.V_XPixel     = 2471;
Config.Cam1.V_YPixelMin  = 100;
Config.Cam1.V_YPixelMax  = 200;
Config.Cam1.V_XBand      = 20;
Config.Cam1.V_FilterRadius = 5;
Config.Cam1.V_ApplyTwist = true;

% LH vertical (horizon) search parameters
Config.Cam1.V2_XPixel     = 300;
Config.Cam1.V2_YPixelMin  = 85;
Config.Cam1.V2_YPixelMax  = 145;
Config.Cam1.V2_XBand      = 20;
Config.Cam1.V2_FilterRadius = 5;
Config.Cam1.V2_ApplyTwist = false;

% Edge positions in pixels corresponding to Twist = [0,0,0] 
% note: these are based on Hurunui2_15-10-07_15-28-52-74.jpg
Config.Cam2.H_CalibEdge = 1074;
Config.Cam2.V_CalibEdge = 1244; %1273; %140;
Config.Cam2.V2_CalibEdge = 1273; %1268; %46;

% horizontal (fence) search params
Config.Cam2.H_XPixelMin = 600; % horizontal search range for cliff edge [px]
Config.Cam2.H_XPixelMax = 1100;
Config.Cam2.H_YPixel = 1340;     % vert coord of horiz search line for cliff edge [px]
Config.Cam2.H_YBand = 20;        % search band thickness for cliff edge search [px]
Config.Cam2.H_dSVthresh = 2e-3;  % initial dHSV threshold
Config.Cam2.H_FilterRadius = 20;
Config.Cam2.H_SearchDirection = 0; % 1=search L to R, 0=no search direction, -1=search R to L
Config.Cam2.H_FineSearchMax = +5;% secondary/fine search parameters
Config.Cam2.H_ApplyTwist = true;

% RH vertical (horizon) search parameters
Config.Cam2.V_XPixel     = 1053; %1750; %2310;
Config.Cam2.V_YPixelMin  = 1200; %1220; %100;
Config.Cam2.V_YPixelMax  = 1300; %1340; %170;
Config.Cam2.V_XBand      = 5;    %20;
Config.Cam2.V_FilterRadius = 30;        %5
Config.Cam2.V_ApplyTwist = true;

% LH vertical (horizon) search parameters
Config.Cam2.V2_XPixel     = 1750; %1620; %1300;
Config.Cam2.V2_YPixelMin  = 1220; %1220; %20;
Config.Cam2.V2_YPixelMax  = 1340; %1340; %90;
Config.Cam2.V2_XBand      = 20;
Config.Cam2.V2_FilterRadius = 30;        %5;
Config.Cam2.V2_ApplyTwist = true;

%% Spatial parameters
% Transect lines
TransectShp = '100mTransects_NZTM_clipped';
Transects = m_shaperead(TransectShp);
Config.Transects = cellfun(@flipud, Transects.ncst, ...
                           'UniformOutput', false);
clear TransectShp Transects

Config.ShoreNormalDir = 128; % Shoreline angle - given as direction of a shore normal line towards the coast in degrees

% Shoreline measure line
ShorelineShp = 'AlongshoreMeasure';
Shoreline = m_shaperead(ShorelineShp);
Config.Shoreline = Shoreline.ncst{1,1};
clear ShorelineShp Shoreline

% Beachface slope
Config.Beachslope = 0.13;

% Barrier crest height
Config.CrestHeight = 3.9;
