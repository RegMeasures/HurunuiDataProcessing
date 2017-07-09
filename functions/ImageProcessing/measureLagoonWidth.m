function [Offsets] = measureLagoonWidth(WetBdy,Transects,DiagPlot)
%Measure offset to lagoon edge along multiple transects
%   [Offsets] = measureLagoonWidth(WetBdy,Transects,DiagPlot)

if ~exist('DiagPlot','var')
    DiagPlot = false;
end

Offsets = nan(size(Transects));

% Find offset to lagoon edge for each transect
for TranNo = 1:size(Transects)
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

