function [Twist, WetBdy] = LagoonEdgePosition(PhotoFileName, WL, Cam, ...
                                              FgBgMask, SeedPixel, ...
                                              Twist, WetBdy)
%LAGOONEDGEPOSITION   ID waters edge and project for multiple images
%   Use parallel processing to loop through files and apply WetDry2 and
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
    Twist = nan(NoOfPhotos,2);
end
if ~exist('WetBdy','var') || isempty(WetBdy)
    WetBdy = cell(NoOfPhotos,1);
end

% Twist is handled as a cell array within this process
CellTwist = mat2cell(Twist,ones(NoOfPhotos,1));

%% Loop through days

% start parrallel pool (if license available)
if license('test','Distrib_Computing_Toolbox')
    if isempty(gcp('nocreate'))
        numCores = feature('numcores');
        parpool(numCores);
    end
else
    fprintf(['No license for Matlab parallel computing toolbox ',...
             'available. Single-core processing only.\n'])
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
        if any(isnan(CellTwist{PhotoNo}))
            CellTwist{PhotoNo} = MeasureTwist1(PhotoRgb, Cam.k, ...
                                               Cam.Resolution);
        end

        % find wet edges, project, and clean
        if ~isnan(CellTwist{PhotoNo}(1))
            [~, WetBdyPx] = WetDry2(PhotoRgb, FgBgMask, SeedPixel, CellTwist{PhotoNo});
            [BdyEast, BdyNorth] = ProjectToMap(Cam, WL(PhotoNo), CellTwist{PhotoNo}, WetBdyPx(:,1), WetBdyPx(:,2));
            WetBdy{PhotoNo} = [BdyEast, BdyNorth];
            [WetBdy{PhotoNo}] = cleanWetBdy(WetBdy{PhotoNo});
        end
    end
end

Twist = cell2mat(CellTwist);

end

