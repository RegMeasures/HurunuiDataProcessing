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
XRange = [datetime('1-Jul-2015'),datetime('1-Oct-2017')]; % For paper
%XRange = [datetime('1-Dec-2016'),datetime('1-Sep-2017')]; % For presentation

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
KeyDates = {'12Oct2015','01Nov2015'; ... % Well connected lagoon - short outlet channel
            '05Nov2015','29Nov2015'; ... % Perched lagoon with extended outlet - at end of period small seaward truncation of outlet channel
            '12May2016','15May2016'; ... % Outlet channel migration widening lagoon
            '13Jul2016','15Jul2016'; ... % Lagoon flood due to small river flood when already perched
            '18Nov2016','20Nov2016'; ... % Outlet channel migration widening lagoon
            '19Jan2017','22Jan2017'; ... % River flood lagoon widening
            '16Feb2017','28Feb2017'; ... % Southwards offset driven by southwards longshore transport - sufficient to cause perched lagoon level
            '13Jun2017','16Jun2017'; ... % Wave overtopping lagoon narrowing
            '21Jul2017','23Jul2017'};    % Primary breach (+ some wave overtopping narrowing and some flood widening!)
% KeyDates = {'19Jan2017','22Jan2017'; ... % River flood lagoon widening
%             '01May2017','10Jun2017'; ... % Migration
%             '13Jun2017','16Jun2017'; ... % Wave overtopping lagoon narrowing
%             '21Jul2017','23Jul2017'};    % Primary breach (+ some wave overtopping narrowing and some flood widening!)

KeyDates = datetime(KeyDates,'InputFormat','ddMMMuuuu');
Alphabet = num2cell('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
DateLabels = Alphabet(1:size(KeyDates,1));

% set up figure size and margins
ax = figure_ts(6,datenum(XRange),0,'');
FigPos = get(gcf,'pos');
% Portrait
% set(gcf,'pos',[FigPos(1),FigPos(2)-(1000-FigPos(4)),700,1000], ...
%     'Color',[1,1,1])
% Landscape
set(gcf,'pos',[FigPos(1)-400,FigPos(2)-(900-FigPos(4)),1400,900], ...
    'Color',[1,1,1])
% Adjust margins
for ii=1:size(ax,2)
    AxPos = get(ax(ii),'Position');
    % Portrait
%     set(ax(ii),'Position', [AxPos(1:2), 1-2*AxPos(1), AxPos(4)], ...
%                'FontSize', 9, 'TickDir', 'out', ...
%                'TickLength', [0.005,0.005])
    % Landscape
    set(ax(ii),'Position', [0.07, AxPos(2), 0.86, AxPos(4)], ...
               'FontSize', 9, 'TickDir', 'out', ...
               'TickLength', [0.005,0.005])
end

% Add vertical gridlines and nice X axis labels
ax(2).XAxis.TickValues = ...
    datenum(dateshift(XRange(1), 'start', 'month', ...
                      0:3:calmonths(between(XRange(1),XRange(2)))));
datetick('x','mmmyy','keeplimits','keepticks')
ax(2).XGrid = 'on';
ax(2).GridLineStyle = '--';
% ax(2).XAxis.MinorTickValuesMode = 'manual';
% ax(2).XAxis.MinorTickValues = ...
%     datenum(dateshift(XRange(1), 'start', 'month', ...
%                       0:calmonths(between(XRange(1),XRange(2)))));
% ax(2).XAxis.MinorTick = 'on';
% ax(2).XMinorGrid = 'on';

% ticks and ylabels for each axis
YTicsChan = 0:400:1600; YLblChan  = {'Position of outlet channel'; ...
                                     '(m North of river centerline)'};
YTicsWidth = 30:30:150; YLblWidth = 'Lagoon width (m)';
YTicsFlow  = 0:200:600; YLblFlow  = 'River flow (m^3\cdots^{-1})';
YTicsLst   = -4:2:6; YLblLst   = {'Longshore transport potential'; ...
                                     '(positive northwards)'};
YTicsRunup = 0:0.5:2; YLblRunup = {'Overwash potential (m)'};
YTicsLevel = -1:1:3; YLblLevel = {'Water level (daily range, m)'; ...
                                   'sea = green, lagoon = blue'};

% plot outlet channel position including blindspot
Blindspot = [700, 830];
  
[ChanH, DataScale, DataOffset] = ...
    subplot_ts(ax, 1, YTicsChan ,YLblChan, 1.1, 1,...
               's1', repmat(datenum(ChannelPos.UniqueTime),[3,1]), ...
                     ChannelPos.UsOffset(:), '.k', 'MarkerSize', 7, ...
               's2', repmat(datenum(ChannelPos.UniqueTime),[3,1]), ...
                     ChannelPos.DsOffset(:), '.', 'MarkerSize', 7, ...
                     'Color', [0.6,0.6,0.6]);
                 
ChanH{end+1} = patch(ax(2),datenum([XRange,fliplr(XRange)]), ...
                     [Blindspot(1), Blindspot(1), Blindspot(2), Blindspot(2)] * ...
                     DataScale + DataOffset, ...
                     [0.85,0.9,0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6);

text(ax(2), datenum(XRange(1)+days(30)), ...
     mean(Blindspot) * DataScale + DataOffset, ...
     'Camera blind spot', 'Color', [0.2,0.3,0.2], ...
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

[WidthH, DataScale, DataOffset] = ...
    subplot_ts(ax, 2, YTicsWidth, YLblWidth, 1.3, -1.5,...
               's1', TPlotDates, T5, '.', 'MarkerSize', 6, 'color', WidthColors(1,:), ...
               's2', TPlotDates, T6, '.', 'MarkerSize', 6, 'color', WidthColors(2,:), ...
               's3', TPlotDates, T7, '.', 'MarkerSize', 6, 'color', WidthColors(3,:), ...
               's4', TPlotDates, T8, '.', 'MarkerSize', 6, 'color', WidthColors(4,:), ...
               's5', TPlotDates, T10, '.', 'MarkerSize', 6, 'color', WidthColors(6,:), ...
               's6', TPlotDates, T11, '.', 'MarkerSize', 6, 'color', WidthColors(7,:), ...
               's7', TPlotDates, T12, '.', 'MarkerSize', 6, 'color', WidthColors(8,:));

text(ax(2),datenum(2015,9,27),30*DataScale+DataOffset,'Camera failure', ...
     'Rotation', 90, 'VerticalAlignment', 'Middle', 'FontSize', 8, ...
     'Color',[0.2,0.3,0.2]);
 
% clear area for width legend
WidthH{end+1} = patch(ax(3),datenum([XRange(1), XRange(1)+(XRange(2)-XRange(1))*0.07, ...
                      XRange(1)+(XRange(2)-XRange(1))*0.07, XRange(1)]), ...
                      [20,20,160,160] * ...
                      DataScale + DataOffset, ...
                      'w', 'EdgeColor', 'none');
uistack(WidthH{end},'top')
                  
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
           's1', datenum(LagoonTS.DateTime), SmoothedLstPot, '-k', ...
           's2', datenum(LagoonTS.DateTime), SmoothedLstPotPos, '-b', ...
           's3', datenum(LagoonTS.DateTime), SmoothedLstPotNeg, '-r');

% overwash potential plot (Poate et al 2016 formulation for runup)
subplot_ts(ax, 5, YTicsRunup ,YLblRunup, 0.9, -2,...
           's1', datenum(LagoonTS.DateTime), LagoonTS.OP2, '-k');
%            's1', datenum(DailyLagoonTS.Date), DailyLagoonTS.MaxOP2, '-k');
           
% level plot
MSL = mean(LagoonTS.SeaLevel, 'omitnan');
LightBlue = [47/256, 141/256, 245/256];
Green = [0,0.5,0];

% lines
[LevelH, DataScale, DataOffset] = ...
    subplot_ts(ax, 6, YTicsLevel, YLblLevel, 1, -2, ...
               's1', datenum(DailyLagoonTS.Date), DailyLagoonTS.MaxWL - MSL, '-', 'Color', LightBlue, ...
               's2', datenum(DailyLagoonTS.Date), DailyLagoonTS.MinWL - MSL, '-', 'Color', LightBlue, ...
               's3', datenum(DailyLagoonTS.Date), DailyLagoonTS.MaxSeaLevel - MSL, '-', 'Color', Green, ...
               's4', datenum(DailyLagoonTS.Date), DailyLagoonTS.MinSeaLevel - MSL, '-', 'Color', Green);
% lagoon level filled patch
LevelH{end+1} = patch(ax(2), ...
                      datenum([DailyLagoonTS.Date; flipud(DailyLagoonTS.Date)]), ...
                      ([DailyLagoonTS.MinWL; flipud(DailyLagoonTS.MaxWL)] - MSL) * ...
                      DataScale + DataOffset, ...
                      [47/256, 141/256, 245/256], 'EdgeColor', 'none', 'FaceAlpha', 0.8);
uistack(LevelH{end},'bottom')
% sea level filled patch
LevelH{end+1} = patch(ax(2), ...
                      datenum([DailyLagoonTS.Date(~isnan(DailyLagoonTS.MinSeaLevel)); ...
                               flipud(DailyLagoonTS.Date(~isnan(DailyLagoonTS.MaxSeaLevel)))]), ...
                      ([DailyLagoonTS.MinSeaLevel(~isnan(DailyLagoonTS.MinSeaLevel)); ...
                        flipud(DailyLagoonTS.MaxSeaLevel(~isnan(DailyLagoonTS.MaxSeaLevel)))]  - ...
                      MSL) * DataScale + DataOffset, ...
                      Green, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
uistack(LevelH{end},'bottom')

% Legends
LegChan = legend(ax(2),[ChanH{1},ChanH{2}], ...
                 {'Upstream end of outlet channel', ...
                  'Downstream end of outlet channel'});               
set(LegChan, 'Position', [0.08, 0.88, 0.12, 0.0406], ...
             'box', 'on', 'EdgeColor', 'none', ...
             'color', [1,1,1])

LegWidth = legend(ax(3),[WidthH{1}, WidthH{2}, WidthH{3}, WidthH{4},...
                         WidthH{5}, WidthH{6}, WidthH{7}], ...
                  {'400m', '500m', '600m', '700m', '900m', '1000m', '1100m'});
% set(LegWidth, 'Position', [0.945, 0.64, 0.03, 0.0772], ...
%               'box', 'on', 'EdgeColor', 'none', ...
%               'color', [1,1,1])
set(LegWidth, 'Position', [0.08, 0.64, 0.03, 0.09], ...
              'box', 'on', 'EdgeColor', 'none', ...
              'color', [1,1,1])
title(LegWidth, 'Width at:', 'FontWeight', 'Normal')

% Top x-axis labels
TopAx = axes('XAxisLocation', 'top', 'YTick', [], 'color', 'none', ...
             'Position', [0.07, AxPos(2), 0.86, AxPos(4)], ...
             'FontSize', 9, 'TickDir', 'out', ...
             'TickLength', [0.005,0.005], ...
             'XLim', datenum(XRange), ...
             'XTick', datenum(mean(KeyDates,2)), ...
             'XTickLabels', DateLabels, ...
             'XColor','r', ...
             'TickLength', [0,0]);
%              'GridLineStyle','--', ...
%              'GridColor','r', ...
%              'GridAlpha', 0.5, ...
%              'XGrid', 'on');
for DateNo = 1:size(KeyDates,1)
    hold on
    patch(TopAx,datenum(KeyDates(DateNo,[1,2,2,1])),[1,1,0,0],'r', ...
          'EdgeColor', 'none', 'FaceAlpha', 0.2);
end
uistack(TopAx,'bottom')

% Save figure
export_fig('outputs\ConcurrentTimeseries', '-png', '-r450')
% export_fig('outputs\ConcurrentTimeseries', '-eps')

% Tidy up
clear YTicsChan YTicsWidth YTicsFlow YTicsLst PlotDates T5 T6 T7 T8 ...
    FigPos ChanSpacing range rangeFill scale LegChan ...
    LegWidth WidthH ChanH YLblChan YLblWidth YLblFlow YLblLst ...
    TPlotDates mdp LightBlue LevelH YTicsLevel YLblLevel LevelScale ...
    LevelOffset AxPos ax
