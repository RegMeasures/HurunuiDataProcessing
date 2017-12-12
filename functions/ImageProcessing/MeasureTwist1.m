function [Twist,Edge] = MeasureTwist1(RGBimage,k,Resolution,dispPlots)
%MEASURETWIST1   identify cliff edge in cam1 to inform pole twist correction
%   
%   [Twist,Edge] = MEASURESTWIST1(RGBimage,test)
%   
%   Inputs:
%      RGBimage  = Cam1 image i.e. imread('Hurunui1_*.jpg')
%      k         = k value for barrel distortion correction as used for 
%                  lensdistort
%      Resolution= Image size [width, height] (pixels)
%      dispPlots = boolean, true = show plots (optional, default = false)
%   Outputs:
%      Twist     = diff in edge position of cliff to calibration image
%                  [px across, px down]
%      Edge      = optional output, absolute cliff edge position in pixels
%                  from LHside of image.
%                  [H_Edge,V_Edge]
%
%   See also: MeasureTwist2

% set default dispPlots if not supplied 
% (default is not to display diagnistics)
if ~exist('dispPlots','var') || isempty(dispPlots)
    dispPlots = false;
end

%% fixed inputs

% Edge position corresponding to Twist = 0 [px] 
% note: these are based on Hurunui1_15-10-07_15-28-48-75.jpg
H_CalibEdge = 2329; %2335;
V_CalibEdge = 153;
V2_CalibEdge = 113;

% horizontal (cliff) search params
H_XPixelMin = 2000; % horizontal search range for cliff edge [px]
H_XPixelMax = 2450;
H_YPixel = 550;     % vert coord of horiz search line for cliff edge [px]
H_YBand = 20;        % search band thickness for cliff edge search [px]
H_dSVthresh = 2e-4;% initial dHSV threshold
H_FilterRadius = 5;

% RH vertical (horizon) search parameters
V_XPixel     = 2471;
V_YPixelMin  = 100;
V_YPixelMax  = 200;
V_XBand      = 20;
V_FilterRadius = 5;
V_dGrayThresh = 5;

% LH vertical (horizon) search parameters
V2_XPixel     = 300;
V2_YPixelMin  = 85;
V2_YPixelMax  = 145;
V2_XBand      = 20;
V2_FilterRadius = 5;
V2_dGrayThresh = 5;

% secondary/fine search parameters
%FineSearchMin = 0; 
FineSearchMax = +5;

%% identify cliff edge
H_Edge = findCliff(RGBimage, H_YPixel, H_YBand, H_XPixelMin, ...
                             H_XPixelMax, H_dSVthresh, H_FilterRadius, ...
                             FineSearchMax);
if isnan(H_Edge)
    Twist = nan(1,3);
    Edge = nan(1,2);
    return
end
% initial twist calculation with no accounting for lens distortion
H_Twist = H_Edge - H_CalibEdge;

%% identify horizon edge
V_Edge = findHorizon(RGBimage, V_XPixel + H_Twist, V_XBand, ...
                               V_YPixelMin,V_YPixelMax, V_FilterRadius);

% Original twist calculation with no accounting for lens distortion
V_Twist =  V_Edge - V_CalibEdge;

%% update cliff edge calc
H_Edge = findCliff(RGBimage, H_YPixel + V_Twist, H_YBand, H_XPixelMin, ...
                             H_XPixelMax, H_dSVthresh, H_FilterRadius, ...
                             FineSearchMax);

% initial twist calculation with no accounting for lens distortion
H_Twist = H_Edge - H_CalibEdge;

%% update horizon edge calc
V_Edge = findHorizon(RGBimage, V_XPixel + H_Twist, V_XBand, ...
                               V_YPixelMin,V_YPixelMax, V_FilterRadius);

% Original twist calculation with no accounting for lens distortion
V_Twist =  V_Edge - V_CalibEdge;

%% LH horizon edge for roll
V2_Edge = findHorizon(RGBimage, V2_XPixel, V2_XBand, ...
                                V2_YPixelMin,V2_YPixelMax, V2_FilterRadius);

%% Calculate Twist accounting for lens distortion

% horizontal
[H_CalibEdge2, ~] = radialdistort(H_CalibEdge - (Resolution(1)+1)/2, ...
                                  (Resolution(2)+1)/2 - (H_YPixel), ...
                                  k, Resolution);
[H_Edge2, H_Y2] = radialdistort(H_Edge - (Resolution(1)+1)/2, ...
                             (Resolution(2)+1)/2 - (H_YPixel + V_Twist), ...
                             k, Resolution);
H_Twist2 = H_Edge2 - H_CalibEdge2;

% vertical
[V_CalibX2, V_CalibEdge2] = radialdistort(V_XPixel - (Resolution(1)+1)/2, ...
                                  (Resolution(2)+1)/2 - V_CalibEdge, ...
                                  k, Resolution);
[V_X2, V_Edge2] = radialdistort(V_XPixel + H_Twist - (Resolution(1)+1)/2, ...
                             (Resolution(2)+1)/2 - V_Edge, ...
                             k, Resolution);
V_Twist2 =  V_Edge2 - V_CalibEdge2; 
% Note the sign convention of V_Twist2 has been flipped relative to V_Twist 
% as we are now working in XY space rather than row-col space.
% Sign convention is now correct for output.

% roll (clockwise positive)
[V2_CalibX2, V2_CalibEdge2] = radialdistort(V2_XPixel - (Resolution(1)+1)/2, ...
                                  (Resolution(2)+1)/2 - V2_CalibEdge, ...
                                  k, Resolution);
[V2_X2, V2_Edge2] = radialdistort(V2_XPixel - (Resolution(1)+1)/2, ...
                                  (Resolution(2)+1)/2 - V2_Edge, ...
                                  k, Resolution);
RollAngleCalib = atand((V2_CalibEdge2 - V_CalibEdge2) / ...
                       (V_CalibX2 - V2_CalibX2));
RollAngleMeas = atand((V2_Edge2 - V_Edge2) / ...
                      (V_X2 - V2_X2));
Roll = RollAngleMeas - RollAngleCalib;

% Adjust V_Twist2 for roll (i.e. vertical twist at image center)
V_Twist2 = round(V_Twist2 - ...
                 (sqrt(V_X2^2 + V_Edge2^2) * ...
                  sind(atand(V_Edge2/V_X2) - Roll) - V_Edge2));

% Adjust H_Twist2 for roll
H_Twist2 = round(H_Twist2 - ...
                 (sqrt(H_Edge2^2 + H_Y2^2) * ...
                  cosd(atand(H_Y2/H_Edge2) - Roll) - H_Edge2));

% Assemble final outputs
Edge = [H_Edge,V_Edge];
%Twist = [H_Twist,V_Twist];
Twist = [H_Twist2,V_Twist2,Roll];

%% Test plots
if dispPlots
    
    % cliff ID plots
    
%     figure
%     imshow(RGBimage(H_YPixel-H_YBand-50:H_YPixel+H_YBand+50,H_XPixelMin-50:H_XPixelMax+50,:))
%     hold on
%     plot([50,H_XPixelMax-H_XPixelMin+51],[51+H_YBand,51+H_YBand],'r-')
%     plot([50,H_XPixelMax-H_XPixelMin+51],[50,50],'r:')
%     plot([50,H_XPixelMax-H_XPixelMin+51],[51+2*H_YBand,51+2*H_YBand],'r:')
%     plot([H_Edge-(H_XPixelMin-50),H_Edge-(H_XPixelMin-50)],[10,91+2*H_YBand],'r-')
%     hold off
%     
%     figure
%     plot(HSVclip(:,1))
%     hold on
%     plot(HSVclip(:,2))
%     plot(HSVclip(:,3)/300)
%     legend({'H','S','V/300'})
%     plot([H_Edge-H_XPixelMin,H_Edge-H_XPixelMin],[0,1],'k:')
% 
%     figure
%     plot(dSV)
%     legend('dSV')
%     hold on
%     plot([0,H_XPixelMax-H_XPixelMin+1],[H_dSVthresh,H_dSVthresh],'k:')
%     plot([H_Edge-H_XPixelMin,H_Edge-H_XPixelMin],[0,max(dSV)],'k:')
    
    % Horizon ID plots
    
    % figure
    % imshow(RGBimage(V_YPixelMin-50:V_YPixelMax+50,V_XPixel+H_Twist-V_XBand-50:V_XPixel+H_Twist+V_XBand+50,:))
    % hold on
    % plot([51+V_XBand,51+V_XBand],[50,V_YPixelMax-V_YPixelMin+51],'r-')
    % plot([50,50],[50,V_YPixelMax-V_YPixelMin+51],'r:')
    % plot([51+2*V_XBand,51+2*V_XBand],[50,V_YPixelMax-V_YPixelMin+51],'r:')
    % plot([10,91+2*V_XBand],[V_Edge-(V_YPixelMin-50),V_Edge-(V_YPixelMin-50)],'r-')
    % hold off

    % figure
    % plot(dGray,length(dGray):-1:1)
    % hold on
    % plot([V_dGrayThresh,V_dGrayThresh],[0,length(dGray)],'k:')
    % plot([0,max(dGray)],[100-(V_Edge-V_YPixelMin),100-(V_Edge-V_YPixelMin)],'k:')
    
    % Overall plot
    figure
    imshow(RGBimage)
    hold on
    % cliff
    plot([H_XPixelMin,H_XPixelMax],[H_YPixel+V_Twist,H_YPixel+V_Twist],'r-')
    plot([H_XPixelMin,H_XPixelMax],[H_YPixel+V_Twist-H_YBand,H_YPixel+V_Twist-H_YBand],'r:')
    plot([H_XPixelMin,H_XPixelMax],[H_YPixel+V_Twist+H_YBand,H_YPixel+V_Twist+H_YBand],'r:')
    plot([H_Edge,H_Edge],[H_YPixel+V_Twist-40,H_YPixel+V_Twist+40],'g-')
    plot([H_CalibEdge,H_CalibEdge],[H_YPixel+V_Twist-40,H_YPixel+V_Twist+40],'r-')
    % horizon
    plot([V_XPixel+H_Twist,V_XPixel+H_Twist],[V_YPixelMin,V_YPixelMax],'r-')
    plot([V_XPixel+H_Twist-V_XBand,V_XPixel+H_Twist-V_XBand],[V_YPixelMin,V_YPixelMax],'r:')
    plot([V_XPixel+H_Twist+V_XBand,V_XPixel+H_Twist+V_XBand],[V_YPixelMin,V_YPixelMax],'r:')
    plot([V_XPixel+H_Twist-40,V_XPixel+H_Twist+40],[V_Edge,V_Edge],'g-')
    plot([V_XPixel+H_Twist-40,V_XPixel+H_Twist+40],[V_CalibEdge,V_CalibEdge],'r-')
    % horizon 2
    plot([V2_XPixel,V2_XPixel],[V2_YPixelMin,V2_YPixelMax],'r-')
    plot([V2_XPixel-V2_XBand,V2_XPixel-V2_XBand],[V2_YPixelMin,V2_YPixelMax],'r:')
    plot([V2_XPixel+V2_XBand,V2_XPixel+V2_XBand],[V2_YPixelMin,V2_YPixelMax],'r:')
    plot([V2_XPixel-40,V2_XPixel+40],[V2_Edge,V2_Edge],'g-')
    plot([V2_XPixel-40,V2_XPixel+40],[V2_CalibEdge,V2_CalibEdge],'r-')
    
%     % undistorted:
%     % Create grid of pixel positions
%     [PixelCol, PixelRow] = meshgrid(1:Resolution(1),1:Resolution(2));
%     % Make Pixel Positions relative to image center
%     PixelX = PixelCol - (Resolution(1)+1)/2;
%     PixelY = - (PixelRow - (Resolution(2)+1)/2);
%     % Correct pixel positions for lens distortion
%     [PixelX, PixelY] = radialdistort(PixelX, PixelY, k, Resolution);
%     % plot
%     figure
%     surf(PixelX, PixelY, zeros(size(PixelX)),RGBimage,'EdgeColor',...
%          'none','FaceColor','texturemap')
%     view(2)
%     axis equal
%     [X2,Y2] = radialdistort([H_Edge - (Resolution(1)+1)/2, ...
%                              V_XPixel+H_Twist - (Resolution(1)+1)/2, ...
%                              V2_XPixel - (Resolution(1)+1)/2], ...
%                             [(Resolution(2)+1)/2 - (H_YPixel+V_Twist), ...
%                              (Resolution(2)+1)/2 - V_Edge, ...
%                              (Resolution(2)+1)/2 - V2_Edge], ...
%                             k, Resolution);
%     hold on
%     plot(X2,Y2,'rx')
%     plot(X2([2,3]),Y2([2,3]),'r:')
%     [X2,Y2] = radialdistort([H_CalibEdge - (Resolution(1)+1)/2, ...
%                              V_XPixel - (Resolution(1)+1)/2, ...
%                              V2_XPixel - (Resolution(1)+1)/2], ...
%                             [(Resolution(2)+1)/2 - (H_YPixel), ...
%                              (Resolution(2)+1)/2 - V_CalibEdge, ...
%                              (Resolution(2)+1)/2 - V2_CalibEdge], ...
%                             k, Resolution);
%     plot(X2,Y2,'gx')
%     plot(X2([2,3]),Y2([2,3]),'g:')
end

end

function H_Edge = findCliff(RGBimage, H_YPixel, H_YBand, H_XPixelMin, ...
                            H_XPixelMax, H_dSVthresh, H_FilterRadius, ...
                            FineSearchMax)

    % extract horizontal search zone
    RGBclip = RGBimage(H_YPixel-H_YBand:H_YPixel+H_YBand,H_XPixelMin:H_XPixelMax,:);
    RGBclip = mean(RGBclip);
    HSVclip = permute(rgb2hsv(RGBclip),[2,3,1]);
    dH = min([abs(HSVclip(1:end-1,1)-HSVclip(2:end,1)),...
              abs(HSVclip(1:end-1,1)-HSVclip(2:end,1)+1.0),...
              abs(HSVclip(1:end-1,1)-HSVclip(2:end,1)-1.0)],[],2);
    dS = abs(HSVclip(1:end-1,2)-HSVclip(2:end,2));
    dV = abs(HSVclip(1:end-1,3)-HSVclip(2:end,3))/300;
    % dSV = dH .* dS .* dV;

    % identify cliff edge in search zone
    % dH = medfilt1(dH,H_FilterRadius);
    dS = medfilt1(dS,H_FilterRadius);
    dV = medfilt1(dV,H_FilterRadius);
    dSV = dS .* dV;

    % primary search
    H_EdgeIni = find(dSV > H_dSVthresh, 1);
    while isempty(H_EdgeIni) 
        %warning('no cliff edge identified in MeasureTwist1, halving H_dHSVthresh')
        H_dSVthresh = H_dSVthresh/2;
        H_EdgeIni = find(dSV > H_dSVthresh, 1);
        if sum(dSV) == 0
            H_Edge = nan;
            return
        end
    end

    % find peak near this location
    H_Edge = H_EdgeIni;
    while dSV(H_Edge+1) > dSV(H_Edge) && H_Edge <= H_EdgeIni +FineSearchMax
        H_Edge = H_Edge+1;
    end

    % apply relevant offset to identified edge
    H_Edge = H_Edge + H_XPixelMin - 1;

end

function V_Edge = findHorizon(RGBimage, V_XPixel, V_XBand, ...
                              V_YPixelMin,V_YPixelMax, V_FilterRadius)

    % extract vertical search zone
    RGBclip = RGBimage(V_YPixelMin:V_YPixelMax, ...
                       V_XPixel-V_XBand:min(V_XPixel+V_XBand,end),:);

    % convert to grayscale
    GrayClip = rgb2gray(RGBclip);

    % horizontally average
    GrayLine = mean(GrayClip,2);

    % median filter
    GrayLine = medfilt1(GrayLine,V_FilterRadius);

    % calc gradient
    dGray = abs(GrayLine(1:end-1)-GrayLine(2:end));

    % % find first threshold crossing
    % V_EdgeIni = find(dGray > V_dGrayThresh, 1);
    % while isempty(V_EdgeIni)
    %     warning('no horizon edge identified in MeasureTwist1, halving V_dGrayThresh')
    %     V_dGrayThresh = V_dGrayThresh/2;
    %     V_EdgeIni = find(dGray > V_dGrayThresh, 1);
    % end
    % 
    % % find peak near this location
    % V_Edge = V_EdgeIni;
    % while dGray(V_Edge+1) > dGray(V_Edge) && V_Edge <= (V_EdgeIni +FineSearchMax)
    %     V_Edge = V_Edge+1;
    % end

    % find max dGray
    [~, V_Edge] = max(dGray);
    
    % apply relevant offsets to identified edge
    V_Edge = V_Edge + V_YPixelMin - 1;
end
