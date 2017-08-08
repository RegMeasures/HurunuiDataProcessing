function [Offsets] = measureLagoonWidth(ShortlistPhotos, ...
                                        Transects, DiagPlot)
%Calculate offsets to barrier at Transects for each row in ShortlistPhotos
%   [Offsets] = measureLagoonWidth(ShortlistPhotos, Photos, ...
%                                  Transects, DiagPlot)

% Setup broadcast variables
WetBdy = ShortlistPhotos.WetBdy;
Offsets = ShortlistPhotos.Offsets;

% set up progress reporting as this loop can be slow
NoToProcess = size(ShortlistPhotos,1);
fprintf(['Calculating transect offsets to waters edge.\n', ...
         'Required time %s\nCurrent time  \n'], ...
        repmat('.',1,min(70,NoToProcess)));
    
% Calculate offsets
parfor ii = 1:NoToProcess
    if ~isempty(WetBdy{ii})
        Offsets(ii,:) = measureOffsets(WetBdy{ii}, Transects, DiagPlot)';
    end
    
    % Display approx progress
    if rand<(70/NoToProcess)
        fprintf(1,'\b.\n'); % \b is backspace
    end
end

% Basic QA
Offsets(Offsets > 300) = nan;

end



