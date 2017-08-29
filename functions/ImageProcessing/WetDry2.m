function [WetMask, WetBdyPx] = WetDry2(RGBImage, FgBgMask, SeedPixel, Twist, DiagPlot)
% WETDRY   wet area image classification
%   Uses canny edge detection and dilation/watershed erosion to identify
%   wet area of lagoon in image.
%
%   Inputs:
%      RGBImage  = Colour image data read in using imread
%      FgBgMask  = Mask for RGBImage indicating area of the image
%                  which are in the foreground/background and should be 
%                  excluded from analysis. Areas where FgBgMask = 1
%                  will be excluded from analysis, and areas where 
%                  FgBgMask = 0 will be included.
%      SeedPixel =
%      Twist     = 
%      DiagPlot  = Optional boolean: True  = output diagnostic plots
%                                    False = no plots (default)
%
%   Outputs:
%      WetMask   = classified (1/0) image identifying wet (lagoon) area of
%                  image
%      WetBdyPx  = pixel-coordinates of line around edge of identified wet area
%                  (matrix size Nx2)
%
%   See also: EDGE, BWDIST, WATERSHED, IMDILATE, BWBOUNDARIES, 
%             MEASURETWIST1

if ~exist('Twist','var')||isempty(Twist)
    Twist = [0,0];
end
if ~exist('DiagPlot','var')
    DiagPlot = false;
end


%% Hardcoded settings
DilationPx  = 4     ;% 4      4      3  % Dilation in pixels used for boundary closure
LowThresh   = 0.0004;% 0.0003 0.0004 0.001
HighThresh  = 0.04  ;% 0.038  0.04   0.07
SmoothSigma = 2     ;% 3      2      1

%% Twist Mask and WetXY to line up with twisted image 
% (we do it this way round as the distortion correction needs to be on the raw image)
%FgBgMask = imtranslate(FgBgMask,Twist,'FillValues',1);
FgBgMask = logical(simpleTranslate(FgBgMask,Twist,1));
SeedPixel = SeedPixel + Twist;

%% mask Image to remove foreground and background
MaskedImage = im2single(RGBImage);
MaskedImage(repmat(FgBgMask,[1,1,3])) = nan;

%% get greyscale image
GrayImage = rgb2gray(MaskedImage);

%% do automatic edge detection
Edge1 = edge(GrayImage,'Canny',[LowThresh,HighThresh],SmoothSigma);

%% use dilation and watershed erosion to close regions
EdgeDist = bwdist(Edge1);
EdgeDist = DilationPx+1-min(EdgeDist,DilationPx+1);
Watersheds = watershed(EdgeDist);
WetLabel = Watersheds(SeedPixel(2),SeedPixel(1));
WetMask  = imdilate(Watersheds == WetLabel,strel('disk',1));
WetBdySeperate = bwboundaries(WetMask,'noholes');
WetBdyPx = WetBdySeperate{1};
for BdyNo = 2:size(WetBdySeperate,1)
    WetBdyPx = [WetBdyPx; nan(1,2); WetBdySeperate{BdyNo}];
end

%% Plot
if DiagPlot
    PlotImage = RGBImage;
    PlotImage(repmat(FgBgMask,[1,1,3])) = PlotImage(repmat(FgBgMask,[1,1,3]))/2;
    selection = repmat((EdgeDist>0),[1,1,3]);
    PlotImage(selection) = (0.85*PlotImage(selection) + 0.15*[zeros(2*sum(selection(:))/3,1,'uint8');255*ones(sum(selection(:))/3,1,'uint8')]);
    selection = repmat((Watersheds==0),[1,1,3]);
    PlotImage(selection) = (0.2*PlotImage(selection) + 0.8*[zeros(2*sum(selection(:))/3,1,'uint8');255*ones(sum(selection(:))/3,1,'uint8')]);
    PlotImage(repmat(Edge1,[1,1,3])) = 0;
    figure
    imshow(PlotImage)
    
    
%     figure
%     imshow(RGBImage);
%     showMaskAsOverlay(0.5, FgBgMask, [0.5,0.5,0.5])
%     showMaskAsOverlay(0.2, (EdgeDist>0), 'b', [], false)
%     showMaskAsOverlay(0.8, (Watersheds==0), 'b', [], false)
%     showMaskAsOverlay(1, Edge1, 'k', [], false)
    hold on
    plot(SeedPixel(1),SeedPixel(2),'ro')
    plot(WetBdyPx(:,2), WetBdyPx(:,1), 'r-')
end

end
