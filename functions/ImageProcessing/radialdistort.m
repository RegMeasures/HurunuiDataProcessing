function [x2, y2] = radialdistort(x, y, k, Resolution)
%RADIALDISTORT apply radial distortion to x,y coordinates of image pixels 
%
% Initially just use simplest radial distortion - can get more
% complicated later

% convert to polar coordinates
[theta,r] = cart2pol(x,y);

% Normalise distances to the range 0 to 1
normfac = sqrt(sum(((Resolution-1)/2).^2));
r = r/normfac;

% Apply distortion
s = r .* (1 + k .* (r.^2));

% Remove normalisation
s2 = s * normfac;

% convert back to cartesian coordinates
[x2,y2] = pol2cart(theta,s2);

% additional rescaling to preserve width
ScaledMid = ((Resolution(1)-1)/2)/normfac;
ScaleFac = ScaledMid/(ScaledMid * (1 + k .* (ScaledMid^2)));
x2=x2*ScaleFac;
y2=y2*ScaleFac;

end

