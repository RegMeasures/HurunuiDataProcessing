function animatePhotos(VideoName, ...
                       PhotoFolder, PhotoDatabase, TimeMatchedPhotos, ...
                       LagoonTs, Framerate, DateOnly)
% ANIMATEPHOTOS   record timelapse movie of both cams + TS data plots
%   
%   ANIMATEPHOTOS(VideoName, ...
%                 PhotoFolder, PhotoDatabase, TimeMatchedPhotos, ...
%                 LagoonTs, WaveTs, ChannelTs, Framerate)
%
%   Inputs:
%       VideoName   = filename of video output
%       PhotoFolder = Main directory containing all images
%       PhotoDatabase = Table referencing photo details and locations in
%                     PhotoFolder (see genPhotoDatabase and photoQuality)
%       TimeMatchedPhotos = Table refencing photos associated with each
%                     timestep of video (see timeMatchPhotos)
%       LagoonTs    = Lagoon timeseries data 
%                     (optional, if not supplied no data is plotted, if 
%                     supplied but no wave or channel data then only level 
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
%   See also: GENPHOTODATABASE, PHOTOQUALITY, TIMEMATCHPHOTOS


%% Set defaults and plot options
PlotLevel = false;
PlotFlow = false;
PlotWave = false;
PlotChannel = false;
if exist('LagoonTs','var') || isempty(LagoonTs)
    PlotLevel = true;
    PlotFlow = true;
    if ismember('WaveHs', LagoonTs.Properties.VariableNames)
        PlotWave = true;
    end
    if ismember('ChannelL', LagoonTs.Properties.VariableNames)
        PlotChannel = true;
    end
end

if ~exist('Framerate','var') || isempty(Framerate)
    Framerate = 10;
end

if ~exist('DateOnly','var') || isempty(DateOnly)
    DateOnly = false;
end

%% generate flow plot ready to insert into movie
if PlotFlow
    FlowFig.FigureH = figure('Position',[100, 100, 648, 200],...
                             'Name','SH1 Flow');
    FlowFig.LineH = plot(LagoonTs.DateTime, LagoonTs.Qin, 'b-');
    FlowFig.AxesH = gca;
    hold on
    FlowFig.PointH = plot(LagoonTs.DateTime(end), LagoonTs.Qin(end), 'r.', 'MarkerSize',15);
    hold off
    ylabel('Flow at SH1 [m^3/s]')
    ylim([0,200])
    FlowFig.LabelH = text(70,130, ...
                          sprintf('%0.1fm^3/s', LagoonTs.Qin(end)),...
                          'units','pixels',...
                          'HorizontalAlignment','right');
else
    FlowPlot.cdata = 240 * ones(200, 648, 3, 'int8');
end

%% generate level plot ready to insert into movie
if PlotLevel
    LevelFig.FigureH = figure('Position',[100, 400, 648, 200],...
                             'Name','Lagoon level');
    LevelFig.LineH = plot(LagoonTs.DateTime, LagoonTs.WL, 'b-');
    LevelFig.AxesH = gca;
    hold on
    LevelFig.PointH = plot(LagoonTs.DateTime(end), LagoonTs.WL(end), 'r.', 'MarkerSize',15);
    hold off
    ylabel('Lagoon level [m]')
    ylim([0.5,3.5])
else
    LevelPlot.cdata = 240 * ones(200, 648, 3, 'int8');
end

%% generate wave height plot ready to insert into movie
if PlotWave
    WaveFig.FigureH = figure('Position',[100, 700, 648, 200],...
                             'Name','Significant wave height');
    WaveFig.LineH = plot(LagoonTs.DateTime, LagoonTs.WaveHs, 'b-');
    WaveFig.AxesH = gca;
    hold on
    WaveFig.PointH = plot(LagoonTs.DateTime(end), LagoonTs.WaveHs(end), 'r.', 'MarkerSize',15);
    hold off
    ylabel('Sig. wave height [m]')
    ylim([0,6])
else
    WavePlot.cdata = 240 * ones(200, 648, 3, 'int8');
end

%% generate channel plot ready to insert into movie
if PlotChannel
    ChannelFig.FigureH = figure('Position',[100, 400, 648, 200],...
                                'Name','Outlet Channel');
    ChannelFig.LineH = plot(LagoonTs.DateTime, LagoonTs.ChannelL, 'b-');
    ChannelFig.AxesH = gca;
    hold on
    ChannelFig.PointH = plot(LagoonTs.DateTime(end), LagoonTs.ChannelL(end), 'r.', 'MarkerSize',15);
    hold off
    ylabel('Outlet channel length [m]')
    ylim([0,500])
else
    ChannelPlot.cdata = 240 * ones(200, 648, 3, 'int8');
end

%% Loop through timesteps and write video

% create new instance of VideoWriter class
writerObj = VideoWriter(VideoName,'MPEG-4');

% set relevant properties
writerObj.FrameRate = Framerate;
writerObj.Quality = 85;

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
    if PlotFlow
        CurrentQ = interp1(LagoonTs.DateTime, LagoonTs.Qin, ...
                           TimeMatchedPhotos.UniqueTime(TimeNo));
        if verLessThan('Matlab','9.1')
            xlim(FlowFig.AxesH, ...
                 datenum(TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)]))
        else
            xlim(FlowFig.AxesH, ...
                 TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)])
        end
        datetick(FlowFig.AxesH,'x','ddmmm','keeplimits')
        set(FlowFig.PointH, ...
            'XData', datenum(TimeMatchedPhotos.UniqueTime(TimeNo)), ...
            'YData', CurrentQ)
        set(FlowFig.LabelH, ...
            'String', sprintf('%0.1fm^3/s', CurrentQ))
        FlowPlot = getframe(FlowFig.FigureH);
    end

    % prep level plot
    if PlotLevel
        CurrentWL = interp1(LagoonTs.DateTime, LagoonTs.WL, ...
                            TimeMatchedPhotos.UniqueTime(TimeNo));
        if verLessThan('Matlab','9.1')
            xlim(LevelFig.AxesH, ...
                 datenum(TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)]))
        else
            xlim(LevelFig.AxesH, ...
                 TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)])
        end
        datetick(LevelFig.AxesH,'x','ddmmm','keeplimits')
        set(LevelFig.PointH, ...
            'XData', datenum(TimeMatchedPhotos.UniqueTime(TimeNo)), ...
            'YData', CurrentWL)
        LevelPlot = getframe(LevelFig.FigureH);
    end

    % prep significant wave height plot
    if PlotWave
        CurrentHs = interp1(LagoonTs.DateTime, LagoonTs.WaveHs, ...
                            TimeMatchedPhotos.UniqueTime(TimeNo));
        if verLessThan('Matlab','9.1')
            xlim(WaveFig.AxesH, ...
                 datenum(TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)]))
        else
            xlim(WaveFig.AxesH, ...
                 TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)])
        end
        datetick(WaveFig.AxesH,'x','ddmmm','keeplimits')
        set(WaveFig.PointH, ...
            'XData', datenum(TimeMatchedPhotos.UniqueTime(TimeNo)), ...
            'YData', CurrentHs)
        WavePlot = getframe(WaveFig.FigureH);
    end

    % prep channel plot
    if PlotChannel
        CurrentChannelLength = interp1(LagoonTs.DateTime, LagoonTs.ChannelL, ...
                                       TimeMatchedPhotos.UniqueTime(TimeNo));
        if verLessThan('Matlab','9.1')
            xlim(ChannelFig.AxesH, ...
                 datenum(TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)]))
        else
            xlim(ChannelFig.AxesH, ...
                 datenum(TimeMatchedPhotos.UniqueTime(TimeNo) + [-days(21),days(7)]))
        end
        datetick(ChannelFig.AxesH,'x','ddmmm','keeplimits')
        set(ChannelFig.PointH, ...
            'XData', datenum(TimeMatchedPhotos.UniqueTime(TimeNo)), ...
            'YData', CurrentChannelLength)
        ChannelPlot = getframe(ChannelFig.FigureH);
    end

    % insert plots into frame
    if PlotFlow || PlotLevel
        frame = [frame; ...
                 FlowPlot.cdata, LevelPlot.cdata];
    end
    if PlotWave || PlotChannel
        frame = [frame; ...
                 WavePlot.cdata, ChannelPlot.cdata];
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
if PlotFlow
    close(FlowFig.FigureH)
end
if PlotWave
    close(WaveFig.FigureH)
end
if PlotChannel
    close(ChannelFig.FigureH)
end

