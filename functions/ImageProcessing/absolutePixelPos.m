function [NewPosition, ScalingFac] = absolutePixelPos(Position)
%ABSOLUTEPIXELPOS Generate a figure 'position' of exact pixel dimensions
%   This function is required because of differing screen resolutions. It
%   ensures that when you save or grab the figure's pixels (e.g. using 
%   saveas or getframe) you get the exact dimensions you want.
%   
%   [NewPosition, ScalingFac] = absolutePixelPos(Position)
%
%   Typical usage is:
%       H = figure('Position',absolutePixelPos(Position))
%       where Position is a 1x4 array of the form:
%       [Left edge X, Lower edge Y, Height in pixels, Width in pixels]
%   
%   See also: FIGURE, GETFRAME

% Use a test figure to find the scaling factor required
TestFig = figure('position', Position); 
Frame = getframe(TestFig); 
close(TestFig)
FrameSize(2) = size(Frame.cdata,1); 
FrameSize(1) = size(Frame.cdata,2); 
ScalingFac = Position([3:4]) ./ FrameSize;
NewPosition = Position .* ScalingFac([1,2,1,2]);

% TestFig = figure('position', NewPosition); 
% Frame = getframe(TestFig); 
% close(TestFig)
% FrameSize(1) = size(Frame.cdata,1); 
% FrameSize(2) = size(Frame.cdata,2);
end