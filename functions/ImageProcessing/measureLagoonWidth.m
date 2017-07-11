function [Offsets] = measureLagoonWidth(ShortlistPhotos, Photos, ...
                                        Transects, DiagPlot)
%Calculate offsets to barrier at Transects for each row in ShortlistPhotos
%   [Offsets] = measureLagoonWidth(ShortlistPhotos, Photos, ...
%                                  Transects, DiagPlot)

% create variable to hold outputs if not already present
if ~any(strcmp('Offsets', ShortlistPhotos.Properties.VariableNames))
    ShortlistPhotos.Offsets = nan(size(ShortlistPhotos,1),size(Transects,1));
end

% Setup broadcast variables
WetBdy = cellfun(@(a,b) [a;nan(1,2);b], ...
                 Photos.WetBdy(ShortlistPhotos.Cam1Photo), ...
                 Photos.WetBdy(ShortlistPhotos.Cam2Photo), ...
                 'UniformOutput', false);
Offsets = ShortlistPhotos.Offsets;

% set up progress reporting as this loop can be slow
NoToProcess = size(ShortlistPhotos,1);
fprintf(['Calculating transect offsets to waters edge.\n', ...
         'Required time %s\nCurrent time  \n'], ...
        repmat('.',1,min(70,NoToProcess)));
    
% Calculate offsets
for ii = 1:NoToProcess
    if ~isempty(WetBdy{ii})
        Offsets(ii,:) = measureOffsets(WetBdy{ii}, Transects, DiagPlot)';
    end
    
    % Display approx progress
    if rand<(70/NoToProcess)
        fprintf(1,'\b.\n'); % \b is backspace
    end
end

end

%% Local functions
function [Offsets] = measureOffsets(WetBdy, Transects, DiagPlot)
%Local function to measure offset to lagoon edge along multiple transects
%   [Offsets] = measureOffsets(WetBdy,Transects,DiagPlot)

if ~exist('DiagPlot','var')
    DiagPlot = false;
end

Offsets = nan(size(Transects));

% Find offset to lagoon edge for each transect
for TranNo = 1:size(Transects)
    
    % AS THE TRANSECT IS A STRAIGHT LINE THERE IS PROBABALY A QUICKER WAY 
    % OF DOING THIS BIT
    % intersect transect with WetBdy
    [Xint,Yint] = polyintersect(WetBdy(:,1), WetBdy(:,2), ...
                                Transects{TranNo}(:,1), ...
                                Transects{TranNo}(:,2));
    % if they cross then calc offset to outermost crossing
    if ~isempty(Xint)
        Offsets(TranNo) = max(sqrt((Xint - Transects{TranNo}(1,1)).^2 + ...
                                   (Yint - Transects{TranNo}(1,2)).^2));
    end
end

% Plot only if specified
if DiagPlot
    plot(WetBdy(:,1),WetBdy(:,2),'k')
    axis equal
    hold on
    for TranNo = 1:size(Transects)
    
        plot(Transects{TranNo}(:,1),Transects{TranNo}(:,2),'g--')
        plot(Transects{TranNo}(1,1),Transects{TranNo}(1,2),'gx')
        LineLength = sqrt((Transects{TranNo}(2,1) - Transects{TranNo}(1,1)).^2 + ...
                          (Transects{TranNo}(2,2) - Transects{TranNo}(1,2)).^2);
        plotX = Transects{TranNo}(1,1) + ...
                (Transects{TranNo}(2,1) - Transects{TranNo}(1,1)) * ...
                (Offsets(TranNo)/LineLength);
        plotY = Transects{TranNo}(1,2) + ...
                (Transects{TranNo}(2,2) - Transects{TranNo}(1,2)) * ...
                (Offsets(TranNo)/LineLength);
        plot(plotX,plotY,'rx')
    end
end

end

