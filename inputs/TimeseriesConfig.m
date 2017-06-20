function Config = TimeseriesConfig()
% Input parameters for Hurunui TS analysis

%% Data file locations

% Main data drive/folder
Config.DataFolder = 'H:\Hapua\Individual_Hapua\Hurunui';
%Config.DataFolder = '\\engcad4\GISdump\Richard\';
%Config.DataFolder = 'F:\Hurunui';

% River flow timeseries exported from tideda
Config.HurunuiSH1File = '\TimeseriesData\HurunuiSH1Flow.csv';
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

%% Corrections and adjustments

% Vertical offsets
Config.LagoonOffset = -1.1; %conversion from local gauge datum to LVD-37
Config.SumnerOffset = 0;
%SumnerOffset = -9.043; % conversion from CDB to LVD-37

% Time Offsets
Config.TimeZone = 12;
Config.Sumner2Hurunui = 19/60/24; % Hurunui tides roughly 19 minutes after Sumner
Config.SH1_to_lagoon = 2.6/24; % Mandamus to SH1 = ~8 hours (56.5km) SH1 to lagoon = 18.4km therefore 2.6hrs\

%% Other parameters
Config.OnshoreDir = 308; % Shoreline angle - given as direction of a shore normal line towards the coast in degrees