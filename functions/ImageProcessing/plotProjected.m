function [AX] = plotProjected(RGBimage,Twist,WL,Cam,FgBgMask,AX)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% calculate pixel positions
[PixelX, PixelY] = ProjectToMap(Cam, WL, Twist, [], []);

% Mask image areas not required for plotting
PixelX(FgBgMask) = nan;
PixelY(FgBgMask) = nan;

% Create axis if not supplied
if ~exist('AX','var')
    AX = gca;
end

% display projected image as surface
Z = zeros(size(PixelX));
surf(AX,PixelX,PixelY,Z,RGBimage,'EdgeColor','none','FaceColor','texturemap')
view(2)
axis equal


end

