function Proportion = propDistLT(Position, WindowSize, ThresholdDist, ...
                                 MultiDim)
%PROPDISTLT Proportion of in-window points within ThresholdDist
%   Calculate the proportion of points within a moving window surrounding
%   each point which fall within ThresholdDist of that point.
%
%   Proportion = PROPDISTLT(Position, WindowSize, ThresholdDist)
%   
%   Inputs:
%      Position = NPoints x NDimensions mat of point positions
%      WindowSize = Size of moving window for analysis (typically odd-no)
%                   Window size refers to dimension 1 of input variable.
%      ThresholdDist = Threshold value of distance
%      MultiDim = Switch for how additional columns are handled:
%                    True  = distance is calculated in multiple dimensions
%                            size(Proportion) = [size(Position,1),1]
%                    False = treated as a group of individual points
%                            size(Proportion) = size(Position)
%                 Optional, default = true
%
%   Outputs:
%      Proportion = Proportion of points within a moving window surrounding
%                   each point which fall within ThresholdDist of that 
%                   point.

if ~exist('MultiDim','var') || isempty(MultiDim)
    MultiDim = true;
end

NoOfPoints = size(Position,1);
if MultiDim
    Proportion = nan(NoOfPoints,1);
    for PointNo = 1:NoOfPoints
        if any(isnan(Position(PointNo,:)))
            Proportion(PointNo) = 0;
        else
            ThisWindowPos = ...
                Position([max(1, PointNo-floor(WindowSize/2)):PointNo-1, ...
                          PointNo+1:min(end, PointNo+floor(WindowSize/2))], ...
                         :);
            SeperationDist = sqrt(sum((ThisWindowPos - repmat(Position(PointNo,:), size(ThisWindowPos,1),1)).^2,2));
            Proportion(PointNo) = ...
                sum(SeperationDist<ThresholdDist,'omitnan') / ...
                sum(~isnan(SeperationDist));
        end
    end
else
    NoOfCols = size(Position,2);
    Proportion = nan(NoOfPoints,NoOfCols);
    for PointNo = 1:NoOfPoints
        ThisWindowPos = ...
            Position([max(1, PointNo-floor(WindowSize/2)):PointNo-1, ...
                      PointNo+1:min(end, PointNo+floor(WindowSize/2))], ...
                     :);
        for ColNo = 1:NoOfCols
            if isnan(Position(PointNo,ColNo))
                Proportion(PointNo) = 0;
            else
                SeperationDist = min(abs(ThisWindowPos - Position(PointNo,ColNo)),[],2,'omitnan');
                Proportion(PointNo,ColNo) = ...
                    sum(SeperationDist<ThresholdDist,'omitnan') / ...
                    sum(~isnan(SeperationDist));
            end
        end
    end
end

end