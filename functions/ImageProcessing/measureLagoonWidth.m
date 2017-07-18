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
    
    % intersect transect with WetBdy
%     [Xint,Yint] = polyintersect(WetBdy(:,1), WetBdy(:,2), ...
%                                 Transects{TranNo}(:,1), ...
%                                 Transects{TranNo}(:,2));

    M = (Transects{TranNo}(2,2) - Transects{TranNo}(1,2)) / ...
        (Transects{TranNo}(2,1) - Transects{TranNo}(1,1));
    C = Transects{TranNo}(1,2) - M * Transects{TranNo}(1,1);
    [Xint,Yint] = lineCrossings (WetBdy(:,1), WetBdy(:,2), M, C);
    
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
    for TranNo = 1:size(Transects,1)
    
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

function [Xint, Yint] = lineCrossings (LineX, LineY, M, C)
% efficient calculation of intersection points as polyintersect is too slow

% ID crossing segments
% crossings are where we go from one side of the line to the other
LineSide = sign(LineY - (M * LineX + C));
Crossings = find(LineSide(1:end-1) .* LineSide(2:end) == -1);

% ID intersection points
NoOfCrossings = size(Crossings,1);
Xint = nan(NoOfCrossings,1);
Yint = Xint;
for ii = 1:NoOfCrossings;
    M2 = (LineY(Crossings(ii)+1) - LineY(Crossings(ii))) / ...
         (LineX(Crossings(ii)+1) - LineX(Crossings(ii)));
    if isinf(M2)
        Xint(ii) = LineX(Crossings(ii));
    else
        C2 = LineY(Crossings(ii)) - M2 * LineX(Crossings(ii));
        Xint(ii) = (C2-C)/(M-M2);
    end
    Yint(ii) = M * Xint(ii) + C;
end

% plot(LineX,LineY,'k-')
% hold on
% axis equal
% plot([min(LineX),max(LineX)], [min(LineX)*M+C,max(LineX)*M+C], 'b-')

end

