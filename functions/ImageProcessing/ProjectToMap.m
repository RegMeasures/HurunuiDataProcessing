function [PixelEasting, PixelNorthing] = ...
              ProjectToMap(Cam, WaterLevel, Twist, PixelRow, PixelCol, TestImage)
%PROJECTTOMAP   Convert image pixel positions to map coordinates
%   
%   [PixelEasting, PixelNorthing] = PROJECTTOMAP(Cam, WaterLevel, ...
%                                                PixelX, PixelY, TestImage)
%   Inputs:
%      Cam            = structure array with details of camera including:
%         .Resolution = 1 x 2 array, image size [px across, px down]
%         .Bearing    = Bearing of center of image [degrees]
%         .Pitch      = Pitch angle of image center (usually negative as 
%                       this indicates the image is angled down) [degrees]
%         .Roll       = Roll angle of camera (clockwise = +ve) [degrees]
%         .ViewWidth  = width of field of view [degrees]
%         .Height     = elevation of camera [m]
%         .Easting    = Easting of camera [m]
%         .Northing   = Northing of camera [m]
%         .k          = k value for barrel distortion correction
%      WaterLevel     = Lagoon Water level (mLVD)
%      Twist          = Horizontal and vertical displacement of image
%                       compared to reference image (see MeasureTwist1) 
%                       [px across, px down] (optional, default = [0,0]).
%      PixelRow, PixelCol = Matrices of locations corresponding to position
%                       in image from top left. (Optional: If not supplied
%                       a grid covering the full image is assumed)
%      TestImage      = image to project (optional). If supplied a figure
%                       is generated. If supplied PixelRow and PixelCol
%                       must cover full image.
%   
%   Outputs:
%      PixelEasting, PixelNorthing = Real world coordinates of locations
%                                    given in PixelX, PixelY
%   
%   Notes:
%   - Neglects curvature of the earth - not sure if this is significant
%     Assumes flat image plane perpendicular to center of image
%   - Need to supply raw image uncorrected for twist otherwise image
%     distortion correction does not work correctly.
%   
%   See also: RADIALDISTORT, MEASURETWIST1, CAMERAROLL.

%% Set defaults
% Twist
if ~exist('Twist','var')||isempty(Twist)
    Twist = [0,0];
end

% Create grid of pixel positions if not supplied
if ~exist('PixelRow','var')||isempty(PixelRow)
    [PixelCol, PixelRow] = meshgrid(1:Cam.Resolution(1),...
                                    1:Cam.Resolution(2));
end

%% Make Pixel Positions relative to image center
PixelX = PixelCol - (Cam.Resolution(1)+1)/2;
PixelY = - (PixelRow - (Cam.Resolution(2)+1)/2);
                        
%% Correct pixel positions for lens distortion
[PixelX, PixelY] = radialdistort(PixelX, PixelY, Cam.k, Cam.Resolution);

%% Correct pixel positions for roll
[PixelX, PixelY] = cameraroll(PixelX, PixelY, Cam.Roll);

%% Correct pixel positions for twist
PixelX = PixelX - Twist(1);
PixelY = PixelY - Twist(2);

%% Calculate position of each point in polar coordinates
ViewPlaneDist = (Cam.Resolution(1)/2) / tand(Cam.ViewWidth/2); %[m]
Bearing = Cam.Bearing + atand(PixelX / ViewPlaneDist) ;
Angle = Cam.Pitch + atand(PixelY / ViewPlaneDist);

%% Display distortion corrected image (optional, requires TestImage)
if exist('TestImage','var')
    figure
    surf(Bearing,Angle,zeros(size(Bearing)),TestImage,'EdgeColor',...
         'none','FaceColor','texturemap')
    hold on
    % horizon line
    HorizonAngle = -2.21*sqrt(Cam.Height)/60; %http://msi.nga.mil/MSISiteContent/StaticFiles/NAV_PUBS/APN/Chapt-22.pdf
    plot([min(min(Bearing)),max(max(Bearing))], ...
         [HorizonAngle,HorizonAngle], 'r:')
    view(2)
    axis equal
end

%% Calculate horizontal cartesian position of pixels
Angle(Angle>=0) = nan;
Distance = (Cam.Height - WaterLevel) ./ tand(-Angle);
Distance(Distance>1000) = nan;

PixelEasting = Cam.Easting + Distance .* sind(Bearing);
PixelNorthing = Cam.Northing + Distance .* cosd(Bearing);

end

