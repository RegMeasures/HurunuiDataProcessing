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
s = r .* (1 + k(1) .* (r.^2) + k(2) .* (r.^3));
% b=0.8;
% s = r .* (tan(r.*b)./(r.*b));

% Remove normalisation
s2 = s * normfac;

% convert back to cartesian coordinates
[x2,y2] = pol2cart(theta,s2);

% additional rescaling to preserve width
ScaledMid = ((Resolution(1)-1)/2)/normfac;
ScaleFac = ScaledMid/(ScaledMid * (1 + k(1) .* (ScaledMid^2) + k(2) .* (ScaledMid^3)));
% ScaleFac = ScaledMid/(ScaledMid * (tan(ScaledMid*b)/(ScaledMid*b)));
x2=x2*ScaleFac;
y2=y2*ScaleFac;

end

