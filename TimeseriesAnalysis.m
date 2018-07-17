%% Analyse Hurunui Hapua monitoring timeseries data

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% Other fixed parameters
Gravity = 9.81;

%% Load Data and apply datum corrections etc.

% Load Hurunui at SH1 data from web :-)
HurunuiCSV = urlread(Config.HurunuiSH1EcanData);
HurCellArray = textscan(HurunuiCSV,'%*d %s %f',...
                      'delimiter',',',...
                      'headerlines',1);
RiverTS.DateTime = HurCellArray{1,1};
RiverTS.DateTime = strrep(RiverTS.DateTime,'a.m.','AM');
RiverTS.DateTime = strrep(RiverTS.DateTime,'p.m.','PM');
RiverTS.DateTime = datetime(RiverTS.DateTime,...
                               'format','dd/MM/yyyy hh:mm:ss a');
RiverTS.DateTime.Format = 'dd/MM/yyyy HH:mm';
RiverTS.Flow = HurCellArray{1,2};
RiverTS = struct2table(RiverTS);
clear HurunuiCSV HurCellArray

% Apply time delay to account for travel time from SH1 to coast
RiverTS.DateTime = RiverTS.DateTime + Config.SH1_to_lagoon;

% Load lagoon water level data
LagoonTS = readtable(fullfile(Config.DataFolder,Config.LagoonWLFile), ...
                     'Delimiter', ',', ...
                     'HeaderLines', 1, ...
                     'ReadVariableNames', false, ...
                     'Format', '%q %q %f');
LagoonTS.Properties.VariableNames = {'Date','Time','WL'};

% convert WL to metres
LagoonTS.WL = LagoonTS.WL / 1000; 

% apply datum correction
LagoonTS.WL = LagoonTS.WL + Config.LagoonOffset; 

% Convert Date and Time cols to datenum
LagoonTS.DateTime = datetime(strcat(LagoonTS.Date,LagoonTS.Time), ...
                             'InputFormat', 'dd/MM/yyyyHH:mm:ss', ...
                             'Format', 'dd/MM/yyyy HH:mm');
LagoonTS.Date = []; % Remove date col as no longer needed
LagoonTS.Time = []; % Remove Time col as no longer needed
LagoonTS = [LagoonTS(:,2),LagoonTS(:,1)]; % re-order columns
LagoonTS = flipud(LagoonTS); % reverse row order (so time increases)

% Load Lagoon Hypsometry
Hypsometry = readtable(fullfile(Config.DataFolder,Config.HypsometryFile),...
                       'ReadVariableNames',true);
                   
% Load Sumner sea level data
% (exported from Tideda as 15 minute averaged data, synchronised to interval)
SumnerTS = readtable(fullfile(Config.DataFolder,Config.SumnerFile),...
                     'Delimiter',',',...
                     'HeaderLines',2,...
                     'ReadVariableNames',false);
SumnerTS.Properties.VariableNames = {'DateTime', 'WL'};
SumnerTS.DateTime = datetime(SumnerTS.DateTime, ...
                             'InputFormat','dd/MM/yyyy HH:mm:ss', ...
                             'Format', 'dd/MM/yyyy HH:mm');
SumnerTS.DateTime = SumnerTS.DateTime - minutes(7.5); % adjustment required to center time in averaging interval

% apply datum correction
SumnerTS.WL = SumnerTS.WL + Config.SumnerOffset; 

% Load Sumner barometric data
% hourly instantaneous values
SumnerBaroTS = readtable(fullfile(Config.DataFolder,Config.SumnerBaroFile),...
                     'Delimiter',',',...
                     'HeaderLines',2,...
                     'Format','%{dd/MM/yyyy HH:mm:ss}D %f',...
                     'ReadVariableNames',false);
SumnerBaroTS.Properties.VariableNames = {'DateTime', 'Baro'};
SumnerBaroTS.DateTime.Format = 'dd/MM/yyyy HH:mm';

% Load Hurunui barometric pressure data
% use cheviot for now from CliFlow (site 31832)
% have manually deleted footer rows to ease import
HurunuiBaroTS = readtable(fullfile(Config.DataFolder,Config.HurunuiBaroFile),...
                     'Delimiter',',',...
                     'HeaderLines',9,...
                     'ReadVariableNames',false);
HurunuiBaroTS(:,[1,4:7]) = [];
HurunuiBaroTS.Properties.VariableNames = {'DateTime', 'Baro'};
HurunuiBaroTS.DateTime = datetime(HurunuiBaroTS.DateTime, ...
                                  'format','yyyyMMdd:HHmm');

% % Read buoy wavedata
% - tideda exports for same time period and synchronised to 30min intervals
%   fill in na lines to correct number of data values (e.g. na,na,na,etc)
BuoyTS = readtable(fullfile(Config.DataFolder,Config.WaveCSV1),...
                   'Delimiter',',',...
                   'HeaderLines',1,...
                   'ReadVariableNames',true ,...
                   'Format', '%q %f %f %f %f %f %f %f %f %f %f', ...
                   'TreatAsEmpty', 'na');
BuoyTS.Date = datetime(BuoyTS.Date,'format','dd/MM/yyyy HH:mm:ss');

BuoyTS2 = readtable(fullfile(Config.DataFolder,Config.WaveCSV2),...
                    'Delimiter',',',...
                    'HeaderLines',1,...
                    'ReadVariableNames',true ,...
                    'Format', '%q %f %f %f %f %f %f', ...
                    'TreatAsEmpty', 'na');
BuoyTS2.Date = datetime(BuoyTS2.Date,'format','dd/MM/yyyy HH:mm:ss');

% Combine wavedata into 1 table
BuoyTS = [BuoyTS, BuoyTS2(:,2:end)]; % if this line doesn't work check tideda exports for same time period and synchronised to 30min intervals
clear BuoyTS2

% Read model wave data
WaveModTS = readtable(fullfile(Config.DataFolder,Config.WaveModelOutput), ...
                      'HeaderLines',27,...
                      'ReadVariableNames',false ,...
                      'Format', '%f%d%d%d%d%d%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
WaveModTS.Var2 = datetime([WaveModTS{:,2:6}, zeros(height(WaveModTS),1)]);
WaveModTS(:,[1,3:6,24:25]) = [];
WaveModTS.Properties.VariableNames = {'DateTime', ...
                                      'Hsig', ...
                                      'Tm01', ...
                                      'Tm02', ...
                                      'RTpeak', ...
                                      'Dir', ...
                                      'Dspr', ...
                                      'PkDir', ...
                                      'XWindv', ...
                                      'YWindv', ...
                                      'Ubot', ...
                                      'Urms', ...
                                      'Wlen', ...
                                      'Depth', ...
                                      'XTransp', ...
                                      'YTransp', ...
                                      'XWForce', ...
                                      'YWForce'};

% Read salinity logger data
SalinityFiles = rdir(fullfile(Config.DataFolder, ...
                              Config.SalinityFolder, '*.csv'), ...
                     '', true);
SalinityTS.DateTime = NaT(0,0);
SalinityTS.Temp = nan(0,0);
SalinityTS.Cond = nan(0,0);
for FileNo = 1:size(SalinityFiles,1)
    LoggerData = readtable(fullfile(Config.DataFolder, ...
                                    Config.SalinityFolder, ...
                                    SalinityFiles(FileNo).name), ...
                           'HeaderLines', 15, ...
                           'Delimiter', ',', ...
                           'ReadVariableNames', true);
    LoggerData.DateTime = datetime(strcat(LoggerData.Date,LoggerData.Time), ...
                                   'InputFormat', 'yyyy/MM/ddHH:mm:ss');
    SalinityTS.DateTime = [SalinityTS.DateTime; ...
                           LoggerData.DateTime(1) - seconds(1); ...
                           LoggerData.DateTime; ...
                           LoggerData.DateTime(end) + seconds(1)];
    SalinityTS.Temp = [SalinityTS.Temp; nan; LoggerData.TEMPERATURE; nan];
    SalinityTS.Cond = [SalinityTS.Cond; nan; LoggerData.CONDUCTIVITY; nan];
end
SalinityTS = struct2table(SalinityTS);
SalinityTS = sortrows(SalinityTS,1);
SalinityTS.SP = gsw_SP_from_C(SalinityTS.Cond,SalinityTS.Temp,0);
clear LoggerData LoggerInterval FileNo
%% Data QA

% Water Level Timeseries
DataOk = true(size(LagoonTS,1),1);
DataOk(LagoonTS.WL>3.7) = false;
DataOk(LagoonTS.WL<-0.1) = false;
DataOk(LagoonTS.DateTime < ...
   datetime('8/6/2015 15:00', 'InputFormat', 'dd/MM/yyyy HH:mm')) = false;
LagoonTS = LagoonTS(DataOk,:);
figure
plot(LagoonTS.DateTime,LagoonTS.WL)
ylabel('Measured Lagoon Water Level [m-LVD]')

% Inflow TS
figure
plot(RiverTS.DateTime,RiverTS.Flow);
ylabel('Measured Hurunui Flow [m^3/s]')

% Sumner sea level
% QualityCheck
DataOk = true(size(SumnerTS,1),1);
DataOk(SumnerTS.WL > +3) = false;
DataOk(SumnerTS.WL < -3) = false;
WLchange = [0;(SumnerTS.WL(2:end)-SumnerTS.WL(1:end-1));0];
DataOk(WLchange(1:end-1) > 0.5 & WLchange(2:end) < -0.5|...
      WLchange(1:end-1) < -0.5 & WLchange(2:end) > 0.5) = false;
% check range to identify gaps with ~constant values
DataOk(movmax(SumnerTS.WL,[48,0])-movmin(SumnerTS.WL,[48,0]) < 0.3) = false; 
DataOk(movmax(SumnerTS.WL,[0,48])-movmin(SumnerTS.WL,[0,48]) < 0.3) = false;
SumnerTS = SumnerTS(DataOk,:);
% Plot
figure
plot(SumnerTS.DateTime,SumnerTS.WL,'b-');
ylabel('Sumner Sea Level [m-LVD]')

% Sumner Baro
% Quality Check
DataOk = true(size(SumnerBaroTS,1),1);
DataOk(SumnerBaroTS.Baro > 1100) = false;
DataOk(SumnerBaroTS.Baro < 900) = false;
SumnerBaroTS = SumnerBaroTS(DataOk,:);
% Plot
figure
plot(SumnerBaroTS.DateTime,SumnerBaroTS.Baro,'b-');
ylabel('Air pressure [hPa]')

% Hurunui Baro
% Quality Check
DataOk = true(size(HurunuiBaroTS,1),1);
DataOk(HurunuiBaroTS.Baro > 1100) = false;
DataOk(HurunuiBaroTS.Baro < 900) = false;
HurunuiBaroTS = HurunuiBaroTS(DataOk,:);
% Plot
hold on
plot(HurunuiBaroTS.DateTime,HurunuiBaroTS.Baro,'r-'); 
legend('Sumner', 'Hurunui')

% Hypsometry
figure
plot(Hypsometry.Volume,Hypsometry.Elevation,'-xb')
xlabel('Lagoon volume [m^3]')
ylabel('Lagoon water surface elevation [m-LVD]')

% Wave data
figure
wind_rose(BuoyTS.DirDeg, BuoyTS.HsM, ...
          'di',0:5, ...
          'dtype', 'meteo', ...
          'lablegend', 'H_s (m)', ...
          'percbg','none', ...
          'quad',0, ...
          'compass',false, ...
          'bgcolor','none', ...
          'cmap',parula, ...
          'lwidth',0.1, ...
          'lstyle','none', ...
          'ci', 0, ...
          'n', 72)
export_fig 'outputs\BuoyWaveRose.png' -transparent -m 5
figure
wind_rose(WaveModTS.Dir, WaveModTS.Hsig, ...
          'di',0:5, ...
          'dtype', 'meteo', ...
          'lablegend', 'H_s (m)', ...
          'percbg','none', ...
          'quad',0, ...
          'compass',false, ...
          'bgcolor','none', ...
          'cmap',parula, ...
          'lwidth',0.1, ...
          'lstyle','none', ...
          'ci', 0, ...
          'n', 72)
hold on
plot([0.37,12.5]*sind(Config.ShoreNormalDir), ...
     [0.37,12.5]*cosd(Config.ShoreNormalDir), ...
     'k-', 'LineWidth', 4)
% quiver(0.37*sind(Config.ShoreNormalDir), ...
%        0.37*cosd(Config.ShoreNormalDir), ...
%        13.5*sind(Config.ShoreNormalDir), ...
%        13.5*cosd(Config.ShoreNormalDir), ...
%        'k-', 'LineWidth', 3, 'MaxHeadSize', 0.25)
%  text(12.5*sind(Config.ShoreNormalDir), ...
%       12.5*cosd(Config.ShoreNormalDir), ...
%       {'Shore normal', 'direction'}, 'Rotation', -(Config.ShoreNormalDir-90))
export_fig 'outputs\ModelWaveRose.png' -transparent -m 5


clear DataOk WLchange

%% Convert Sumner tide to Hurunui

% Calculate observed tidal anomaly at sumner
[HurunuiTide.DateTime, HurunuiTide.Anomaly] = ...
    CalcTidalAnomaly(SumnerTS, SumnerBaroTS);
HurunuiTide = struct2table(HurunuiTide);

% Interpolate anomaly for periods of missing sumner data (e.g. 14/8/2017 - 9/9/2017)
HurunuiTide.Anomaly = fillmissing(HurunuiTide.Anomaly, 'linear');

% Calculate astronomic tide at Hurunui
[HurunuiTide.Astronomic] = ...
    AstronomicTide(fullfile(Config.DataFolder,Config.HurunuiTidalConstFile),...
                   datenum(HurunuiTide.DateTime), Config.TimeZone);

% Put Hurunui barometric pressure reading onto same timeseries
% Compute barometric effect
HurunuiBaroTS.BaroEffect = -100*(HurunuiBaroTS.Baro-1000)/(1025*9.81);
HurunuiTide.BaroEffect = interp1(HurunuiBaroTS.DateTime,HurunuiBaroTS.BaroEffect,HurunuiTide.DateTime);

% Calculate Hurunui Tide accounting for anomaly and barometric effect
HurunuiTide.Final = HurunuiTide.Astronomic + ...
                    HurunuiTide.BaroEffect + ...
                    HurunuiTide.Anomaly;

figure
plot(SumnerTS.DateTime, SumnerTS.WL,'r')
hold on
plot(HurunuiTide.DateTime,HurunuiTide.Final,'b')
legend('Sumner observed','Hurunui calculated')
ylabel('Sea level [mLVD]')

%% Calculate wave parameters

% Offshore wave angle relative to beach
BuoyTS.Angle = angleDiff(deg2rad(Config.ShoreNormalDir), deg2rad(BuoyTS.DirDeg));
BuoyTS.OnshoreWaves = BuoyTS.Angle>-pi/2 & BuoyTS.Angle<pi/2;
WaveModTS.Angle = angleDiff(deg2rad(Config.ShoreNormalDir), deg2rad(WaveModTS.Dir));
WaveModTS.OnshoreWaves = WaveModTS.Angle>-pi/2 & WaveModTS.Angle<pi/2;

% Long shore transport potential
% Qs = K*H^(12/5)*T(1/5)*(cos(theta))^(6/5)*sin(theta);
% Ashton, Murray (2006) eq5
BuoyTS.LstPot = zeros(size(BuoyTS,1),1);
BuoyTS.LstPot(BuoyTS.OnshoreWaves) = BuoyTS.HsM(BuoyTS.OnshoreWaves).^(12/5) .* ...
                              BuoyTS.TsSec(BuoyTS.OnshoreWaves).^(1/5) .* ...
                              (cos(BuoyTS.Angle(BuoyTS.OnshoreWaves))).^(6/5) .* ...
                              sin (BuoyTS.Angle(BuoyTS.OnshoreWaves));
WaveModTS.LstPot = zeros(height(WaveModTS),1);
WaveModTS.LstPot(WaveModTS.OnshoreWaves) = WaveModTS.Hsig(WaveModTS.OnshoreWaves).^(12/5) .* ...
                                 WaveModTS.Tm01(WaveModTS.OnshoreWaves).^(1/5) .* ...
                                 (cos(WaveModTS.Angle(WaveModTS.OnshoreWaves))).^(6/5) .* ...
                                 sin (WaveModTS.Angle(WaveModTS.OnshoreWaves));
   
% Runup (Stockdon et al 2006)
% first calc deep water wavelength based on linear dispersion relationship
BuoyTS.L0p = (Gravity .* BuoyTS.TpeakSec.^2) ./ (2*pi);
BuoyTS.Runup1 = 1.1 * (0.35 * Config.Beachslope * (BuoyTS.HsM .* BuoyTS.L0p).^0.5 + ...
                       (BuoyTS.HsM .* BuoyTS.L0p * (0.563 * Config.Beachslope^2 + 0.004)).^0.5 / 2);
WaveModTS.L0p = (Gravity .* WaveModTS.Tm01.^2) ./ (2*pi);
WaveModTS.Runup1 = 1.1 * (0.35 * Config.Beachslope * (WaveModTS.Hsig .* WaveModTS.L0p).^0.5 + ...
                       (WaveModTS.Hsig .* WaveModTS.L0p * (0.563 * Config.Beachslope^2 + 0.004)).^0.5 / 2);
                  
% Runup (Poate et al 2016 eq11)
BuoyTS.Runup2 = 0.49 * Config.Beachslope^0.5 * BuoyTS.TzSec .* BuoyTS.HsM;
WaveModTS.Runup2 = 0.49 * Config.Beachslope^0.5 * WaveModTS.Tm01 .* WaveModTS.Hsig;

figure
histogram(WaveModTS.Dir, 'BinEdges', 0:5:360)
hold on 
histogram(BuoyTS.DirDeg, 'BinEdges', 0:5:360)
plot(repmat(Config.ShoreNormalDir,[2,1]),ylim','r--','LineWidth',2)
xlabel('Wave approach direction (degrees)')
legend({'SWAN model at 10m depth', 'Wave buoy', 'Hurunui mouth shore normal direction'})
yticks([])
xticks(0:60:360)

% figure
% histogram(rad2deg(WaveModTS.Angle))
% xlim([-90,90])
% xlabel('Wave approach angle (degrees)')

figure
plot(WaveModTS.DateTime,WaveModTS.LstPot)
hold on
plot(BuoyTS.Date,BuoyTS.LstPot)
ylabel('Longshore transport potential')

figure
histogram(WaveModTS.LstPot)
plot(WaveModTS.DateTime,cumsum(WaveModTS.LstPot))
ylabel('Cumulative longshore transport potential')

figure
subplot(2,1,1)
histogram(WaveModTS.Runup1,'BinWidth',0.1)
xlim([0,5])
ylim([0,20000])
xlabel('Runup Stockdon et al (2006)')
subplot(2,1,2)
histogram(WaveModTS.Runup2,'BinWidth',0.1)
xlim([0,5])
ylim([0,20000])
xlabel('Runup Poate et al (2016)')

%% Interpolate data onto same timesteps
LagoonTS.Qin = interp1(RiverTS.DateTime,...
                       RiverTS.Flow,...
                       LagoonTS.DateTime);
LagoonTS.SeaLevel = interp1(HurunuiTide.DateTime,...
                            HurunuiTide.Final,...
                            LagoonTS.DateTime);
LagoonTS.WaveHs = interp1(WaveModTS.DateTime,...
                          WaveModTS.Hsig,...
                          LagoonTS.DateTime);
LagoonTS.WaveTs = interp1(WaveModTS.DateTime,...
                          WaveModTS.Tm01,...
                          LagoonTS.DateTime);
LagoonTS.WaveAngle = interp1(WaveModTS.DateTime,...
                           WaveModTS.Angle,...
                           LagoonTS.DateTime);
LagoonTS.LstPot = interp1(WaveModTS.DateTime,...
                          WaveModTS.LstPot,...
                          LagoonTS.DateTime);
LagoonTS.Runup1 = interp1(WaveModTS.DateTime,...
                         WaveModTS.Runup1,...
                         LagoonTS.DateTime);
LagoonTS.Runup2 = interp1(WaveModTS.DateTime,...
                          WaveModTS.Runup2,...
                          LagoonTS.DateTime);
LagoonTS.SP = interp1(SalinityTS.DateTime,...
                      SalinityTS.SP,...
                      LagoonTS.DateTime);

figure
plot(LagoonTS.DateTime, LagoonTS{:,{'WL','SeaLevel'}});
datetickzoom('x')
ylabel('Water level [m-LVD]')
legend('Lagoon','Sea')

%% Calculate outflow (assuming static lagoon volume)
[LagoonTS.Qout, LagoonTS.Volume] = HindcastQ(Hypsometry,LagoonTS);

figure
plot(LagoonTS.DateTime,LagoonTS{:,{'Qin','Qout'}});
datetickzoom('x')
ylabel('Flow [m^3/s]')
legend('Inflow','Outflow')

%% Calculate Overwash Potential (Matias et al 2012)
LagoonTS.OP1 = max(LagoonTS.SeaLevel + LagoonTS.Runup1 - Config.CrestHeight, 0);
LagoonTS.OP2 = max(LagoonTS.SeaLevel + LagoonTS.Runup2 - Config.CrestHeight, 0);
% LagoonTS.OP1 = LagoonTS.SeaLevel + LagoonTS.Runup1;
% LagoonTS.OP2 = LagoonTS.SeaLevel + LagoonTS.Runup2;

figure
% plotyy(LagoonTS.DateTime,LagoonTS{:,{'WL','SeaLevel','OP1','OP2'}}, ...
%        LagoonTS.DateTime, LagoonTS.SP);
plot(LagoonTS.DateTime,LagoonTS{:,{'WL','SeaLevel','OP1','OP2'}});
datetickzoom('x')
ylabel('Overtopping potential (m)')
legend('Lagoon level','Sea level','Stockdon et al 2006','Poate et al 2016')

%% Save lagoon TS
writetable(LagoonTS,'outputs\LagoonTS.csv')

DailyLagoonTS = dailyStats(LagoonTS);
writetable(DailyLagoonTS,'outputs\DailyLagoonTS.csv')
