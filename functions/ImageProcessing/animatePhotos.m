function animatePhotos(VideoName, ...
                       PhotoFolder, PhotoDatabase, TimeMatchedPhotos, ...
                       Config, LagoonTs, Framerate, DateOnly)
% ANIMATEPHOTOS   record timelapse movie of both cams + TS data plots
%   
%   ANIMATEPHOTOS(VideoName, ...
%                 PhotoFolder, PhotoDatabase, TimeMatchedPhotos, ...
%                 Config, LagoonTs, Framerate, DateOnly)
%
%   Inputs:
%       VideoName   = filename of video output
%       PhotoFolder = Main directory containing all images
%       PhotoDatabase = Table referencing photo details and locations in
%                     PhotoFolder (see genPhotoDatabase and photoQuality)
%       TimeMatchedPhotos = Table refencing photos associated with each
%                     timestep of video (see timeMatchPhotos)
%       Config      = Configuration inputs from HurunuiAnalysisConfig
%       LagoonTs    = Lagoon timeseries data 
%                     (optional, if not supplied no data is plotted, if 
%                     supplied but no wave or LST data then only level 
%                     and flow are plotted)
%       Framerate   = frames per second for outupt video 
%                     (optional, default=10)
%       DateOnly    = boolean: true  = display date only
%                              false = display date and time
%
%   Notes: 
%     - Size locked for 1944x2592 but shouldn't be a problems as
%       this is the camera high res size
%
%   See also: GENPHOTODATABASE, PHOTOQUALITY, TIMEMATCHPHOTOS, 
%             HURUNUIANALYSISCONFIG


%% Set defaults and plot options
PlotLevel = false;
PlotTide = false;
PlotQin = false;
PlotQout = false;
PlotWave = false;
PlotLST = false;
if exist('LagoonTs','var') || isempty(LagoonTs)
    PlotLevel = true;
    PlotQin = true;
    if ismember('Qout', LagoonTs.Properties.VariableNames)
        %PlotQout = true;
    end
    if ismember('SeaLevel', LagoonTs.Properties.VariableNames)
        PlotTide = true;
    end
    if ismember('R_high2', LagoonTs.Properties.VariableNames)
        PlotWave = true;
    end
    if ismember('LST', LagoonTs.Properties.VariableNames)
        PlotLST = true;
    end
end

if ~exist('Framerate','var') || isempty(Framerate)
    Framerate = 10;
end

if ~exist('DateOnly','var') || isempty(DateOnly)
    DateOnly = false;
end

%% generate flow plot ready to insert into movie
if PlotQin
    FlowFig.FigureH = figure('Position',absolutePixelPos([100, 100, 648, 200]),...
                             'Name','SH1 Flow');
    FlowFig.LineH = plot(LagoonTs.DateTime, LagoonTs.Qin, 'b-');
    FlowFig.AxesH = gca;
    hold on
%     FlowFig.PointH = plot(FlowFig.AxesH, LagoonTs.DateTime(end), ...
%                           LagoonTs.Qin(end), 'b.', 'MarkerSize',15);
    if PlotQout
        FlowFig.QoutLineH = plot(FlowFig.AxesH, LagoonTs.DateTime, ...
                                 LagoonTs.Qout, 'c-');
%         FlowFig.QoutPointH = plot(FlowFig.AxesH, LagoonTs.DateTime(end), ...
%                                   LagoonTs.Qout(end), 'c.', 'MarkerSize',15);
        FlowFig.TimeLineH = plot(LagoonTs.DateTime([1,1]),[0,200],'k-');
        legend([FlowFig.LineH,FlowFig.QoutLineH], ...
               {'River flow','Lagoon outflow'}, ...
               'Location', 'NorthWest')
%         legend('boxoff')
%         [~, ScalingFac] = absolutePixelPos([0,0,145,135]);
%         FlowFig.LabelH = text(145 * ScalingFac(1), 135 * ScalingFac(2), ...
%                               sprintf('= %0.0f m^3/s\n= %0.0f m^3/s', ...
%                                       LagoonTs.Qin(end), LagoonTs.Qout(end)),...
%                               'units','pixels',...
%                               'HorizontalAlignment','left', ...
%                               'FontSize', 9);
    else
%         FlowFig.LabelH = text(70 * ScalingFac(1), 135 * ScalingFac(2), ...
%                               sprintf('River flow = %0.0f m^3/s', ...
%                                       LagoonTs.Qin(end)),...
%                               'units','pixels',...
%                               'HorizontalAlignment','left', ...
%                               'FontSize', 9);
    end
    hold off
    ylabel('Flow (m^3/s)')
    ylim([0,200])
    Pos = get(FlowFig.AxesH, 'Position');
    set(FlowFig.AxesH, 'Position', [0.1, Pos(2), 0.87, Pos(4)])
else
    FlowPlot.cdata = 255 * ones(200, 648, 3, 'int8');
end

%% generate level plot ready to insert into movie
if PlotLevel
    if ~PlotLST || ~PlotQin
        LevelFig.FigureH = figure('Position',absolutePixelPos([100, 400, 648, 200]),...
                                  'Name','Lagoon level');
    else
        % if we're plotting LST and flow data then make level plot bigger
        LevelFig.FigureH = figure('Position',absolutePixelPos([100, 400, 648, 400]),...
                                  'Name','Lagoon level');
    end
    LevelFig.LineH = area(LagoonTs.DateTime, LagoonTs.WL, -1, ...
                          'FaceColor', 'blue');
    LevelFig.AxesH = gca;
    hold on
    ylim([0.5,3.5])
    ylabel('Water level (m)')
    LevLegText = {'Lagoon level'};
    LevLegObj = [LevelFig.LineH];
                       
    if PlotTide
        % Add in tide plot
        LevelFig.TideLineH = area(LevelFig.AxesH, LagoonTs.DateTime, ...
                                  LagoonTs.SeaLevel, -1, ...
                                  'FaceColor', [47/256, 141/256, 245/256]);
        LevLegText{end+1} = 'Sea level';
        LevLegObj(end+1) = [LevelFig.TideLineH];
        ylim([-1.0,3.5])
    end
    if PlotWave
        LevelFig.WaveLineH = area(LevelFig.AxesH, LagoonTs.DateTime, ...
                                  LagoonTs.R_high2, -1, ...
                                  'LineStyle', 'none', 'FaceColor', 'red');
        LevLegText{end+1} = 'Max wave runup';
        LevLegObj(end+1) = [LevelFig.WaveLineH];
        ylim([-1.0,5])
        LevelFig.PatchH = fill([LagoonTs.DateTime(1), LagoonTs.DateTime(end), ...
                                LagoonTs.DateTime(end), LagoonTs.DateTime(1)], ...
                               [Config.CrestHeight(1), Config.CrestHeight(1), ...
                                Config.CrestHeight(2), Config.CrestHeight(2)], ...
                               [0.9,0.9,0.9], ...
                               'EdgeColor', 'none');
        uistack(LevelFig.WaveLineH, 'bottom')
        uistack(LevelFig.PatchH, 'bottom')
    end
    LevelFig.TimeLineH = plot(LagoonTs.DateTime([1,1]),[-1.0,5],'k-');
    legend(LevLegObj, LevLegText, 'Location', 'NorthWest')
    Pos = get(LevelFig.AxesH, 'Position');
    set(LevelFig.AxesH, 'Position', [0.1, Pos(2), 0.87, Pos(4)])
    hold off
else
    if PlotLST || ~PlotWave
        LevelPlot.cdata = 255 * ones(200, 648, 3, 'int8');
    else
        LevelPlot.cdata = 255 * ones(400, 648, 3, 'int8');
    end
end

%% generate LST plot ready to insert into movie
if PlotLST
    LstPos = LagoonTs.LST;
    LstNeg = LagoonTs.LST;
    LstPos(LstPos<0) = nan;
    LstNeg(LstNeg>0) = nan;
    LSTFig.FigureH = figure('Position',absolutePixelPos([100, 400, 648, 200]),...
                            'Name','LST');
    LSTFig.AxisLineH = plot([LagoonTs.DateTime(1), LagoonTs.DateTime(end)], ...
                            [0,0], 'Color', [0.7,0.7,0.7]);
    LSTFig.AxesH = gca;
    hold on
    LSTFig.LineH = plot(LSTFig.AxesH, LagoonTs.DateTime, ...
                        LagoonTs.LST*60*60, 'k-');
    LSTFig.PosLineH = plot(LSTFig.AxesH, LagoonTs.DateTime, ...
                           LstPos*60*60, 'b-');
    LSTFig.NegLineH = plot(LSTFig.AxesH, LagoonTs.DateTime, ...
                           LstNeg*60*60, 'r-');
    LSTFig.TimeLineH = plot(LSTFig.AxesH, LagoonTs.DateTime([1,1]), ...
                            [-15,20],'k-');
    hold off
    ylabel('Longshore transport (m^3/hr)')
    ylim([-15,20])
    Pos = get(LSTFig.AxesH, 'Position');
    set(LSTFig.AxesH, 'Position', [0.1, Pos(2), 0.87, Pos(4)])
end

%% Loop through timesteps and write video

% create new instance of VideoWriter class
writerObj = VideoWriter(VideoName,'MPEG-4');

% set relevant properties
writerObj.FrameRate = Framerate;
writerObj.Quality = 70;

% open ready for writing to
open(writerObj);

% loop through timesteps
NoOfFrames = size(TimeMatchedPhotos.UniqueTime,1);
for TimeNo = 1:1:NoOfFrames
    fprintf('animating timestep number %i of %i\n', TimeNo, NoOfFrames);
        
    % load the images
    if isnan(TimeMatchedPhotos.Cam1Photo(TimeNo))
        Cam1Image = zeros(1944,2592,3);
    else
        Cam1Image = imread(fullfile(PhotoFolder, ...
                                    PhotoDatabase.FileSubDir{TimeMatchedPhotos.Cam1Photo(TimeNo)}, ...
                                    [PhotoDatabase.FileName{TimeMatchedPhotos.Cam1Photo(TimeNo)}, '.jpg']));
    end
    if isnan(TimeMatchedPhotos.Cam2Photo(TimeNo))
        Cam2Image = zeros(1944,2592,3);
    else
        Cam2Image = imread(fullfile(PhotoFolder, ...
                                    PhotoDatabase.FileSubDir{TimeMatchedPhotos.Cam2Photo(TimeNo)}, ...
                                    [PhotoDatabase.FileName{TimeMatchedPhotos.Cam2Photo(TimeNo)}, '.jpg']));
    end

    % combine into 1 frame
    frame = [Cam2Image, zeros(1944, 4, 3), Cam1Image];

    % crop the image fractionally
    %frame = imcrop(frame, [3,25,5183,1895]);
    frame = frame(25:1920,3:5186,:);

    % reduce the resolution of the image
    % frame = imresize(frame,0.25);
    frame = frame(2:4:end-2,2:4:end-2,:);
    

    % insert timestamp
    if DateOnly
        timestamp = 255 * text2im(datestr(TimeMatchedPhotos.UniqueTime(TimeNo),'dd/mm/yyyy'));
        frame(1:20,558:737,:) = repmat(timestamp,[1,1,3]);
    else
        timestamp = 255 * text2im(datestr(TimeMatchedPhotos.UniqueTime(TimeNo),'dd/mm/yyyy HH:MM:SS'));
        frame(1:20,477:818,:) = repmat(timestamp,[1,1,3]);
    end

    % prep flow plot
    if PlotQin
        xlim(FlowFig.AxesH, ...
             TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)])
        datetick(FlowFig.AxesH,'x','ddmmm','keeplimits')
        if PlotQout
            set(FlowFig.TimeLineH, ...
                'XData', TimeMatchedPhotos.UniqueTime([TimeNo,TimeNo]));
        end
        FlowPlot = getframe(FlowFig.FigureH);
    end

    % prep level plot
    if PlotLevel
        xlim(LevelFig.AxesH, ...
             TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)])
        datetick(LevelFig.AxesH,'x','ddmmm','keeplimits')
        set(LevelFig.TimeLineH, ...
            'XData', TimeMatchedPhotos.UniqueTime([TimeNo,TimeNo]));
        LevelPlot = getframe(LevelFig.FigureH);
    end

    % prep LST plot
    if PlotLST
        xlim(LSTFig.AxesH, ...
             TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)])
        datetick(LSTFig.AxesH,'x','ddmmm','keeplimits')
        set(LSTFig.TimeLineH, ...
            'XData', TimeMatchedPhotos.UniqueTime([TimeNo,TimeNo]));
        LSTPlot = getframe(LSTFig.FigureH);
    end

    % insert plots into frame
    if PlotQin && PlotLST
        if PlotLevel
            frame = [frame; ...
                     [FlowPlot.cdata; LSTPlot.cdata], LevelPlot.cdata];
        else
            frame = [frame; ...
                     FlowPlot.cdata, LSTPlot.cdata];
        end
    elseif PlotQin
        frame = [frame; ...
                 FlowPlot.cdata, LevelPlot.cdata];
    elseif PlotLST || PlotLevel
        frame = [frame; ...
                 LSTPlot.cdata, LevelPlot.cdata];
    end

    % write out the frame
    writeVideo(writerObj,frame);
end

% close file
close(writerObj);

% close plots
if PlotLevel
    close(LevelFig.FigureH)
end
if PlotQin
    close(FlowFig.FigureH)
end
if PlotLST
    close(LSTFig.FigureH)
end

