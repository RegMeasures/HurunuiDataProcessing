function [WetBdy] = cleanWetBdy(WetBdy)
%Remove lagoon backshore part of WetBdy
%   [WetBdy] = cleanWetBdy(WetBdy)

% Calculate approximate along shore position of each point
NE = WetBdy(:,1) + WetBdy(:,2);

% find maximum and minimum alonshore ponts
maxNE = find(NE==max(NE),1);
minNE = find(NE==min(NE),1);

% remove the backshore part of the WetBdy
% Note: outline is clockwise...
if maxNE>minNE
    % polygon start/end is on barrier
    WetBdy = WetBdy([maxNE:end,1:minNE],:);
else
    % polygon start/end is on lagoon backshore
    WetBdy = WetBdy([maxNE:minNE],:);
end
end

