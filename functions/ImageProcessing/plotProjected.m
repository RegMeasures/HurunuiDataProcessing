function [AX] = plotProjected(RGBimage,Twist,WL,Cam,FgBgMask,AX,DiagPlot)
%Color surf plot of projected camera image
%   AX = plotProjected(RGBimage,Twist,WL,Cam,FgBgMask,AX,testimage)
%   AX input and output are optional.
%   DiagPlot is optional boolean (default = false)

if ~exist('DiagPlot','var') || isempty(DiagPlot)
    DiagPlot = false;
end

% Create axis if not supplied
if ~exist('AX','var') || isempty(AX)
    AX = gca;
end

% calculate pixel positions
if DiagPlot
    [PixelX, PixelY] = ProjectToMap(Cam, WL, Twist, [], [], RGBimage);
else
    [PixelX, PixelY] = ProjectToMap(Cam, WL, Twist, [], []);
end

% Mask image areas not required for plotting
PixelX(FgBgMask) = nan;
PixelY(FgBgMask) = nan;

% display projected image as surface
Z = zeros(size(PixelX));
surf(AX,PixelX,PixelY,Z,RGBimage,'EdgeColor','none','FaceColor','texturemap')
view(AX,0,90)
axis(AX,'image')


end

