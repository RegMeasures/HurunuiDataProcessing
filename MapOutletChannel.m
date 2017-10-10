ChannelPos.LinePx = cell(size(StdTidePhotos,1),1);
ChannelPos.LineXY = cell(size(StdTidePhotos,1),1);
for TimeNo = 1:size(StdTidePhotos,1)
    % Get data for timestep
    Cam1Image = imread(fullfile(Config.DataFolder,Config.PhotoFolder, ...
                                Photos.FileSubDir{StdTidePhotos.Cam1Photo(TimeNo)}, ...
                                [Photos.FileName{StdTidePhotos.Cam1Photo(TimeNo)}, '.jpg']));
    Cam2Image = imread(fullfile(Config.DataFolder,Config.PhotoFolder, ...
                                Photos.FileSubDir{StdTidePhotos.Cam2Photo(TimeNo)}, ...
                                [Photos.FileName{StdTidePhotos.Cam2Photo(TimeNo)}, '.jpg']));
    WL = StdTidePhotos.LagoonLevel(TimeNo);
    Twist = StdTidePhotos.Twist(TimeNo,:);
    
    % manually digitise outlet channel
    figure
    imshow([Cam2Image,Cam1Image]);
    [LinePxX,LinePxY] = getline;
    close
    ChannelPos.LinePx{TimeNo} = [LinePxX,LinePxY];
    
    % convert to real world coordinates
    ChannelEasting = nan(size(LinePxX));
    ChannelNorthing = nan(size(LinePxY));
    
    Cam1Pts = LinePxX > Config.Cam2.Resolution(1);
    
    if sum(Cam1Pts)>0;
        [ChannelEasting(Cam1Pts), ChannelNorthing(Cam1Pts)] = ...
            ProjectToMap(Config.Cam1, WL, Twist, LinePxY(Cam1Pts), LinePxX(Cam1Pts) - Config.Cam2.Resolution(1));
    end
    if sum(~Cam1Pts)>0;
        [ChannelEasting(~Cam1Pts), ChannelNorthing(~Cam1Pts)] = ...
            ProjectToMap(Config.Cam2, WL, Twist, LinePxY(~Cam1Pts), LinePxX(~Cam1Pts));
    end
    
    ChannelPos.LineXY{TimeNo} = [ChannelEasting,ChannelNorthing];
    
%     ProjectToMap(Config.Cam1, WL, Twist, [],[], Cam1Image);
%     hold on
%     plot(ChannelEasting,ChannelNorthing,'r-x')

end
ChannelPos.UniqueTime = StdTidePhotos.UniqueTime;
ChannelPos = struct2table(ChannelPos);
save('outputs\ChannelPos.mat','ChannelPos','-v7.3')