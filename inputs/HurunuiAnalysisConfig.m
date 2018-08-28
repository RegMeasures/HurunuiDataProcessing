function Config = HurunuiAnalysisConfig()
%HURUNUIANALYSISCONFIG Setup ready to run analysis scripts
%   Config = HURUNUIANALYSISCONFIG

%% Overall settings
Config.StartTime = datetime(2015,7,1);
Config.EndTime = datetime(2017,10,1);

%% Data file locations

% Main data drive/folder
Config.DataFolder = fullfile(getenv('USERPROFILE'),'OneDrive - NIWA',...
                             'Hapua\Hurunui');

% River flow timeseries from ECan web services
Config.HurunuiSH1EcanData = 'http://data.ecan.govt.nz/data/79/Water/River%20stage%20flow%20data%20for%20individual%20site/CSV?SiteNo=65101&Period=All&StageFlow=River%20Flow';

% Lagoon level timeseries from NIWA's Aquarius database
Config.LagoonWLSiteID = 65119;
Config.LagoonWLDataId = 'HG.Master';
Config.AquariusHostURL = 'aquarius.niwa.co.nz';

% Lagoon hypsometry
Config.HypsometryFile = '\TimeseriesData\LagoonHypsometry.xlsx';

% Sumner sea level
Config.SumnerFile = '\TimeseriesData\SumnerSeaLevel.csv';
Config.SumnerBaroFile = '\TimeseriesData\SumnerBaro.csv';

% Hurunui air pressure
Config.HurunuiTidalConstFile = '\TimeseriesData\Hurunui.cns';
Config.HurunuiBaroFile = '\TimeseriesData\CheviotPressureCliFlow.txt';

% Wave buoy data exported from Tideda
Config.WaveCSV1 = '\TimeseriesData\WaveData1.csv';
Config.WaveCSV2 = '\TimeseriesData\WaveData2.csv';

% Wave data from SWAN modelling
Config.WaveModelOutput = '\SWAN\output\TS_hurunui.txt';

% Salinity data folder
Config.SalinityFolder = 'TimeseriesData\SalinityTS';

% Photo directory containing all images
Config.PhotoFolder = '\PhotoRecord\ImageStore';

%% Data corrections and adjustments

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

% Seed pixels for water ID
Config.SeedPixel1 = [1628, 1013];
Config.SeedPixel2 = [1334, 950];

% Set standard WL for selection of consistent images
Config.StandardWL = 1.5;

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

% Barrier crest height range (from/to)
Config.CrestHeight = [3.0, 4.1]; 

%% Parameters for sediment transport and runup equations
Config.Gravity = 9.81;  % m/s^2
Config.Rho = 1025;      % Density of seawater (kg/m^3)
Config.Gamma = 0.5;     % Ratio of water depth at breakpoint to breaking wave height (WaveHeightAtBreaking = Gamma x WaterDepthAtBreakPoint)
Config.K = 0.02;        % Longshore transport coefficient
Config.RhoS = 2650;     % Density of rock (kg/m^3)
Config.VoidRatio = 0.4; % Proportion of volume taken up by voids in beach sediment deposits

%% Key periods for outputs

Config.KeyDates = {'12Oct2015','01Nov2015'; ... % Well connected lagoon - short outlet channel
                   '05Nov2015','29Nov2015'; ... % Perched lagoon with extended outlet - at end of period small seaward truncation of outlet channel
                   '12May2016','15May2016'; ... % Outlet channel migration widening lagoon
                   '13Jul2016','15Jul2016'; ... % Lagoon flood due to small river flood when already perched
                   '18Nov2016','20Nov2016'; ... % Outlet channel migration widening lagoon
                   '19Jan2017','22Jan2017'; ... % River flood lagoon widening
                   '16Feb2017','28Feb2017'; ... % Southwards offset driven by southwards longshore transport - sufficient to cause perched lagoon level
                   '13Jun2017','16Jun2017'; ... % Wave overtopping lagoon narrowing
                   '21Jul2017','23Jul2017'};    % Primary breach (+ some wave overtopping narrowing and some flood widening!)
% Config.KeyDates = {'19Jan2017','22Jan2017'; ... % River flood lagoon widening
%                    '01May2017','10Jun2017'; ... % Migration
%                    '13Jun2017','16Jun2017'; ... % Wave overtopping lagoon narrowing
%                    '21Jul2017','23Jul2017'};    % Primary breach (+ some wave overtopping narrowing and some flood widening!)

Config.KeyDates = datetime(Config.KeyDates,'InputFormat','ddMMMuuuu');
