function [Twist, WetBdy] = LagoonEdgePosition(PhotoFileName, WL, Cam, ...
                                              FgBgMask, SeedPixel, ...
                                              Twist, WetBdy)
%LAGOONEDGEPOSITION   ID waters edge and project for multiple images
%   Use parrallel processing to loop through files and apply WetDry2 and
%   ProjectToMap to process each image
%
%   [Twist, WetBdy] = LAGOONEDGEPOSITION(PhotoFileName, WL, Cam, ...
%                                        FgBgMask, SeedPixel, ...
%                                        Twist, WetBdy)
%   Inputs:
%      PhotoFileName = cell array of image file names including full path
%                      and extension
%      WL            = Matrix of lagoon water level for each image
%      Cam           = Camera distortion and projection specifications (see
%                      ProjectToMap for details)
%      FGbGMask      = Mask for foreground/background areas of input images
%                      (see WetDry2 for details)
%      
%
%   See also: MEASURETWIST1, WETDRY2, PROJECTTOMAP, PARFOR

NoOfPhotos = size(PhotoFileName,1);

% Create variables to hold outputs (if they have not been supplied)
if ~exist('Twist','var') || isempty(Twist)
    Twist = cell(NoOfPhotos,1);
end
if ~exist('WetBdy','var') || isempty(WetBdy)
    WetBdy = cell(NoOfPhotos,1);
end

%% Loop through days

% start parralel pool
if isempty(gcp('nocreate'))
    numCores = feature('numcores');
    parpool(numCores);
end

% set up progress reporting as this loop can be slow
fprintf(['Calculating waters edge positions from imagery.\n', ...
         'Required time %s\nCurrent time  \n'], ...
        repmat('.',1,min(70,NoOfPhotos)));

parfor PhotoNo = 1:NoOfPhotos
    
    % Display approx progress
    if rand<(70/NoOfPhotos)
        fprintf(1,'\b.\n'); % \b is backspace
    end
    
    % only load image and process if it hasn't been done before
    if isempty(WetBdy{PhotoNo})

        % Load image
        PhotoRgb = imread(PhotoFileName{PhotoNo});

        % calculate twist if required (only works for cam1 at present!)
        if isempty(Twist{PhotoNo})
            Twist{PhotoNo} = MeasureTwist1(PhotoRgb);
        end

        % find wet edges and project
        if ~isnan(Twist{PhotoNo}(1))
            [~, WetBdyPx] = WetDry2(PhotoRgb, FgBgMask, SeedPixel, Twist{PhotoNo});
            [BdyEast, BdyNorth] = ProjectToMap(Cam, WL(PhotoNo), Twist{PhotoNo}, WetBdyPx(:,1), WetBdyPx(:,2));
            WetBdy{PhotoNo} = [BdyEast, BdyNorth];
        end
    end
end

end

