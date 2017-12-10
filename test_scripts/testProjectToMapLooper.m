function [Twist,WetBdy,Offsets] = testProjectToMapLooper(Config,TestImage1,TestImage2,WL,SurveyPoints)

% get screensize for plot setups
ScrSz = get(groot, 'ScreenSize');

% Measure pole twist
Twist = MeasureTwist1(TestImage1,Config.Cam1.k,Config.Cam1.Resolution,true);

% find wet edges
[WetMask1, WetBdy1] = WetDry2(TestImage1, Config.FgBgMask1, ...
                              Config.SeedPixel1, Twist, false);
[WetMask2, WetBdy2] = WetDry2(TestImage2, Config.FgBgMask2, ...
                              Config.SeedPixel2, [Twist(1),-Twist(2)], ...
                              false);

% convert WetBdys to easting northing
[BdyEasting1, BdyNorthing1] = ...
    ProjectToMap(Config.Cam1, WL, Twist, WetBdy1(:,1), WetBdy1(:,2));
[BdyEasting2, BdyNorthing2] = ...
    ProjectToMap(Config.Cam2, WL, [Twist(1),-Twist(2),-Twist(3)], ...
                 WetBdy2(:,1), WetBdy2(:,2));
WetBdy1 = [BdyEasting1, BdyNorthing1];
WetBdy2 = [BdyEasting2, BdyNorthing2];

% Remove backshore part of WetBdy polygon to leave polyline along barrier
WetBdy1 = cleanWetBdy(WetBdy1);
WetBdy2 = cleanWetBdy(WetBdy2);

% display projected image as surface
figure('Position', [(ScrSz(3)/2)-700, ScrSz(4)/2-300, 1400, 400]);
MapAx = plotProjected(TestImage1,Twist,WL,Config.Cam1,...
                      Config.FgBgMask1,[],true);
hold(MapAx,'on')
plotProjected(TestImage2,[Twist(1),-Twist(2),-Twist(3)],WL,Config.Cam2,...
              Config.FgBgMask2,MapAx,true);

% overlay surveyed waters edge
hold(MapAx,'on')
SurveyH = plot(MapAx,SurveyPoints(:,1), SurveyPoints(:,2), 'c-');
hold(MapAx,'off')

% calculate offsets along transects and add them and WetBdy to plot
WetBdy = [WetBdy1; ...
          nan(1,2); ...
          WetBdy2];
% Transects = m_shaperead('100mTransects_NZTM');
% Transects = Transects.ncst(23:39);
% Transects = cellfun(@flipud, Transects, 'UniformOutput', false);
hold(MapAx,'on')
[Offsets, OffsetsH] = measureOffsets(WetBdy,Config.Transects,true,MapAx);
hold(MapAx,'off')

% Tidy up the plot for export
view(MapAx,45,90)
xlim(MapAx,[1622800,1624300])
ylim(MapAx,[5248600,5250200])
set(MapAx,'Position',[-0.6 -2.1 2.2 5])
axis(MapAx,'off')
legend(MapAx, [SurveyH;OffsetsH([1,2,4])], ...
       {'Surveyed waters edge', ...
        'Image analysis waters edge', ...
        'Measurement transects', ...
        'Measured offset'}, ...
       'Position',[0.81 0.06 0.17 0.28], ...
       'FontSize',11)

end

