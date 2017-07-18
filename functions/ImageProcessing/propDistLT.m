function Proportion = propDistLT(Position, WindowSize, ThresholdDist)
%PROPDISTLT Proportion of in-window points within ThresholdDist
%   Calculate the proportion of points within a moving window surrounding
%   each point which fall within ThresholdDist of that point. Distance
%   between co-ordinates is calcluated with as many dimensions as supplied.
%
%   Proportion = PROPDISTLT(Position, WindowSize, ThresholdDist)
%   
%   Inputs:
%      Position = NPoints x NDimensions mat of point positions
%      WindowSize = Size of moving window for analysis (typically odd-no)
%      ThresholdDist = Threshold value of distance
%
%   Outputs:
%      Proportion = NPoints x 1 mat

NoOfPhotos = size(Position,1);
Proportion = nan(NoOfPhotos,1);

for ii = 1:NoOfPhotos
    ThisGroupPos = Position(max(1, ii-floor(WindowSize/2)):min(end, ii+floor(WindowSize/2)),:);
    SeperationDist = sqrt(sum((ThisGroupPos - repmat(Position(ii,:), size(ThisGroupPos,1),1)).^2,2));
    Proportion(ii) = (sum(SeperationDist<ThresholdDist)-1) / (sum(~isnan(SeperationDist))-1);
end

end