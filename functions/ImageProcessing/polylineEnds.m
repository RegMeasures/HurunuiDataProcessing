function [StartIx,EndIx] = polylineEnds(polyline)
%POLYLINEENDS Return start and end points of multipart polyline
%   [StartCoords,EndCoords] = polylineEnds(polyline)
%   
%   All input variable is an array of positions e.g.
%      [x1 ,y1;
%       x2 ,y2;
%       ...
%       xn ,yn]
%   Any number of dimensions (i.e. columns) is allowed but only the first
%   dimension (column) is used for processing.
%
%   Outputs are boolean column vectors showing the location of start and
%   end points.
%
%   Individual parts of multi-part polylines are seperated by rows of nan
%   values.

% find start and end points of (potentially multipart) polyline
Gaps = isnan(polyline(:,1));
if ~isempty(polyline)
    StartIx = [true; Gaps(1:end-1)];
    EndIx = [Gaps(2:end); true];
    % check for double nan seperators or nan values at start/end
    StartIx(Gaps) = false;
    EndIx(Gaps) = false;
else
    StartIx = false(0,1);
    EndIx = false(0,1);
end


