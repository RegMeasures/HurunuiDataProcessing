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

Button = questdlg('Review previously digised images as well as ones which have not been digitised yet?', ...
                  'Review previous?','Yes','No','Yes');
if strcmp(Button,'No')
    TimeNoToProcess = find(cellfun(@isempty,ChannelPos.LinePx))';
else
    TimeNoToProcess = height(ChannelPos):-1:1;
end
for TimeNo = TimeNoToProcess
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
    Button = 'Delete';
    if ~isempty(ChannelPos.LinePx{TimeNo})
        hold on
        plot(ChannelPos.LinePx{TimeNo}(:,1),ChannelPos.LinePx{TimeNo}(:,2))
        Button = questdlg('Channel digitised', 'Channel digitised', ...
                              'Ok', 'Delete', 'Add another', 'Ok');
    end
    while ~strcmp(Button,'Ok')
        [LinePxX,LinePxY] = getline;
        if strcmp(Button,'Delete')
            ChannelPos.LinePx{TimeNo} = [LinePxX,LinePxY];
        elseif strcmp(Button,'Add another')
            ChannelPos.LinePx{TimeNo} = [ChannelPos.LinePx{TimeNo}; ...
                                         nan(1,2); ...
                                         LinePxX,LinePxY];
        end
        hold on
        plot(ChannelPos.LinePx{TimeNo}(:,1),ChannelPos.LinePx{TimeNo}(:,2))
        Button = questdlg('Channel digitised', 'Channel digitised', ...
                              'Ok', 'Delete', 'Add another', 'Ok');
    end
    close
    
    
    
    % convert to real world coordinates
    ChannelEasting = nan(size(ChannelPos.LinePx{TimeNo},1),1);
    ChannelNorthing = nan(size(ChannelPos.LinePx{TimeNo},1),1);
    
    Cam1Pts = ChannelPos.LinePx{TimeNo}(:,1) > Config.Cam2.Resolution(1);
    
    if sum(Cam1Pts)>0;
        [ChannelEasting(Cam1Pts), ChannelNorthing(Cam1Pts)] = ...
            ProjectToMap(Config.Cam1, WL, Twist, ChannelPos.LinePx{TimeNo}(Cam1Pts,2), ChannelPos.LinePx{TimeNo}(Cam1Pts,1) - Config.Cam2.Resolution(1));
    end
    if sum(~Cam1Pts)>0;
        [ChannelEasting(~Cam1Pts), ChannelNorthing(~Cam1Pts)] = ...
            ProjectToMap(Config.Cam2, WL, Twist, ChannelPos.LinePx{TimeNo}(~Cam1Pts,2), ChannelPos.LinePx{TimeNo}(~Cam1Pts,1));
    end
    
    
    ChannelPos.LineXY{TimeNo} = [ChannelEasting,ChannelNorthing];
    
%     ProjectToMap(Config.Cam1, WL, Twist, [],[], Cam1Image);
%     hold on
%     plot(ChannelEasting,ChannelNorthing,'r-x')

end

save('outputs\ChannelPos.mat','ChannelPos','-v7.3')

clear TimeNoToProcess Cam1Image Cam2Image WL Twist LinePxX LinePxY ...
    ChannelEasting ChannelNorthing Cam1Pts TimeNo Button

%% Calculate upstream and downstream offset alongshore

% upstream and downstream position
ChannelPos.UsPos = nan(size(ChannelPos,1),2,3);
ChannelPos.DsPos = nan(size(ChannelPos,1),2,3);
% note: dim1 = time, dim2 = outlet no (up to 3), dim3 = [X, Y]
EdgeTol = 50;
for TimeNo = 1:size(ChannelPos,1);
    % find start and end
    [StartCoords,EndCoords] = polylineEnds(ChannelPos.LineXY{TimeNo});
    % remove any start/ends which are in the blind spot
    StartCoords(ChannelPos.LinePx{TimeNo}(:,1) > Config.Cam2.Resolution(1) - EdgeTol & ...
                ChannelPos.LinePx{TimeNo}(:,1) < Config.Cam2.Resolution(1) + EdgeTol) = false;
    EndCoords(ChannelPos.LinePx{TimeNo}(:,1) > Config.Cam2.Resolution(1) - EdgeTol & ...
              ChannelPos.LinePx{TimeNo}(:,1) < Config.Cam2.Resolution(1) + EdgeTol) = false;

    % restrict to 3 points (for now)
    StartCoords = find(StartCoords,3);
    EndCoords = find(EndCoords,3);
    ChannelPos.UsPos(TimeNo,:,1:size(StartCoords,1)) = ...
        permute(ChannelPos.LineXY{TimeNo}(StartCoords,:),[3,2,1]);
    ChannelPos.DsPos(TimeNo,:,1:size(EndCoords,1)) = ...
        permute(ChannelPos.LineXY{TimeNo}(EndCoords,:),[3,2,1]);
%     if ~isempty(ChannelPos.LinePx{TimeNo})
%         % channel start position
% %         if ChannelPos.LinePx{TimeNo}(1,1) > Config.Cam2.Resolution(1) - EdgeTol && ...
% %                ChannelPos.LinePx{TimeNo}(1,1) < Config.Cam2.Resolution(1) + EdgeTol
%             % start is in the blind spot
%         ChannelPos.UsPos(TimeNo,:) = ChannelPos.LineXY{TimeNo}(1,:);
%         
%         % channel end position
%         if ~(ChannelPos.LinePx{TimeNo}(end,1) > Config.Cam2.Resolution(1) - EdgeTol && ...
%              ChannelPos.LinePx{TimeNo}(end,1) < Config.Cam2.Resolution(1) + EdgeTol)
%             % end is not in the blind spot
%             ChannelPos.DsPos(TimeNo,:) = ChannelPos.LineXY{TimeNo}(end,:);
%         end
%     end
end

% transformation inputs
RelShore = Config.Shoreline(2,:)-Config.Shoreline(1,:);
ShoreAng = atan(RelShore(2)/RelShore(1));

% upstream offset
PosRelative = ChannelPos.UsPos - repmat(Config.Shoreline(1,:),size(ChannelPos,1),1,3);
ChannelPos.UsOffset = permute(PosRelative(:,1,:) * cos(ShoreAng) + ...
                              PosRelative(:,2,:) * sin(ShoreAng), ...
                              [1,3,2]);

% downstream offset
PosRelative = ChannelPos.DsPos - repmat(Config.Shoreline(1,:),size(ChannelPos,1),1,3);
ChannelPos.DsOffset = permute(PosRelative(:,1,:) * cos(ShoreAng) + ...
                              PosRelative(:,2,:) * sin(ShoreAng), ...
                              [1,3,2]);
                              
save('outputs\ChannelPos.mat','ChannelPos','-v7.3')

clear  RelShore ShoreAng EdgeTol PosRelative ii StartCoords EndCoords

%% Plot
plot(repmat(ChannelPos.UniqueTime,[3,1]),[ChannelPos.UsOffset(:),ChannelPos.DsOffset(:)],'x')
legend({'Upstream end of outlet channel','Downstream end of outlet channel'})
ylabel('Alongshore distance (North positive) from river centreline (m)')
