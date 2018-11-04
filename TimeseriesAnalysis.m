%% Analyse Hurunui Hapua monitoring timeseries data

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

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

% Load lagoon water level data from web
AuthToken = aquariusGetAuthToken(Config.AquariusHostURL);
LagoonTS = aquariusGetData(Config.AquariusHostURL, Config.LagoonWLSiteID, ...
                           Config.LagoonWLDataId, Config.StartTime, ...
                           Config.EndTime, AuthToken, "+12:00");

% Remove the columns we're not using
LagoonTS.RangeNumber = [];
LagoonTS.Quality = [];
LagoonTS.Interpolation = [];
LagoonTS.Approval = [];
LagoonTS.Properties.VariableNames = {'DateTime','WL'};

% Remove the timezone (everything is in +12:00)
LagoonTS.DateTime.TimeZone = '';

% apply datum correction to LVD-37
LagoonTS.WL = LagoonTS.WL + Config.LagoonOffset; 

% Load Lagoon Hypsometry
Hypsometry = readtable(fullfile(Config.DataFolder,Config.HypsometryFile),...
                       'ReadVariableNames',true);
                   
% Load Sumner sea level data
% (exported from Tideda as 15 minute averaged data, synchronised to interval)
% SumnerTS = aquariusGetResampledData(Config.AquariusHostURL, 66699, ...
%                                     'HG.Master', Config.StartTime, ...
%                                     Config.EndTime, minutes(15), ...
%                                     AuthToken, "+12:00");
% SumnerTS.RangeNumber = [];
% SumnerTS.Quality = [];
% SumnerTS.Interpolation = [];
% SumnerTS.Approval = [];
% SumnerTS.Properties.VariableNames = {'DateTime','WL'};
% SumnerTS.DateTime.TimeZone = '';
                       
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
WaveModTS.Properties.VariableUnits = {'Datetime', ...
                                      'm', ...
                                      's', ...
                                      's', ...
                                      's', ...
                                      'degrees', ...
                                      'degrees', ...
                                      'degrees', ...
                                      'm/s', ...
                                      'm/s', ...
                                      'm/s', ...
                                      'm/s', ...
                                      'm', ...
                                      'm', ...
                                      'm3/s', ...
                                      'm3/s', ...
                                      'N/m2', ...
                                      'N/m2'};
WaveModTS = WaveModTS(WaveModTS.DateTime >= Config.StartTime & ...
                      WaveModTS.DateTime <= Config.EndTime, :);
% Remove columns we're not using
WaveModTS.Dspr = [];
WaveModTS.PkDir = [];
WaveModTS.XWindv = [];
WaveModTS.YWindv = [];
WaveModTS.Ubot = [];
WaveModTS.Urms = [];
WaveModTS.XWForce = [];
WaveModTS.YWForce = [];

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

clear LoggerData LoggerInterval FileNo AuthToken

%% Data QA

% Water Level Timeseries
DataOk = true(size(LagoonTS,1),1);
DataOk(LagoonTS.WL>3.7) = false;
DataOk(LagoonTS.WL<-0.1) = false;
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
% Remove bias between baro TS due to elevation
HurunuiBaroTS.Baro = HurunuiBaroTS.Baro - ...
                     (mean(HurunuiBaroTS.Baro) - mean(SumnerBaroTS.Baro));
% Plot
hold on
plot(HurunuiBaroTS.DateTime,HurunuiBaroTS.Baro,'r-'); 
legend('Sumner', 'Hurunui')

% Hypsometry
figure
plot(Hypsometry.Volume,Hypsometry.Elevation,'-xb')
xlabel('Lagoon volume [m^3]')
ylabel('Lagoon water surface elevation [m-LVD]')

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

%% Calculate runup height

% wave angle relative to beach [radians] (at ~10m depth)
WaveModTS.Angle_10m = angleDiff(deg2rad(Config.ShoreNormalDir), deg2rad(WaveModTS.Dir));

% Flag onshore directed waves and set offshore directed waves to have Hs=0
WaveModTS.OnshoreWaves = WaveModTS.Angle_10m>deg2rad(-89) & WaveModTS.Angle_10m<deg2rad(89);
WaveModTS.Hsig(~WaveModTS.OnshoreWaves) = 0;
WaveModTS.Angle_10m(~WaveModTS.OnshoreWaves) = 0;

% wave number (k) and ratio of group speed (celerity) to wave speed (n) (both calculated at 10m)
WaveModTS.k_10m = 2*pi./WaveModTS.Wlen;
WaveModTS.n_10m = 0.5 * (1 + 2*WaveModTS.k_10m.*WaveModTS.Depth ./ ...
                         sinh(2*WaveModTS.k_10m.*WaveModTS.Depth));

% Reverse shoal model data to deep water (needed for runup equations)
WaveModTS.LoffRatio = 1 ./ tanh(2*pi*WaveModTS.Depth./WaveModTS.Wlen);
WaveModTS.Wlen_Offshore = WaveModTS.Wlen .* WaveModTS.LoffRatio;
%WaveModTS.Wlen_Offshore2 = Config.Gravity * WaveModTS.Tm02.^2 / (2*pi); % calculated from T rather than L_10m
WaveModTS.Angle_Offshore = asin(max(min(WaveModTS.LoffRatio .* sin(WaveModTS.Angle_10m),1),-1)); % min and max is to prevent tiny irregularities generating complex numbers due to calculation of asin(>1) or asin(<-1)
WaveModTS.Hsig_Offshore = WaveModTS.Hsig ./ ...
                          ((1./(2*WaveModTS.n_10m)) .* ...
                           (WaveModTS.LoffRatio) .* ...
                           (cos(WaveModTS.Angle_Offshore)./cos(WaveModTS.Angle_10m))).^0.5;
   
% 2% Exceedence runup height [m] (Stockdon et al 2006)
WaveModTS.Runup1 = 1.1 * (0.35 * Config.Beachslope * (WaveModTS.Hsig_Offshore .* WaveModTS.Wlen_Offshore).^0.5 + ...
                          (WaveModTS.Hsig_Offshore .* WaveModTS.Wlen_Offshore * (0.563 * Config.Beachslope^2 + 0.004)).^0.5 / 2);
                  
% 2% Exceedence runup height [m] (Poate et al 2016 eq11) assuming Tz~Tm02
WaveModTS.Runup2 = 0.49 * Config.Beachslope^0.5 * WaveModTS.Tm02 .* WaveModTS.Hsig_Offshore;

% Compare runup from the 2 equations
figure
histogram(WaveModTS.Runup1,'BinWidth',0.1, ...
          'Normalization', 'probability')
hold on
histogram(WaveModTS.Runup2,'BinWidth',0.1, ...
          'Normalization', 'probability')
xlabel('2% runup height above still water level (m)')
ylabel('Proportion of time')
legend({'Stockdon et al (2006)','Poate et al (2016)'})
export_fig 'outputs\RunupComparison1.png' -m 5

figure
scatter(WaveModTS.Runup1, WaveModTS.Runup2, 6, 'filled', ...
        'MarkerEdgeAlpha', 0.15,'MarkerFaceAlpha', 0.15)
xlabel('Runup [m]: Stockdon et al (2006)')
ylabel('Runup [m]: Poate et al (2016)')
export_fig 'outputs\RunupComparison2.png' -m 5

WaveModTS.LoffRatio = [];

%% Calculate longshore transport rate

% Net direction of wave energy arriving from [radians] (at ~10m depth)
WaveModTS.DirEnergy_10m = acos(-WaveModTS.YTransp ./ ...
                               sqrt(WaveModTS.XTransp.^2 + WaveModTS.YTransp.^2));
WaveModTS.DirEnergy_10m(WaveModTS.XTransp>0) = 2*pi - WaveModTS.DirEnergy_10m(WaveModTS.XTransp>0);

% wave energy angle relative to beach [radians] (at ~10m depth)
WaveModTS.EAngle_10m = angleDiff(deg2rad(Config.ShoreNormalDir), WaveModTS.DirEnergy_10m);

% Total energy transport at 10m [W/m = N/s = kg.m/s3]
% (equivalent to eq 5, Appendix A, Hicks et al 2018)
WaveModTS.F_10m = Config.Rho * Config.Gravity * ...
                  sqrt(WaveModTS.XTransp.^2 + WaveModTS.YTransp.^2);

% Water depth at break point [m] (eq 12, Appendix A Hicks et al 2018)
WaveModTS.h_Break = (WaveModTS.F_10m * ...
                     8 / (Config.Rho*Config.Gravity^1.5*Config.Gamma^2)).^0.4;

% Wave angle to shoreline at breakpoint [radians] 
% Original approach (eq 13, Appendix A, Hicks et al 2018)
WaveModTS.EAngle_Break1 = asin(sqrt(WaveModTS.h_Break./WaveModTS.Depth) .* sin(WaveModTS.EAngle_10m));

% New approach (eliminating an incorrect assumption of shallow water)
WaveModTS.Cb_div_Ch = sqrt(Config.Gravity./WaveModTS.h_Break) ./ ...
                      (Config.Gravity*WaveModTS.Tm02.*tanh(2*pi*WaveModTS.Depth./WaveModTS.Wlen)/(2*pi));
WaveModTS.EAngle_Break = asin(sin(WaveModTS.EAngle_10m) .* WaveModTS.Cb_div_Ch);

% Compare
figure
plot(rad2deg(WaveModTS.EAngle_Break1),rad2deg(WaveModTS.EAngle_Break),'x')
xlim([-15,15])
ylim([-15,15])
xlabel('Breaker angle (Gorman shallow water assumption)')
ylabel('Breaker angle (Improved?)')
hold on
plot([-15,15],[-15,15],'k:')

% Longshore component of wave energy at the breakpoint [W/m]
WaveModTS.Pls_Break1 = WaveModTS.F_10m .* sin(WaveModTS.EAngle_Break1) .* cos(WaveModTS.EAngle_Break1);
WaveModTS.Pls_Break = WaveModTS.F_10m .* sin(WaveModTS.EAngle_Break) .* cos(WaveModTS.EAngle_Break);

% Longshore transport in immersed weight per unit time (N/s)
WaveModTS.LST1 = WaveModTS.Pls_Break1 * Config.K;
WaveModTS.LST = WaveModTS.Pls_Break * Config.K;
% Longshore transport converted to bulk volume per unit time [m3/s]
WaveModTS.LST1 = WaveModTS.LST1 / ...
                ((Config.RhoS-Config.Rho) * Config.Gravity * ...
                 (1-Config.VoidRatio));
WaveModTS.LST = WaveModTS.LST / ...
                ((Config.RhoS-Config.Rho) * Config.Gravity * ...
                 (1-Config.VoidRatio));


% Plot effect of refraction
figure
histogram(rad2deg(WaveModTS.EAngle_10m), 'BinEdges', -90:5:90, ...
          'Normalization', 'probability')
hold on
histogram(rad2deg(WaveModTS.EAngle_Break1), 'BinEdges', -90:5:90, ...
          'Normalization', 'probability')
histogram(rad2deg(WaveModTS.EAngle_Break), 'BinEdges', -90:5:90, ...
          'Normalization', 'probability')
YL = ylim;
plot([0,0],YL,'k-','LineWidth',3)
ylim(YL)
xlabel('Wave energy approach angle relative to shore normal (degrees)')
ylabel('Proportion of time')
xticks(-60:15:60)
xlim([-60,60])
xticklabels({'North';'45';'30';'15';'0';'15';'30';'45';'South'});
legend({'Angle at 10m depth','Angle at breakpoint (original approach)', ...
        'Angle at breakpoint (new approach)'}, ...
       'Location','SouthOutside')
export_fig 'outputs\RefractionEffectOnAngle.png' -m 5

% Plot energy weighted distribution of wave approach angle
[histw0, ~] = histwv(rad2deg(WaveModTS.EAngle_10m), WaveModTS.F_10m, ...
                        -90, 90, 48);
histw0=histw0/sum(histw0);
[histw1, ~] = histwv(rad2deg(WaveModTS.EAngle_Break1), WaveModTS.F_10m, ...
                        -90, 90, 48);
histw1=histw1/sum(histw1);
[histw2, ~] = histwv(rad2deg(WaveModTS.EAngle_Break), WaveModTS.F_10m, ...
                        -90, 90, 48);
histw2=histw2/sum(histw2);

figure
bar(-90+90/48:180/48:90-90/48, histw0, 1.0, 'FaceAlpha', 0.5)
hold on
bar(-90+90/48:180/48:90-90/48, histw1, 1.0, 'FaceAlpha', 0.5)
bar(-90+90/48:180/48:90-90/48, histw2, 1.0, 'FaceAlpha', 0.5)
YL = ylim;
plot([0,0],YL,'k-','LineWidth',3)
ylim(YL)
legend({'Energy', 'Time'})
xlabel('Wave energy approach angle at break point (degrees)')
ylabel('Proportion of energy')
xlim([-45,45])
legend({'Angle at 10m depth','Angle at breakpoint (original approach)', ...
        'Angle at breakpoint (new approach)'}, ...
       'Location','SouthOutside')
export_fig 'outputs\EnergyWeightedWaveApproachAngle.png' -m 5

% Plot longshore transport rate
figure
plot(WaveModTS.DateTime, WaveModTS.LST1)
hold on
plot(WaveModTS.DateTime, WaveModTS.LST)
ylabel('Longshore transport rate (m^3/s)')
legend({'Original approach','New approach'})

figure
histogram(WaveModTS.LST1*86400, 'BinEdges', -1000:50:1000, ...
          'Normalization', 'probability')
hold on
histogram(WaveModTS.LST*86400, 'BinEdges', -1000:50:1000, ...
          'Normalization', 'probability')
xlabel('Longshore transport rate (m^3/day)')
ylabel('Proportion of time')
XTL=xticklabels;
xticklabels([{'South'};XTL(2:end-1);{'North'}])
legend({'Original approach','New approach'},'Location','SouthOutside')

% Plot cumulative longshore transport
figure
plot(WaveModTS.DateTime, cumsum(WaveModTS.LST1)*60*60 / 1000,'b-')
hold on
plot(WaveModTS.DateTime, cumsum(WaveModTS.LST)*60*60 / 1000,'r-')
plot(WaveModTS.DateTime, cumsum(abs(WaveModTS.LST1))*60*60 / 1000,'b--')
plot(WaveModTS.DateTime, cumsum(abs(WaveModTS.LST))*60*60 / 1000,'r--')
ylabel('Cumulative longshore transport (thousand m^3)')
legend({'Net transport original approach', ...
        'Net transport new approach', ...
        'Gross transport original approach', ...
        'Gross transport new approach'}, ...
        'Location', 'Northwest')
export_fig 'outputs\CumulativeLongShoreTransport.png' -m 5

% Tidy up stuff we don't want to keep
clear histw0 histw1 histw2 XTL YL
WaveModTS.Cb_div_Ch = [];
WaveModTS.EAngle_Break1 = [];
WaveModTS.Pls_Break1 = [];
WaveModTS.LST1 = [];

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
LagoonTS.WavePower = interp1(WaveModTS.DateTime,...
                             WaveModTS.F_10m,...
                             LagoonTS.DateTime);
LagoonTS.LST = interp1(WaveModTS.DateTime,...
                       WaveModTS.LST,...
                       LagoonTS.DateTime);
LagoonTS.Runup1 = interp1(WaveModTS.DateTime,...
                          WaveModTS.Runup1,...
                          LagoonTS.DateTime);
LagoonTS.Runup2 = interp1(WaveModTS.DateTime,...
                          WaveModTS.Runup2,...
                          LagoonTS.DateTime);
% LagoonTS.SP = interp1(SalinityTS.DateTime,...
%                       SalinityTS.SP,...
%                       LagoonTS.DateTime);

figure
plot(LagoonTS.DateTime, LagoonTS{:,{'WL','SeaLevel'}});
datetickzoom('x')
ylabel('Water level [m-LVD]')
legend('Lagoon','Sea')

%% Calculate Runup Height (R_high) (Matias et al 2012)
% LagoonTS.OP1 = max(LagoonTS.SeaLevel + LagoonTS.Runup1 - Config.CrestHeight, 0);
% LagoonTS.OP2 = max(LagoonTS.SeaLevel + LagoonTS.Runup2 - Config.CrestHeight, 0);
LagoonTS.R_high1 = LagoonTS.SeaLevel + LagoonTS.Runup1;
LagoonTS.R_high2 = LagoonTS.SeaLevel + LagoonTS.Runup2;

figure
% plotyy(LagoonTS.DateTime,LagoonTS{:,{'WL','SeaLevel','OP1','OP2'}}, ...
%        LagoonTS.DateTime, LagoonTS.SP);
plot(LagoonTS.DateTime,LagoonTS{:,{'WL','SeaLevel','R_high1','R_high2'}});
datetickzoom('x')
ylabel('Overtopping potential (m)')
legend('Lagoon level','Sea level','Stockdon et al 2006','Poate et al 2016')

%% Calculate outflow (assuming static lagoon volume)
[LagoonTS.Qout, LagoonTS.Volume] = HindcastQ(Hypsometry,LagoonTS);

figure
plot(LagoonTS.DateTime,LagoonTS{:,{'Qin','Qout'}});
datetickzoom('x')
ylabel('Flow [m^3/s]')
legend('Inflow','Outflow')

%% Save lagoon TS
writetable(LagoonTS,'outputs\LagoonTS.csv')

DailyLagoonTS = dailyStats(LagoonTS);
writetable(DailyLagoonTS,'outputs\DailyLagoonTS.csv')

%% References
% Hicks D.M., Gorman R.M., Measures R.J., Walsh J.M., Bosserelle C. (2018) 
%    Coastal sand budget for Southern Pegasus Bay: Stage A, NIWA Client 
%    Report 2018062CH.
% Matias A., Williams J.J., Masselink G., Ferreira Ó. (2012) Overwash 
%    threshold for gravel barriers. Coast Eng 63:48–61. 
%    http://www.sciencedirect.com/science/article/pii/S0378383911001980
% Poate T.G., McCall R.T., Masselink G. (2016) A new parameterisation for 
%    runup on gravel beaches. Coast Eng 117:176–190. 
%    http://dx.doi.org/10.1016/j.coastaleng.2016.08.003
% Stockdon H.F., Holman R.A., Howd P.A., Sallenger A.H. (2006) Empirical 
%    parameterization of setup, swash, and runup. Coast Eng 53(7):573–588.
