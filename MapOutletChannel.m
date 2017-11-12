%% Setup

% Add required directories (and subdirectories)
addpath(genpath('functions'))
addpath(genpath('inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% Get list of photos to process
load('outputs\PhotoDatabase.mat')
load('outputs\StdTidePhotos.mat')

%% Digitise outlet channel position

ChannelPos.UniqueTime = StdTidePhotos.UniqueTime;
ChannelPos.LinePx = cell(size(StdTidePhotos,1),1); % Pixel position
ChannelPos.LineXY = cell(size(StdTidePhotos,1),1); % Real world coordinates position
ChannelPos = struct2table(ChannelPos);

% Have some photos already been digitised? If so then import
if exist('outputs\ChannelPos.mat','file')
    OldChannelPos = load('outputs\ChannelPos.mat');
    OldChannelPos = OldChannelPos.ChannelPos;
    % find matching data
    [~,IA,IB] = intersect(OldChannelPos.UniqueTime, ...
                          ChannelPos.UniqueTime,'stable');
    ChannelPos(IB,:) = OldChannelPos(IA,{'UniqueTime','LinePx','LineXY'});
    clear OldChannelPos IA IB
end

TimeNoToProcess = find(cellfun(@isempty,ChannelPos.LinePx));
for TimeNo = TimeNoToProcess'
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
    if ~isempty(ChannelPos.LinePx{TimeNo})
        hold on
        plot(ChannelPos.LinePx{TimeNo}(:,1),ChannelPos.LinePx{TimeNo}(:,2))
    end
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

save('outputs\ChannelPos.mat','ChannelPos','-v7.3')

clear TimeNoToProcess Cam1Image Cam2Image WL Twist LinePxX LinePxY ...
    ChannelEasting ChannelNorthing Cam1Pts TimeNo

%% Calculate upstream and downstream offset alongshore

% upstream and downstream position
ChannelPos.UsPos = nan(size(ChannelPos,1),2);
ChannelPos.DsPos = nan(size(ChannelPos,1),2);
EdgeTol = 50;
for TimeNo = 1:size(ChannelPos,1);
    if ~isempty(ChannelPos.LinePx{TimeNo})
        % channel start position
%         if ChannelPos.LinePx{TimeNo}(1,1) > Config.Cam2.Resolution(1) - EdgeTol && ...
%                ChannelPos.LinePx{TimeNo}(1,1) < Config.Cam2.Resolution(1) + EdgeTol
            % start is in the blind spot
        ChannelPos.UsPos(TimeNo,:) = ChannelPos.LineXY{TimeNo}(1,:);
        
        % channel end position
        if ~(ChannelPos.LinePx{TimeNo}(end,1) > Config.Cam2.Resolution(1) - EdgeTol && ...
             ChannelPos.LinePx{TimeNo}(end,1) < Config.Cam2.Resolution(1) + EdgeTol)
            % end is not in the blind spot
            ChannelPos.DsPos(TimeNo,:) = ChannelPos.LineXY{TimeNo}(end,:);
        end
    end
end

% transformation inputs
RelShore = Config.Shoreline(2,:)-Config.Shoreline(1,:);
ShoreAng = atan(RelShore(2)/RelShore(1));

% upstream offset
PosRelative = ChannelPos.UsPos - repmat(Config.Shoreline(1,:),size(ChannelPos,1),1);
ChannelPos.UsOffset = PosRelative(:,1) * cos(ShoreAng) + ...
                          PosRelative(:,2) * sin(ShoreAng);

% downstream offset
PosRelative = ChannelPos.DsPos - repmat(Config.Shoreline(1,:),size(ChannelPos,1),1);
ChannelPos.DsOffset = PosRelative(:,1) * cos(ShoreAng) + ...
                          PosRelative(:,2) * sin(ShoreAng);
                      
save('outputs\ChannelPos.mat','ChannelPos','-v7.3')

clear  RelShore ShoreAng EdgeTol PosRelative ii

%% Plot
plot(ChannelPos.UniqueTime,[ChannelPos.UsOffset,ChannelPos.DsOffset],'x')
legend({'Upstream end of outlet channel','Downstream end of outlet channel'})
ylabel('Alongshore distance (North positive) from river centreline (m)')
