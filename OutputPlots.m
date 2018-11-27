%% Longterm multi panel timeseries plot

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

%% set up figure

% Create figure and set size
ax = figure_ts(6,datenum(XRange),0,'');
FigPos = get(gcf,'pos');
set(gcf,'pos',[FigPos(1)-400,FigPos(2)-(900-FigPos(4)),1400,900], ...
    'Color',[1,1,1])

% Adjust margins
for ii=1:size(ax,2)
    AxPos = get(ax(ii),'Position');
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

% ticks and ylabels for each axis
YTicsChan = 0:400:1600; YLblChan  = {'Position of outlet channel'; ...
                                     '(m north of river centerline)'};
YTicsWidth = 30:30:150; YLblWidth = {'Lagoon width';
                                     '(m)'};
YTicsFlow  = 0:200:800; YLblFlow  = {'River flow'; ...
                                     '(m^3/s)'}; % '(m^3\cdots^{-1})';
YTicsLst   = -250:250:500; YLblLst   = {'Longshore transport, Q_s'; ...
                                        '(m^3/day, positive northwards)'};
YTicsRunup = 1:1:5; YLblRunup = {'Wave runup height, \itR_{high}\rm'; ...
                                 '(daily max, m-LVD)'};
YTicsLevel = -1:1:3; YLblLevel = {'Water level'; ...
                                  '(daily range, m-LVD)'};

%% plot outlet channel position including blindspot
Blindspot = [700, 830];
  
[ChanH, DataScale, DataOffset] = ...
    subplot_ts(ax, 1, YTicsChan ,YLblChan, 1.1, 1,...
               's1', repmat(datenum(ChannelPos.UniqueTime),[3,1]), ...
                     ChannelPos.UsOffset(:), '.k', 'MarkerSize', 9, ...
               's2', repmat(datenum(ChannelPos.UniqueTime),[3,1]), ...
                     ChannelPos.DsOffset(:), '.', 'MarkerSize', 9, ...
                     'Color', [0.6,0.6,0.6]);
                 
ChanH{end+1} = patch(ax(2),datenum([XRange,fliplr(XRange)]), ...
                     [Blindspot(1), Blindspot(1), Blindspot(2), Blindspot(2)] * ...
                     DataScale + DataOffset, ...
                     [0.85,0.9,0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
uistack(ChanH{end},'bottom')

text(ax(2), datenum(XRange(1)+days(30)), ...
     mean(Blindspot) * DataScale + DataOffset, ...
     'Camera blind spot', 'Color', [0.2,0.3,0.2], ...
     'VerticalAlignment', 'Middle', 'FontSize', 8)
       
%% plot lagoon width
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
               's1', TPlotDates, T5, '.', 'MarkerSize', 8, 'color', WidthColors(1,:), ...
               's2', TPlotDates, T6, '.', 'MarkerSize', 8, 'color', WidthColors(2,:), ...
               's3', TPlotDates, T7, '.', 'MarkerSize', 8, 'color', WidthColors(3,:), ...
               's4', TPlotDates, T8, '.', 'MarkerSize', 8, 'color', WidthColors(4,:), ...
               's5', TPlotDates, T10, '.', 'MarkerSize', 8, 'color', WidthColors(6,:), ...
               's6', TPlotDates, T11, '.', 'MarkerSize', 8, 'color', WidthColors(7,:), ...
               's7', TPlotDates, T12, '.', 'MarkerSize', 8, 'color', WidthColors(8,:));

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
                  
%% plot river flow
subplot_ts(ax, 3, YTicsFlow ,YLblFlow, 0.95, -1.5,...
           's1', datenum(LagoonTS.DateTime), LagoonTS.Qin, ...
                 'color', [0,0.7,0.9]);

% plot longshore transport in m3/day
SmoothedLstPot = movmean(LagoonTS.LST, days(1), 'SamplePoints', LagoonTS.DateTime);
SmoothedLstPot = SmoothedLstPot * 60*90*24; % convert to daily rate
SmoothedLstPotPos = SmoothedLstPot;
SmoothedLstPotNeg = SmoothedLstPot;
SmoothedLstPotPos(SmoothedLstPotPos<0) = nan;
SmoothedLstPotNeg(SmoothedLstPotNeg>0) = nan;
subplot_ts(ax, 4, YTicsLst ,YLblLst, 1.1, -2.5,...
           's1', datenum(LagoonTS.DateTime), SmoothedLstPot, '-k', ...
           's2', datenum(LagoonTS.DateTime), SmoothedLstPotPos, '-b', ...
           's3', datenum(LagoonTS.DateTime), SmoothedLstPotNeg, '-r');

%% runup plot
% plot max daily runup
[RunupH, DataScale, DataOffset] = ...
    subplot_ts(ax, 5, YTicsRunup ,YLblRunup, 0.9, -2.5,...
               's1', datenum(DailyLagoonTS.Date), DailyLagoonTS.MaxR_high2, '-k'); %, ...
               %'s2', datenum(DailyLagoonTS.Date), DailyLagoonTS.MaxR_high1, '-', 'Color', [1,0,0.8]);
% add shaded band for barrier crest height
RunupH{end+1} = patch(ax(2),datenum([XRange,fliplr(XRange)]), ...
                      [Config.CrestHeight(1), Config.CrestHeight(1), ...
                       Config.CrestHeight(2), Config.CrestHeight(2)] * ...
                      DataScale + DataOffset, ...
                      [0.85,0.9,0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
uistack(ChanH{end},'bottom')
[figx, figy] = axxy2figxy(ax(2), repmat(datenum(XRange(1)+days(90)), [2,1]), ...
                          Config.CrestHeight * DataScale + DataOffset);
annotation('doublearrow', figx, figy, 'Color', [0.2,0.3,0.2], ...
           'Head1Length', 5, 'Head1Width', 5, ...
           'Head2Length', 5, 'Head2Width', 5)
text(ax(2), datenum(XRange(1)+days(92)), ...
     mean(Config.CrestHeight) * DataScale + DataOffset, ...
     'Typical range of barrier crest elevation', 'Color', [0.2,0.3,0.2], ...
     'VerticalAlignment', 'Middle', 'FontSize', 8)
           
%% level plot
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

%% Legends
LegChan = legendflex([ChanH{1},ChanH{2}], ...
                     {'Lagoon end of channel', ...
                      'Sea end of channel'}, ...
                     'xscale', 0.5, ...
                     'anchor', [3,3], 'buffer', [-5,-5], 'ref', ax(2));               

LegWidth = legendflex([WidthH{1}, WidthH{2}, WidthH{3}, WidthH{4},...
                       WidthH{5}, WidthH{6}, WidthH{7}], ...
                      {'400m', '500m', '600m', '700m', '900m', '1000m', '1100m'}, ...
                      'xscale', 0.5, ...
                      'title', {'Width at:'; '(see Figure 2'; 'for locations)'}, ...
                      'anchor', [1,1], 'buffer', [5,-155], 'ref', ax(2));

% LegRunup = legendflex([RunupH{1}, RunupH{2}], ...
%                       {'Poate et al. (2016)', 'Stockdon et al. (2006)'}, ...
%                       'xscale', 0.5, 'padding', [1,1,4], ...
%                       'anchor', [5,5], 'buffer', [-5,115], 'ref', ax(2));

LegLevel = legendflex([LevelH{end-1}, LevelH{end}], ...
                      {'Lagoon level', 'Sea level'}, ...
                      'xscale', 0.5, 'padding', [1,1,4], ...
                      'anchor', [7,7], 'buffer', [5,5], 'ref', ax(2));

%% Add vertical red bands to show key dates and label along top x-axis
Alphabet = num2cell('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
DateLabels = Alphabet(1:size(Config.KeyPeriods,1));
TopAx = axes('XAxisLocation', 'top', 'YTick', [], 'color', 'none', ...
             'Position', [0.07, AxPos(2), 0.86, AxPos(4)], ...
             'FontSize', 9, 'TickDir', 'out', ...
             'TickLength', [0.005,0.005], ...
             'XLim', datenum(XRange), ...
             'XTick', datenum(mean(Config.KeyPeriods,2)), ...
             'XTickLabels', DateLabels, ...
             'XColor','r', ...
             'TickLength', [0,0]);
for DateNo = 1:size(Config.KeyPeriods,1)
    hold on
    patch(TopAx,datenum(Config.KeyPeriods(DateNo,[1,2,2,1])),[1,1,0,0],'r', ...
          'EdgeColor', 'none', 'FaceAlpha', 0.2);
end
uistack(TopAx,'bottom')

%% Save figure
export_fig('outputs\ConcurrentTimeseries', '-png', '-r450')
% export_fig('outputs\ConcurrentTimeseries', '-eps')

%% Tidy up
clear YTicsChan YTicsWidth YTicsFlow YTicsLst PlotDates T5 T6 T7 T8 ...
    FigPos ChanSpacing range rangeFill scale LegChan ...
    LegWidth WidthH ChanH YLblChan YLblWidth YLblFlow YLblLst ...
    TPlotDates mdp LightBlue LevelH YTicsLevel YLblLevel LevelScale ...
    LevelOffset AxPos ax
