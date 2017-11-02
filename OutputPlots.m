%% Poster & Paper plots

%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% get screensize for plot setups
ScrSz = get(groot, 'ScreenSize');

%% Plot setup
XRange = [datetime('1-Jul-2015'),datetime('1-Oct-2017')];

%% Longterm multi panel timeseries plot

% Read lagoon time series (already processed)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

FigureH = figure('Position', [(ScrSz(3)/2)-600, 50, 1200, 800]);

% Top panel - flow
% timeseries
AxH{1} = subplot(3,2,1);
plot(AxH{1},LagoonTS.DateTime,LagoonTS.Qin)
xlim(AxH{1},XRange)
ylim(AxH{1},[0,400])
ylabel(AxH{1},'Hapua inflow (m^3/s)')
% cumulative frequency
AxH{2} = subplot(3,2,2);
[f,x] = ecdf(LagoonTS.Qin);
plot((1-f)*100,x)
ylim(AxH{2},[0,400])
xlabel(AxH{2},'% of time exceeded')
xticks(AxH{2},0:25:100)

% Second panel - waves
AxH{3} = subplot(3,2,3);
plot(AxH{3},LagoonTS.DateTime,LagoonTS.WaveHs)
xlim(AxH{3},XRange)
ylim(AxH{3},[0,8])
ylabel(AxH{3},'Offshore Sig. wave height, H_s (m)')
% cumulative frequency
AxH{4} = subplot(3,2,4);
[f,x] = ecdf(LagoonTS.WaveHs);
plot((1-f)*100,x)
ylim(AxH{4},[0,8])
xlabel(AxH{4},'% of time exceeded')
xticks(AxH{4},0:25:100)

% Third panel - lagoon and tide level
AxH{5} = subplot(3,2,5);
plot(AxH{5},LagoonTS.DateTime,[LagoonTS.WL,LagoonTS.SeaLevel])
xlim(AxH{5},XRange)
ylim(AxH{5},[-1,4])
ylabel(AxH{5},'Water level (mLVD)')
legend(AxH{5},{'Lagoon level','Sea level'})
% cumulative frequency
AxH{6} = subplot(3,2,6);
[f,x] = ecdf(LagoonTS.WL);
plot((1-f)*100,x)
ylim(AxH{6},[-1,4])
xlabel(AxH{6},'% of time exceeded')
xticks(AxH{6},0:25:100)

% Adjust plot positions and margins
set(AxH{1}, 'Position', [0.05, 2/3+0.055, 0.71, 1/3-0.06])
set(AxH{2}, 'Position', [0.8,  2/3+0.055, 0.18, 1/3-0.06])
set(AxH{3}, 'Position', [0.05, 1/3+0.055, 0.71, 1/3-0.06])
set(AxH{4}, 'Position', [0.8,  1/3+0.055, 0.18, 1/3-0.06])
set(AxH{5}, 'Position', [0.05, 0/3+0.055, 0.71, 1/3-0.06])
set(AxH{6}, 'Position', [0.8,  0/3+0.055, 0.18, 1/3-0.06])

%% TS plot of daily WL analysis

% Read in daily TS
DailyLagoonTS = readtable('outputs\DailyLagoonTS.csv');
DailyLagoonTS.Date = datetime(DailyLagoonTS.Date,'InputFormat','dd/MM/yyyy');

% overview TS
figure

fill([DailyLagoonTS.Date;flipud(DailyLagoonTS.Date)],[DailyLagoonTS.MinWL;flipud(DailyLagoonTS.MaxWL)],[0.3,0.3,0.3])
hold on
plot(DailyLagoonTS.Date,DailyLagoonTS.MeanWL,'r-')
xlim(XRange)

% looking at range and flow variability for proxies
figure
DailyLagoonTS.WL_Range = DailyLagoonTS.MaxWL-DailyLagoonTS.MinWL;
DailyLagoonTS.Qout_Range = DailyLagoonTS.MaxQout-DailyLagoonTS.MinQout;
DailyLagoonTS.Qout_RangeRatio = DailyLagoonTS.Qout_Range./DailyLagoonTS.MeanQout;
[AX,~,~] = plotyy(DailyLagoonTS.Date,DailyLagoonTS.WL_Range,...
                    DailyLagoonTS.Date,DailyLagoonTS.Qout_RangeRatio);
xlim(AX,XRange)
ylim(AX(1),[0,2])
ylabel(AX(1),'Lagoon water level range (m)')
ylabel(AX(2),'Lagoon outflow variability (% of mean outflow)')

figure
plot(DailyLagoonTS.WL_Range,DailyLagoonTS.Qout_RangeRatio,'x')
xlabel('Lagoon water level range (m)')
ylabel('Lagoon outflow variability (% of mean outflow)')

figure
plot(DailyLagoonTS.WL_Range,DailyLagoonTS.MeanQin,'x')
xlabel('Lagoon water level range (m)')
ylabel('Lagoon inflow (m^3/s)')

%% TS plot of outlet channel position

load('outputs\ChannelPos.mat')
FigureH = figure('Position', [(ScrSz(3)/2)-600, 50, 1200, 500]);
plot(ChannelPos.UniqueTime,[ChannelPos.UsOffset,ChannelPos.DsOffset],'x')
xlim(XRange)
legend({'Upstream end of outlet channel','Downstream end of outlet channel'}, ...
       'Location', 'northwest')
ylabel('Alongshore distance (North positive) from river centreline (m)')

%% TS plot of flow only

% Read lagoon time series (already processed)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

FigureH = figure('Position', [(ScrSz(3)/2)-600, 50, 1200, 500]);
plot(LagoonTS.DateTime,LagoonTS.Qin)
xlim(XRange)
ylabel('Hapua inflow (m^3/s)')

%% TS Plot of waves

% Read lagoon time series (already processed)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

FigureH = figure('Position', [(ScrSz(3)/2)-600, 50, 1200, 500]);
plot(LagoonTS.DateTime,LagoonTS.WaveHs)
xlim(XRange)
ylabel('Offshore Sig. wave height, H_s (m)')


%% Longterm multi panel timeseries plot

% Read lagoon time series (already processed)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

% Read sampled timeseries
load('outputs\ShortlistPhotos.mat')

% Load channel position TS
load('outputs\ChannelPos.mat')

% set up figure
ax = figure_ts(4,datenum(XRange),0,'Date');
datetick('x','mmmyy','keeplimits')
ax(2).XGrid = 'on';

% ticks and ylabels for each axis
YTicsChan = [0,400,800,1200,1600]; YLblChan = 'Alongshore distance from river centreline (m)';
YTicsWidth = [40,80,120,160]; YLblWidth = 'Lagoon width (m)';
YTicsFlow = [0,100,200,300,400]; YLblFlow = 'River flow (m^3/s)';
YTicsLst = [-40,0,40,80]; YLblLst = 'Longshore transport potential';

% plot outlet channel position
subplot_ts(ax, 1, YTicsChan ,YLblChan, 0.3, 0,...
           's1', datenum(ChannelPos.UniqueTime), ChannelPos.UsOffset, ...
                 '.k', ...
           's2', datenum(ChannelPos.UniqueTime), ChannelPos.DsOffset, ...
                 '.r')
       
% plot lagoon width
TPlotDates = repmat(datenum(ShortlistPhotos.UniqueTime), [5, 1]);
T5 = permute(ShortlistPhotos.OffsetOK(:,5,:),[1,3,2]); T5 = T5(:);
T6 = permute(ShortlistPhotos.OffsetOK(:,6,:),[1,3,2]); T6 = T6(:);
T7 = permute(ShortlistPhotos.OffsetOK(:,7,:),[1,3,2]); T7 = T7(:);
T8 = permute(ShortlistPhotos.OffsetOK(:,8,:),[1,3,2]); T8 = T8(:);

subplot_ts(ax, 2, YTicsWidth, YLblWidth, 0.7, 1,...
           's1', TPlotDates, T5, '.g', ...
           's2', TPlotDates, T6, '.b', ...
           's3', TPlotDates, T7, '.k', ...
           's4', TPlotDates, T8, '.r');

% plot river flow
subplot_ts(ax, 3, YTicsFlow ,YLblFlow, 0.5, 0,...
           's1', datenum(LagoonTS.DateTime), LagoonTS.Qin, ...
                 'color', [0,0.7,0.9]);

% plot LST pot
subplot_ts(ax, 4, YTicsLst ,YLblLst, 0.2, -1,...
           's1', datenum(LagoonTS.DateTime), LagoonTS.LstPot, '-k');


% add legend for transects
%LegWidth = legend_ts(ax, 2, 'west', ...
%                     'Transect 5', 'Transect 6', 'Transect 7', 'Transect 8');

clear YTicsChan YTicsWidth YTicsFlow YTicsLstT PlotDates T5 T6 T7 T8

