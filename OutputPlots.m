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

%% Load data

% Read lagoon time series (already processed)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

% Read in daily TS
DailyLagoonTS = readtable('outputs\DailyLagoonTS.csv');
DailyLagoonTS.Date = datetime(DailyLagoonTS.Date,'InputFormat','dd/MM/yyyy');

% Read sampled timeseries
load('outputs\ShortlistPhotos.mat');
%load('outputs\ShortlistPhotos_small.mat')

% Load channel position TS
load('outputs\ChannelPos.mat')

%% Longterm multi panel timeseries plot

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

FigureH = figure('Position', [(ScrSz(3)/2)-600, 50, 1200, 500]);
plot(repmat(ChannelPos.UniqueTime,[3,1]),[ChannelPos.UsOffset(:),ChannelPos.DsOffset(:)],'x')
xlim(XRange)
legend({'Upstream end of outlet channel','Downstream end of outlet channel'}, ...
       'Location', 'northwest')
ylabel('Alongshore distance (North positive) from river centreline (m)')

%% TS plot of flow only

FigureH = figure('Position', [(ScrSz(3)/2)-600, 50, 1200, 500]);
plot(LagoonTS.DateTime,LagoonTS.Qin)
xlim(XRange)
ylabel('Hapua inflow (m^3/s)')

%% TS Plot of waves

FigureH = figure('Position', [(ScrSz(3)/2)-600, 50, 1200, 500]);
plot(LagoonTS.DateTime,LagoonTS.WaveHs)
xlim(XRange)
ylabel('Offshore Sig. wave height, H_s (m)')


%% Longterm multi panel timeseries plot

% set up figure
ax = figure_ts(5,datenum(XRange),0,'Date');
FigPos = get(gcf,'pos');
set(gcf,'pos',[FigPos(1),FigPos(2)-(1000-FigPos(4)),700,1000], ...
    'Color',[1,1,1])
datetick('x','mmmyy','keeplimits')
ax(2).XGrid = 'on';
for ii=1:size(ax,2)
    AxPos = get(ax(ii),'Position');
    set(ax(ii),'Position', [AxPos(1:2), 1-2*AxPos(1), AxPos(4)], ...
               'FontSize', 9, 'TickDir', 'out', ...
               'TickLength', [0.005,0.005])
end

% ticks and ylabels for each axis
YTicsChan = 0:400:1600; YLblChan  = {'Alongshore position of outlet channel'; ...
                                     '(m North of river centerline)'};
YTicsWidth = 30:30:150; YLblWidth = 'Lagoon width (m)';
YTicsFlow  = 0:200:600; YLblFlow  = 'River flow (m^3/s)';
YTicsLst   = -10:10:30; YLblLst   = {'Longshore transport potential'; ...
                                     '(positive northwards)'};
YTicsRunup = 0:1:3; YLblRunup = {'Overwash potential'; ...
                                 '(daily maxima, m)'};

% plot outlet channel position
ChanScale = 1.1;
ChanOffset = 1;
Blindspot = [700, 830];

rangeFill = 10 * ChanScale;
range=abs(max(max(max(ChannelPos.UsOffset(ChannelPos.UniqueTime>=XRange(1) & ...
                                          ChannelPos.UniqueTime<=XRange(2),:), ...
                      ChannelPos.DsOffset(ChannelPos.UniqueTime>=XRange(1) & ...
                                          ChannelPos.UniqueTime<=XRange(2),:)))) - ...
          min(min(min(ChannelPos.UsOffset(ChannelPos.UniqueTime>=XRange(1) & ...
                                          ChannelPos.UniqueTime<=XRange(2),:), ...
                      ChannelPos.DsOffset(ChannelPos.UniqueTime>=XRange(1) & ...
                                          ChannelPos.UniqueTime<=XRange(2),:)))));
scale=rangeFill/range;
mdp=(min(min(min(ChannelPos.UsOffset(ChannelPos.UniqueTime>=XRange(1) & ...
                                     ChannelPos.UniqueTime<=XRange(2),:), ...
                 ChannelPos.DsOffset(ChannelPos.UniqueTime>=XRange(1) & ...
                                     ChannelPos.UniqueTime<=XRange(2),:)))) + ...
     range/2) * scale;
patch(ax(2),datenum([XRange,fliplr(XRange)]), ...
      [Blindspot(1), Blindspot(1), Blindspot(2), Blindspot(2)] * ...
          scale - 5 - mdp + ChanOffset, ...
      [0.9,0.95,0.9], 'EdgeColor', 'none')
  
ChanH = subplot_ts(ax, 1, YTicsChan ,YLblChan, ChanScale, ChanOffset,...
                   's1', repmat(datenum(ChannelPos.UniqueTime),[3,1]), ...
                         ChannelPos.UsOffset(:), '.k', 'MarkerSize', 7, ...
                   's2', repmat(datenum(ChannelPos.UniqueTime),[3,1]), ...
                         ChannelPos.DsOffset(:), '.', 'MarkerSize', 7, 'Color', [0.6,0.6,0.6]);

LegChan = legend(ax(2),[ChanH{1},ChanH{2}], ...
                 {'Upstream end of outlet channel', ...
                  'Downstream end of outlet channel'});               
set(LegChan, 'Position', [0.14, 0.88, 0.3191, 0.0406], ...
             'box', 'on', 'EdgeColor', 'none', ...
             'color', [1,1,1])

text(ax(2), datenum(XRange(1)+days(30)), ...
     mean(Blindspot) * scale -5-mdp+ChanOffset, ...
     'Camera blind spot', 'Color',[0.3,0.3,0.3], ...
     'VerticalAlignment', 'Middle', 'FontSize', 8)
       
% plot lagoon width
TPlotDates = repmat(datenum(ShortlistPhotos.UniqueTime), [5, 1]);
T4 = permute(ShortlistPhotos.OffsetOK(:,4,:),[1,3,2]); T4 = T4(:); T4(T4>160)=nan;
T5 = permute(ShortlistPhotos.OffsetOK(:,5,:),[1,3,2]); T5 = T5(:); T5(T5>160)=nan;
T6 = permute(ShortlistPhotos.OffsetOK(:,6,:),[1,3,2]); T6 = T6(:); T6(T6>160)=nan;
T7 = permute(ShortlistPhotos.OffsetOK(:,7,:),[1,3,2]); T7 = T7(:); T7(T7>160)=nan;
T8 = permute(ShortlistPhotos.OffsetOK(:,8,:),[1,3,2]); T8 = T8(:); T8(T8>160)=nan;
T10 = permute(ShortlistPhotos.OffsetOK(:,10,:),[1,3,2]); T10 = T10(:); T10(T10>160)=nan;
T11 = permute(ShortlistPhotos.OffsetOK(:,11,:),[1,3,2]); T11 = T11(:); T11(T11>160)=nan;
T12 = permute(ShortlistPhotos.OffsetOK(:,12,:),[1,3,2]); T12 = T12(:); T12(T12>160)=nan;
T13 = permute(ShortlistPhotos.OffsetOK(:,13,:),[1,3,2]); T13 = T13(:); T13(T13>160)=nan;
T14 = permute(ShortlistPhotos.OffsetOK(:,14,:),[1,3,2]); T14 = T14(:); T14(T14>160)=nan;
WidthColors = jet(8);

WidthH = subplot_ts(ax, 2, YTicsWidth, YLblWidth, 1.3, -1.5,...
                    's1', TPlotDates, T5, '.', 'MarkerSize', 6, 'color', WidthColors(1,:), ...
                    's2', TPlotDates, T6, '.', 'MarkerSize', 6, 'color', WidthColors(2,:), ...
                    's3', TPlotDates, T7, '.', 'MarkerSize', 6, 'color', WidthColors(3,:), ...
                    's4', TPlotDates, T8, '.', 'MarkerSize', 6, 'color', WidthColors(4,:), ...
                    's5', TPlotDates, T10, '.', 'MarkerSize', 6, 'color', WidthColors(6,:), ...
                    's6', TPlotDates, T11, '.', 'MarkerSize', 6, 'color', WidthColors(7,:), ...
                    's7', TPlotDates, T12, '.', 'MarkerSize', 6, 'color', WidthColors(8,:));

LegWidth = legend(ax(3),[WidthH{1}, WidthH{2}, WidthH{3}, WidthH{4},...
                         WidthH{5}, WidthH{6}, WidthH{7}], ...
                  {'400m', '500m', '600m', '700m', '900m', '1000m', '1100m'});
set(LegWidth, 'Position', [0.88, 0.59, 0.08, 0.0772], ...
              'box', 'on', 'EdgeColor', 'none', ...
              'color', [1,1,1])
title(LegWidth, 'Width at:', 'FontWeight', 'Normal')

% plot river flow
subplot_ts(ax, 3, YTicsFlow ,YLblFlow, 1, -2.5,...
           's1', datenum(LagoonTS.DateTime), LagoonTS.Qin, ...
                 'color', [0,0.7,0.9]);

% plot LST pot
SmoothedLstPot = movmean(LagoonTS.LstPot, days(1), 'SamplePoints', LagoonTS.DateTime);
SmoothedLstPotPos = SmoothedLstPot;
SmoothedLstPotNeg = SmoothedLstPot;
SmoothedLstPotPos(SmoothedLstPotPos<0) = nan;
SmoothedLstPotNeg(SmoothedLstPotNeg>0) = nan;
subplot_ts(ax, 4, YTicsLst ,YLblLst, 1.1, -3.5,...
           's1', datenum(LagoonTS.DateTime), SmoothedLstPotPos, '-b', ...
           's2', datenum(LagoonTS.DateTime), SmoothedLstPotNeg, '-r');

% overwash potential plot
subplot_ts(ax, 5, YTicsRunup ,YLblRunup, 0.9, -2,...
           's1', datenum(DailyLagoonTS.Date), DailyLagoonTS.MaxOP1, '-k');%, ...
           %'s2', datenum(DailyLagoonTS.Date), DailyLagoonTS.MaxOP2, '-r');

export_fig('outputs\ConcurrentTimeseries', '-png', '-r450')

clear YTicsChan YTicsWidth YTicsFlow YTicsLst PlotDates T5 T6 T7 T8 ...
    FigPos ChanSpacing ChanOffset range rangeFill scale LegChan ...
    LegWidth WidthH ChanH YLblChan YLblWidth YLblFlow YLblLst ...
    TPlotDates mdp ax
