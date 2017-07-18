function PropDistLT = propTwistDistLT(TwistX, TwistY, WindowSize, ThresholdDist)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

NoOfPhotos = size(TwistX,1);
PropDistLT = nan(NoOfPhotos,1);

for ii = 1:NoOfPhotos
    ThisGroupX = TwistX(max(1, ii-WindowSize/2):min(end, ii+WindowSize/2));
    ThisGroupY = TwistY(max(1, ii-WindowSize/2):min(end, ii+WindowSize/2));
    TwistDist = sqrt((ThisGroupX - TwistX(ii)).^2 + (ThisGroupY - TwistY(ii)).^2);
    PropDistLT(ii) = sum(TwistDist<ThresholdDist) / sum(~isnan(TwistDist));
end

end