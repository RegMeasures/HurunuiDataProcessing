function [Twist,Edge] = MeasureTwist1(RGBimage,dispPlots)
%MEASURETWIST1   identify cliff edge in cam1 to inform pole twist correction
%   
%   [Twist,Edge] = MEASURESTWIST1(RGBimage,test)
%
%   RGBimage = Cam1 image i.e. imread('Hurunui1_*.jpg')
%   test     = boolean, true = show plots (default = false)
%   Twist    = diff in edge position of cliff to calibration image (pixels)
%              [px across, px down]
%   Edge     = optional output, absolute cliff edge position in pixels
%              from LHside of image.
%              [H_Edge,V_Edge]
%
%   See also: MeasureTwist2

% set default dispPlots if not supplied 
% (default is not to display diagnistics)
if ~exist('dispPlots','var')
    dispPlots = false;
end

%% fixed inputs

% Edge position corresponding to Twist = 0 [px] 
% note: these are based on Hurunui1_15-10-07_15-28-48-75.jpg
H_CalibEdge = 2335;
V_CalibEdge = 153;

% horizontal (cliff) search params
H_XPixelMin = 2000; % horizontal search range for cliff edge [px]
H_XPixelMax = 2400;
H_YPixel = 550;     % vert coord of horiz search line for cliff edge [px]
H_YBand = 20;        % search band thickness for cliff edge search [px]
H_dSVthresh = 2e-4;% initial dHSV threshold
H_FilterRadius = 5;

% vertical (horizon) search parameters
V_XPixel     = 2471;
V_YPixelMin  = 100;
V_YPixelMax  = 200;
V_XBand      = 20;
V_FilterRadius = 5;
V_dGrayThresh = 5;


% secondary/fine search parameters
%FineSearchMin = 0; 
FineSearchMax = +5;

%% identify cliff edge

% extract horizontal search zone
RGBclip = RGBimage(H_YPixel-H_YBand:H_YPixel+H_YBand,H_XPixelMin:H_XPixelMax,:);
RGBclip = mean(RGBclip);
HSVclip = permute(rgb2hsv(RGBclip),[2,3,1]);
dH = min([abs(HSVclip(1:end-1,1)-HSVclip(2:end,1)),...
          abs(HSVclip(1:end-1,1)-HSVclip(2:end,1)+1.0),...
          abs(HSVclip(1:end-1,1)-HSVclip(2:end,1)-1.0)],[],2);
dS = abs(HSVclip(1:end-1,2)-HSVclip(2:end,2));
dV = abs(HSVclip(1:end-1,3)-HSVclip(2:end,3))/300;
dSV = dH .* dS .* dV;

% identify cliff edge in search zone
dH = medfilt1(dH,H_FilterRadius);
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
        Twist = nan(1,2);
        Edge = nan(1,2);
        return
    end
end

% find peak near this location
H_Edge = H_EdgeIni;
while dSV(H_Edge+1) > dSV(H_Edge) && H_Edge <= H_EdgeIni +FineSearchMax
    H_Edge = H_Edge+1;
end

% apply relevant offsets to identified edge
H_Edge = H_Edge + H_XPixelMin - 1;
H_Twist = H_Edge - H_CalibEdge;

%% identify horizon edge

% extract vertical search zone
RGBclip = RGBimage(V_YPixelMin:V_YPixelMax,V_XPixel+H_Twist-V_XBand:V_XPixel+H_Twist+V_XBand,:);

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
V_Twist =  V_CalibEdge - V_Edge;

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
    plot([H_XPixelMin,H_XPixelMax],[H_YPixel,H_YPixel],'r-')
    plot([H_XPixelMin,H_XPixelMax],[H_YPixel-H_YBand,H_YPixel-H_YBand],'r:')
    plot([H_XPixelMin,H_XPixelMax],[H_YPixel+H_YBand,H_YPixel+H_YBand],'r:')
    plot([H_Edge,H_Edge],[H_YPixel-40,H_YPixel+40],'r-')
    % horizon
    plot([V_XPixel+H_Twist,V_XPixel+H_Twist],[V_YPixelMin,V_YPixelMax],'r-')
    plot([V_XPixel+H_Twist-V_XBand,V_XPixel+H_Twist-V_XBand],[V_YPixelMin,V_YPixelMax],'r:')
    plot([V_XPixel+H_Twist+V_XBand,V_XPixel+H_Twist+V_XBand],[V_YPixelMin,V_YPixelMax],'r:')
    plot([V_XPixel+H_Twist-40,V_XPixel+H_Twist+40],[V_Edge,V_Edge],'r-')
end

Edge = [H_Edge,V_Edge];
Twist = [H_Twist,V_Twist];
end


