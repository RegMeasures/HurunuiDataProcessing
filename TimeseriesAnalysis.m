% Hindcast outlet flow time series
% Uses HindcastQ.m

% add associated functions
addpath('functions')
addpath('inputs')

% Add T_Tide toolbox
% Used for tidal harmonics analysis.
% More information at <https://www.eoas.ubc.ca/~rich/#T_Tide>
addpath functions\t_tide_v1.3beta\

%% Get input parameters
% Stored in settings file
Config = TimeseriesConfig;

%% Load Data and apply datum corrections etc.

% Load Hurunui at SH1 flow data from TidedaCSV
% HurunuiSH1 = readtable(fullfile(Config.DataFolder,Config.HurunuiSH1File),...
%                        'Delimiter',',',...
%                        'HeaderLines',2,...
%                        'ReadVariableNames',false);
% HurunuiSH1.Properties.VariableNames = {'DateTime', 'Flow'};
% HurunuiSH1.DateTime = datenum(HurunuiSH1.DateTime,'dd/mm/yyyy HH:MM:SS');

% Load Hurunui at SH1 data from web :-)
HurunuiCSV = urlread(Config.HurunuiSH1EcanData);
HurCellArray = textscan(HurunuiCSV,'%*d %s %f',...
                      'delimiter',',',...
                      'headerlines',1);
HurunuiSH1.DateTime = HurCellArray{1,1};
HurunuiSH1.DateTime = strrep(HurunuiSH1.DateTime,'a.m.','AM');
HurunuiSH1.DateTime = strrep(HurunuiSH1.DateTime,'p.m.','PM');
HurunuiSH1.DateTime = datenum(HurunuiSH1.DateTime,'dd/mm/yyyy HH:MM:SS PM');
HurunuiSH1.Flow = HurCellArray{1,2};
HurunuiSH1 = struct2table(HurunuiSH1);
clear HurunuiCSV HurCellArray

% Apply time delay to account for travel time from SH1 to coast
HurunuiSH1.DateTime = HurunuiSH1.DateTime + Config.SH1_to_lagoon;

% Load lagoon water level data
LagoonTS = readtable(fullfile(Config.DataFolder,Config.LagoonWLFile),...
                     'Delimiter',',',...
                     'HeaderLines',1,...
                     'ReadVariableNames',false);
LagoonTS.Properties.VariableNames = {'Date','Time','WL'};

% convert WL to metres
LagoonTS.WL = LagoonTS.WL / 1000; 

% apply datum correction
LagoonTS.WL = LagoonTS.WL + Config.LagoonOffset; 

% Convert Date and Time cols to datenum
LagoonTS.DateTime = datenum(strcat(LagoonTS.Date,LagoonTS.Time),...
                          'dd/mm/yyyyHH:MM:SS');
LagoonTS.Date = []; % Remove date col as no longer needed
LagoonTS.Time = []; % Remove Time col as no longer needed
LagoonTS = [LagoonTS(:,2),LagoonTS(:,1)]; % re-order columns
LagoonTS = flipud(LagoonTS); % reverse row order (so time increases)

% Load Lagoon Hypsometry
Hypsometry = readtable(fullfile(Config.DataFolder,Config.HypsometryFile),...
                       'ReadVariableNames',true);
                   
% Load Sumner sea level data
SumnerTS = readtable(fullfile(Config.DataFolder,Config.SumnerFile),...
                     'Delimiter',',',...
                     'HeaderLines',2,...
                     'ReadVariableNames',false);
SumnerTS.Properties.VariableNames = {'DateTime', 'WL'};
SumnerTS.DateTime = datenum(SumnerTS.DateTime,'dd/mm/yyyy HH:MM:SS');

% apply datum correction
SumnerTS.WL = SumnerTS.WL + Config.SumnerOffset; 

% Load Sumner barometric data
SumnerBaroTS = readtable(fullfile(Config.DataFolder,Config.SumnerBaroFile),...
                     'Delimiter',',',...
                     'HeaderLines',2,...
                     'ReadVariableNames',false);
SumnerBaroTS.Properties.VariableNames = {'DateTime', 'Baro'};
SumnerBaroTS.DateTime = datenum(SumnerBaroTS.DateTime,'dd/mm/yyyy HH:MM:SS');

% Load Hurunui barometric pressure data
% use cheviot for now from CliFlow (site 31832)
% have manually deleted footer rows to ease import
HurunuiBaroTS = readtable(fullfile(Config.DataFolder,Config.HurunuiBaroFile),...
                     'Delimiter',',',...
                     'HeaderLines',9,...
                     'ReadVariableNames',false);
HurunuiBaroTS(:,[1,4:7]) = [];
HurunuiBaroTS.Properties.VariableNames = {'DateTime', 'Baro'};
HurunuiBaroTS.DateTime = datenum(HurunuiBaroTS.DateTime,'yyyymmdd:HHMM');

% Read wavedata
% - tideda exports for same time period and synchronised to 30min intervals
%   fill in na lines to correct number of data values (e.g. na,na,na,etc)
WaveTS = readtable(fullfile(Config.DataFolder,Config.WaveCSV1),...
                   'Delimiter',',',...
                   'HeaderLines',1,...
                   'ReadVariableNames',true);
WaveTS.Date = datenum(WaveTS.Date,'dd/mm/yyyy HH:MM:SS');

WaveTS2 = readtable(fullfile(Config.DataFolder,Config.WaveCSV2),...
                    'Delimiter',',',...
                    'HeaderLines',1,...
                    'ReadVariableNames',true);
WaveTS2.Date = datenum(WaveTS2.Date,'dd/mm/yyyy HH:MM:SS');

% Combine wavedata into 1 table
WaveTS = [WaveTS, WaveTS2(:,2:end)]; % if this line doesn't work check tideda exports for same time period and synchronised to 30min intervals
clear WaveTS2
WaveTS{:,2:end} = num2cell(str2double(WaveTS{:,2:end}));

%% Data QA

% Water Level Timeseries
DataOk = true(size(LagoonTS,1),1);
DataOk(LagoonTS.WL>3.7) = false;
DataOk(LagoonTS.WL<-0.1) = false;
LagoonTS = LagoonTS(DataOk,:);
figure
plot(LagoonTS.DateTime,LagoonTS.WL)
datetick('x')
ylabel('Measured Lagoon Water Level [m-LVD]')

% Inflow TS
figure
plot(HurunuiSH1.DateTime,HurunuiSH1.Flow);
datetick('x')
ylabel('Measured Hurunui Flow [m^3/s]')

% Sumner sea level
% QualityCheck
DataOk = true(size(SumnerTS,1),1);
DataOk(SumnerTS.WL > +3) = false;
DataOk(SumnerTS.WL < -3) = false;
WLchange = [0;(SumnerTS.WL(2:end)-SumnerTS.WL(1:end-1));0];
DataOk(WLchange(1:end-1) > 0.5 & WLchange(2:end) < -0.5|...
      WLchange(1:end-1) < -0.5 & WLchange(2:end) > 0.5) = false;
SumnerTS = SumnerTS(DataOk,:);
% Plot
figure
plot(SumnerTS.DateTime,SumnerTS.WL,'b-');
datetick('x')
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
datetick('x')
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

clear DataOk

%% Convert Sumner tide to Hurunui

% Calculate observed tidal anomaly at sumner
[HurunuiTide.DateTime, HurunuiTide.Anomaly] = ...
    CalcTidalAnomaly(SumnerTS, SumnerBaroTS);
HurunuiTide = struct2table(HurunuiTide);

% Calculate astronomic tide at Hurunui
[HurunuiTide.Astronomic] = ...
    AstronomicTide(fullfile(Config.DataFolder,Config.HurunuiTidalConstFile),...
                   HurunuiTide.DateTime, Config.TimeZone);

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
datetickzoom('x')
legend('Sumner observed','Hurunui calculated')
ylabel('Sea level [mLVD]')

%% Calculate wave parameters
WaveTS.Angle = angleDiff(WaveTS.DirDeg*pi/180, Config.OnshoreDir*pi/180);
%WaveTS.LstPot = 

%% Interpolate data onto same timesteps
LagoonTS.Qin = interp1(HurunuiSH1.DateTime,...
                       HurunuiSH1.Flow,...
                       LagoonTS.DateTime);
LagoonTS.SeaLevel = interp1(HurunuiTide.DateTime,...
                            HurunuiTide.Final,...
                            LagoonTS.DateTime);
LagoonTS.WaveHs = interp1(WaveTS.Date,...
                          WaveTS.HsM,...
                          LagoonTS.DateTime);
LagoonTS.WaveTs = interp1(WaveTS.Date,...
                          WaveTS.TsSec,...
                          LagoonTS.DateTime);
LagoonTS.WaveAngle = interp1(WaveTS.Date,...
                           WaveTS.Angle,...
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

%% Save lagoon TS
writetable(LagoonTS,'LagoonTS.csv')

DailyLagoonTS = dailyStats(LagoonTS);
writetable(DailyLagoonTS,'DailyLagoonTS.csv')

%% Estimate Channel Dimensions

% Cut down TS
AllData = ~isnan(LagoonTS.WL) & ~isnan(LagoonTS.Qin) & ~isnan(LagoonTS.SeaLevel);
CropTS = LagoonTS(AllData,:);

% Cut down further for testing
CropTS = CropTS(CropTS.DateTime>=datenum('1-May-2016')&CropTS.DateTime<datenum('1-Jun-2016'),:);

TestTimeSteps = 1:size(CropTS,1)/48;
Channel = cell(size(TestTimeSteps,2),1);
meanT = nan(size(TestTimeSteps,2),1);
RMSE = nan(size(TestTimeSteps,2),1);
ExitFlag = nan(size(TestTimeSteps,2),1);

parfor i = TestTimeSteps;
%for i=100:1000:5100;
    
    % Set up the optimisatin inputs
    meanT(i,1) = mean(CropTS.DateTime(i*48-47:i*48));
    Q = CropTS.Qout(i*48-47:i*48);
    E_us = CropTS.WL(i*48-47:i*48);
    E_ds = CropTS.SeaLevel(i*48-47:i*48);
    Manning = 0.04;
%     
%     figure
%     plot(Q)
%     figure
%     plot(E_us,'-r')
%     hold on
%     plot(E_ds,'-b')
    
    % Do the optimisation
    %[Channel{i,1},RMSE(i,1),ExitFlag(i,1)] = FitChannel(Q, E_us, E_ds, Manning);
    [Channel{i,1},RMSE(i,1),ExitFlag(i,1)] = FitChannel_4par(Q, E_us, E_ds, Manning);
    %[Channel{i,1},RMSE(i,1),ExitFlag(i,1)] = FitChannel_3par(Q, E_us, E_ds, Manning);
    
end

% Make a tidy output table
ChannelTable = [table(meanT),struct2table(cell2mat(Channel)),table(RMSE)];
writetable(ChannelTable,'ChannelTable_4pars.csv')
save('ChannelTable_4pars','ChannelTable')


%% Plot the results

%plot(ChannelTable.meanT,ChannelTable.RMSE)
figure
yyplotH = plotyy(ChannelTable.meanT,ChannelTable.L,CropTS.DateTime,[CropTS.WL,CropTS.SeaLevel]);
ylabel(yyplotH(1),'Channel Length [m]')
ylabel(yyplotH(2),'Water Level [mLVD]')
legend('Channel length','Lagoon level','Sea level')
datetick(yyplotH(1),'x','keeplimits')
set(yyplotH(2),'XTick',[])

figure
yyplotH = plotyy(ChannelTable.meanT,ChannelTable.RMSE,CropTS.DateTime,[CropTS.WL,CropTS.SeaLevel]);
ylabel(yyplotH(1),'RMSE [m]')
ylabel(yyplotH(2),'Water Level [mLVD]')
legend('RMSE','Lagoon level','Sea level')
datetick('x')

figure
yyplotH = plotyy(ChannelTable.meanT,ChannelTable.L,ChannelTable.meanT,ChannelTable.RMSE);
ylabel(yyplotH(1),'Channel Length [m]')
ylabel(yyplotH(2),'RMSE in us WL [m]')

figure
yyplotH = plotyy(ChannelTable.meanT,ChannelTable.B,CropTS.DateTime,CropTS.WL);
ylabel(yyplotH(1),'Channel width [m]')
ylabel(yyplotH(2),'RMSE in us WL [m]')