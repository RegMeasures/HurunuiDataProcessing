function Config = HurunuiAnalysisConfig()
%HURUNUIANALYSISCONFIG Setup ready to run analysis scripts
%   Config = HurunuiAnalysisConfig

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

% Camera distortion and projection settings
load('CamSettings')
Config.Cam1 = Cam1;
Config.Cam2 = Cam2;
clear Cam1 Cam2

% Seed pixels for water ID
Config.SeedPixel1 = [1628, 1013];
Config.SeedPixel2 = [1334, 950];

% Set standard WL for selection of consistent images
Config.StandardWL = 1.5;

%% Spatial parameters
% Transect lines
TransectShp = '100mTransects_NZTM';
Transects = m_shaperead(TransectShp);
Config.Transects = cellfun(@flipud, Transects.ncst(23:39), ...
                           'UniformOutput', false);
clear TransectShp Transects

Config.OnshoreDir = 308; % Shoreline angle - given as direction of a shore normal line towards the coast in degrees