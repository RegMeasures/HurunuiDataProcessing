function [x2, y2] = cameraroll(x, y, Roll)
%CAMERAROLL correct pixel coordinates for the effect of camera roll angle
%
% Roll = roll angle of camera (clockwise, degrees)

% convert to polar coordinates
[theta,r] = cart2pol(x,y);

% adjust angle
theta2 = theta + pi * (Roll/180);

% convert back to cartesian coordinates
[x2,y2] = pol2cart(theta2,r);

end

