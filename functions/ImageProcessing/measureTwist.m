function [Twist,Edge] = measureTwist(RGBimage,Cam,dispPlots)
%MEASURETWIST   identify object edges to correct camera orientation
%   
%   [Twist,Edge] = MEASURESTWIST(RGBimage,Cam,dispPlots)
%   
%   Inputs:
%      RGBimage  = Cam1 image i.e. imread('Hurunui1_*.jpg')
%      Cam       = Camera parameters - see HurunuiAnalysisConfig for 
%                  details. Parametrs used in measureTwist are:
%         .k
%         .Resolution
%         .H_CalibEdge
%         .H_CalibEdge
%         .V_CalibEdge
%         .V2_CalibEdge
%         .H_XPixelMin
%         .H_XPixelMax
%         .H_YPixel
%         .H_YBand
%         .H_dSVthresh
%         .H_FilterRadius
%         .H_SearchDirection
%         .H_FineSearchMax
%         .H_ApplyTwist
%         .V_XPixel
%         .V_YPixelMin
%         .V_YPixelMax
%         .V_XBand
%         .V_FilterRadius
%         .V_ApplyTwist
%         .V2_XPixel
%         .V2_YPixelMin
%         .V2_YPixelMax
%         .V2_XBand
%         .V2_FilterRadius
%         .V2_ApplyTwist
%      dispPlots = boolean, true = show plots (optional, default = false)
%   Outputs:
%      Twist     = diff in edge position of cliff to calibration image
%                  [px across, px down]
%      Edge      = optional output, position in pixels of identified
%                  objects: [H_Edge,V_Edge,V2_Edge]
%
%   See also: HURUNUIANALYSISCONFIG

% set default dispPlots if not supplied 
% (default is not to display diagnistics)
if ~exist('dispPlots','var') || isempty(dispPlots)
    dispPlots = false;
end

%% identify cliff edge
H_Edge = findCliff(RGBimage, Cam.H_YPixel, Cam.H_YBand, Cam.H_XPixelMin, ...
                   Cam.H_XPixelMax, Cam.H_dSVthresh, Cam.H_FilterRadius, ...
                   Cam.H_SearchDirection, Cam.H_FineSearchMax);
if isnan(H_Edge)
    Twist = nan(1,3);
    Edge = nan(1,2);
    return
end
% initial twist calculation with no accounting for lens distortion
H_Twist = H_Edge - Cam.H_CalibEdge;

%% identify horizon edge
V_Edge = findHorizon(RGBimage, Cam.V_XPixel + H_Twist*Cam.V_ApplyTwist, ...
                     Cam.V_XBand, Cam.V_YPixelMin,Cam.V_YPixelMax, ...
                     Cam.V_FilterRadius);

% Original twist calculation with no accounting for lens distortion
V_Twist =  V_Edge - Cam.V_CalibEdge;

%% update cliff edge calc
if Cam.H_ApplyTwist
    H_Edge = findCliff(RGBimage, Cam.H_YPixel + V_Twist, Cam.H_YBand, ...
                       Cam.H_XPixelMin, Cam.H_XPixelMax, Cam.H_dSVthresh, ...
                       Cam.H_FilterRadius, Cam.H_SearchDirection, ...
                       Cam.H_FineSearchMax);

    % initial twist calculation with no accounting for lens distortion
    H_Twist = H_Edge - Cam.H_CalibEdge;
end

%% update horizon edge calc
if Cam.V_ApplyTwist
    V_Edge = findHorizon(RGBimage, Cam.V_XPixel + H_Twist, Cam.V_XBand, ...
                         Cam.V_YPixelMin,Cam.V_YPixelMax, Cam.V_FilterRadius);

    % Original twist calculation with no accounting for lens distortion
    V_Twist =  V_Edge - Cam.V_CalibEdge;
end

%% LH horizon edge for roll
V2_Edge = findHorizon(RGBimage, Cam.V2_XPixel + H_Twist * Cam.V2_ApplyTwist, ...
                      Cam.V2_XBand, Cam.V2_YPixelMin,Cam.V2_YPixelMax, ...
                      Cam.V2_FilterRadius);

%% Calculate Twist accounting for lens distortion

% horizontal
[H_CalibEdge2, ~] = radialdistort(Cam.H_CalibEdge - (Cam.Resolution(1)+1)/2, ...
                                  (Cam.Resolution(2)+1)/2 - (Cam.H_YPixel), ...
                                  Cam.k, Cam.Resolution);
[H_Edge2, H_Y2] = radialdistort(H_Edge - (Cam.Resolution(1)+1)/2, ...
                             (Cam.Resolution(2)+1)/2 - (Cam.H_YPixel + V_Twist*Cam.H_ApplyTwist), ...
                             Cam.k, Cam.Resolution);
H_Twist2 = H_Edge2 - H_CalibEdge2;

% vertical
[V_CalibX2, V_CalibEdge2] = radialdistort(Cam.V_XPixel - (Cam.Resolution(1)+1)/2, ...
                                  (Cam.Resolution(2)+1)/2 - Cam.V_CalibEdge, ...
                                  Cam.k, Cam.Resolution);
[V_X2, V_Edge2] = radialdistort(Cam.V_XPixel + H_Twist*Cam.V_ApplyTwist - (Cam.Resolution(1)+1)/2, ...
                             (Cam.Resolution(2)+1)/2 - V_Edge, ...
                             Cam.k, Cam.Resolution);
V_Twist2 =  V_Edge2 - V_CalibEdge2; 
% Note the sign convention of V_Twist2 has been flipped relative to V_Twist 
% as we are now working in XY space rather than row-col space.
% Sign convention is now correct for output.

% roll (clockwise positive)
[V2_CalibX2, V2_CalibEdge2] = radialdistort(Cam.V2_XPixel - (Cam.Resolution(1)+1)/2, ...
                                  (Cam.Resolution(2)+1)/2 - Cam.V2_CalibEdge, ...
                                  Cam.k, Cam.Resolution);
[V2_X2, V2_Edge2] = radialdistort(Cam.V2_XPixel + H_Twist*Cam.V2_ApplyTwist - (Cam.Resolution(1)+1)/2, ...
                                  (Cam.Resolution(2)+1)/2 - V2_Edge, ...
                                  Cam.k, Cam.Resolution);
RollAngleCalib = atand((V2_CalibEdge2 - V_CalibEdge2) / ...
                       (V_CalibX2 - V2_CalibX2));
RollAngleMeas = atand((V2_Edge2 - V_Edge2) / ...
                      (V_X2 - V2_X2));
Roll = RollAngleMeas - RollAngleCalib;

% Adjust V_Twist2 for roll (i.e. vertical twist at image center)
V_Twist2 = round(V_Twist2 - ...
                 (sign(V_X2)*sqrt(V_X2^2 + V_Edge2^2) * ...
                  sind(atand(V_Edge2/V_X2) - Roll) - V_Edge2));

% Adjust H_Twist2 for roll
H_Twist2 = round(H_Twist2 - ...
                 (sign(H_Edge2)*sqrt(H_Edge2^2 + H_Y2^2) * ...
                  cosd(atand(H_Y2/H_Edge2) - Roll) - H_Edge2));

% Assemble final outputs
Edge = [H_Edge,V_Edge,V2_Edge];
%Twist = [H_Twist,V_Twist];
Twist = [H_Twist2,V_Twist2,Roll];

%% Test plots
if dispPlots
    
    % cliff ID plots
    
%     figure
%     imshow(RGBimage(Cam.H_YPixel-Cam.H_YBand-50:Cam.H_YPixel+Cam.H_YBand+50,Cam.H_XPixelMin-50:Cam.H_XPixelMax+50,:))
%     hold on
%     plot([50,Cam.H_XPixelMax-Cam.H_XPixelMin+51],[51+Cam.H_YBand,51+Cam.H_YBand],'r-')
%     plot([50,Cam.H_XPixelMax-Cam.H_XPixelMin+51],[50,50],'r:')
%     plot([50,Cam.H_XPixelMax-Cam.H_XPixelMin+51],[51+2*Cam.H_YBand,51+2*Cam.H_YBand],'r:')
%     plot([H_Edge-(Cam.H_XPixelMin-50),H_Edge-(Cam.H_XPixelMin-50)],[10,91+2*Cam.H_YBand],'r-')
%     hold off
%     
%     figure
%     plot(HSVclip(:,1))
%     hold on
%     plot(HSVclip(:,2))
%     plot(HSVclip(:,3)/300)
%     legend({'H','S','V/300'})
%     plot([H_Edge-Cam.H_XPixelMin,H_Edge-Cam.H_XPixelMin],[0,1],'k:')
% 

    

    
    % Overall plot
    figure
    imshow(RGBimage)
    hold on
    % cliff
    plot([Cam.H_XPixelMin,Cam.H_XPixelMax],[Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist,Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist],'r-')
    plot([Cam.H_XPixelMin,Cam.H_XPixelMax],[Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist-Cam.H_YBand,Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist-Cam.H_YBand],'r:')
    plot([Cam.H_XPixelMin,Cam.H_XPixelMax],[Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist+Cam.H_YBand,Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist+Cam.H_YBand],'r:')
    plot([H_Edge,H_Edge],[Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist-40,Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist+40],'g-')
    plot([Cam.H_CalibEdge,Cam.H_CalibEdge],[Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist-40,Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist+40],'r-')
    % horizon
    plot([Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist,Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist],[Cam.V_YPixelMin,Cam.V_YPixelMax],'r-')
    plot([Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist-Cam.V_XBand,Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist-Cam.V_XBand],[Cam.V_YPixelMin,Cam.V_YPixelMax],'r:')
    plot([Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist+Cam.V_XBand,Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist+Cam.V_XBand],[Cam.V_YPixelMin,Cam.V_YPixelMax],'r:')
    plot([Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist-40,Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist+40],[V_Edge,V_Edge],'g-')
    plot([Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist-40,Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist+40],[Cam.V_CalibEdge,Cam.V_CalibEdge],'r-')
    % horizon 2
    plot([Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist,Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist],[Cam.V2_YPixelMin,Cam.V2_YPixelMax],'r-')
    plot([Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist-Cam.V2_XBand,Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist-Cam.V2_XBand],[Cam.V2_YPixelMin,Cam.V2_YPixelMax],'r:')
    plot([Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist+Cam.V2_XBand,Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist+Cam.V2_XBand],[Cam.V2_YPixelMin,Cam.V2_YPixelMax],'r:')
    plot([Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist-40,Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist+40],[V2_Edge,V2_Edge],'g-')
    plot([Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist-40,Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist+40],[Cam.V2_CalibEdge,Cam.V2_CalibEdge],'r-')
    
    % undistorted:
    % Create grid of pixel positions
    [PixelCol, PixelRow] = meshgrid(1:Cam.Resolution(1),1:Cam.Resolution(2));
    % Make Pixel Positions relative to image center
    PixelX = PixelCol - (Cam.Resolution(1)+1)/2;
    PixelY = - (PixelRow - (Cam.Resolution(2)+1)/2);
    % Correct pixel positions for lens distortion
    [PixelX, PixelY] = radialdistort(PixelX, PixelY, Cam.k, Cam.Resolution);
    % plot
    figure
    surf(PixelX, PixelY, zeros(size(PixelX)),RGBimage,'EdgeColor',...
         'none','FaceColor','texturemap')
    view(2)
    axis equal
    [X2,Y2] = radialdistort([H_Edge - (Cam.Resolution(1)+1)/2, ...
                             Cam.V_XPixel+H_Twist*Cam.V_ApplyTwist - (Cam.Resolution(1)+1)/2, ...
                             Cam.V2_XPixel+H_Twist*Cam.V2_ApplyTwist - (Cam.Resolution(1)+1)/2], ...
                            [(Cam.Resolution(2)+1)/2 - (Cam.H_YPixel+V_Twist*Cam.H_ApplyTwist), ...
                             (Cam.Resolution(2)+1)/2 - V_Edge, ...
                             (Cam.Resolution(2)+1)/2 - V2_Edge], ...
                            Cam.k, Cam.Resolution);
    hold on
    plot(X2,Y2,'gx')
    plot(X2([2,3]),Y2([2,3]),'g:')
    [X2,Y2] = radialdistort([Cam.H_CalibEdge - (Cam.Resolution(1)+1)/2, ...
                             Cam.V_XPixel - (Cam.Resolution(1)+1)/2, ...
                             Cam.V2_XPixel - (Cam.Resolution(1)+1)/2], ...
                            [(Cam.Resolution(2)+1)/2 - (Cam.H_YPixel), ...
                             (Cam.Resolution(2)+1)/2 - Cam.V_CalibEdge, ...
                             (Cam.Resolution(2)+1)/2 - Cam.V2_CalibEdge], ...
                            Cam.k, Cam.Resolution);
    plot(X2,Y2,'rx')
    plot(X2([2,3]),Y2([2,3]),'r:')
    text(0, 0, ...
         sprintf('H Twist = %i px\nV Twist = %i px\nRoll = %f degrees', ...
                 Twist(1),Twist(2),Twist(3)), ...
                 'HorizontalAlignment', 'center', 'Color','k')
end

end

function H_Edge = findCliff(RGBimage, YPixel, YBand, XPixelMin, ...
                            XPixelMax, dSVthresh, FilterRadius, ...
                            SearchDirection, FineSearchMax)

    % extract horizontal search zone
    RGBclip = RGBimage(YPixel-YBand:YPixel+YBand,XPixelMin:XPixelMax,:);
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
    dS = medfilt1(dS,FilterRadius);
    dV = medfilt1(dV,FilterRadius);
    dSV = dS .* dV;
    dSV = [nan(FilterRadius,1); ...
           dSV(FilterRadius+1:end-FilterRadius); ...
           nan(FilterRadius,1)];

    % primary search
    while ~exist('H_EdgeIni','var') || isempty(H_EdgeIni)
        if SearchDirection == 1
            H_EdgeIni = find(dSV > dSVthresh, 1, 'first');
        elseif SearchDirection == -1
            H_EdgeIni = find(dSV > dSVthresh, 1, 'last');
        else
            [~, H_EdgeIni] = max(dSV);
        end
        
        if sum(dSV) == 0
            H_Edge = nan;
            return
        end
        dSVthresh = dSVthresh*0.75;
    end
    dSVthresh = dSVthresh*1/0.75;
    
    % refine to peak of first threshold exceedance
    H_Edge = H_EdgeIni;
    if SearchDirection ~= 0
        while dSV(H_Edge + SearchDirection) > dSV(H_Edge) && ...
              H_Edge >= max(H_EdgeIni -FineSearchMax, 1) && ...
              H_Edge <= min(H_EdgeIni +FineSearchMax, size(RGBclip,2))
            H_Edge = H_Edge + SearchDirection;
        end
    end
    
    % apply relevant offset to identified edge
    H_Edge = H_Edge + XPixelMin - 1;

    figure
    plot(dSV)
    legend('dSV')
    hold on
    plot([0,XPixelMax-XPixelMin+1],[dSVthresh,dSVthresh],'k:')
    plot([H_Edge-XPixelMin,H_Edge-XPixelMin],[0,max(dSV)],'k:')
end

function V_Edge = findHorizon(RGBimage, XPixel, XBand, ...
                              YPixelMin, YPixelMax, FilterRadius)
    % check the black time band at the top is not included in the search
    YPixelMin = max(YPixelMin,25);
                          
    % extract vertical search zone
    RGBclip = RGBimage(YPixelMin:YPixelMax, ...
                       XPixel-XBand:min(XPixel+XBand,end),:);

    % convert to grayscale
    GrayClip = rgb2gray(RGBclip);

    % horizontally average
    GrayLine = mean(GrayClip,2);

    % median filter
    GrayLine = medfilt1(GrayLine,FilterRadius);
    GrayLine = [nan(FilterRadius,1); ...
                GrayLine(FilterRadius+1:end-FilterRadius); ...
                nan(FilterRadius,1)];

    % calc gradient
    dGray = abs(GrayLine(1:end-1)-GrayLine(2:end));

    % find max dGray
    [~, V_Edge] = max(dGray);
    
    % apply relevant offsets to identified edge
    V_Edge = V_Edge + YPixelMin - 1;
    
%     figure
%     imshow(RGBimage(YPixelMin-50:YPixelMax+50,XPixel-XBand-50:XPixel+XBand+50,:))
%     hold on
%     plot([51+XBand,51+XBand],[50,YPixelMax-YPixelMin+51],'r-')
%     plot([50,50],[50,YPixelMax-YPixelMin+51],'r:') % LH edge of band
%     plot([51+2*XBand,51+2*XBand],[50,YPixelMax-YPixelMin+51],'r:') % RH edge of band
%     plot([10,91+2*XBand],[V_Edge-(YPixelMin-50),V_Edge-(YPixelMin-50)],'g-') % Identified edge
%     hold off
end
