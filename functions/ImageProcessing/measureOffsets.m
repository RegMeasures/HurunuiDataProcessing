function [Offsets, PlotHs] = measureOffsets(WetBdy, Transects, DiagPlot, AX)
%MEASUREOFFSETS Function to measure offset to lagoon edge along multiple transects
%   [Offsets] = measureOffsets(WetBdy,Transects)
%      Measure and return offsets at each transect.
%
%   [Offsets, PlotHs] = measureOffsets(WetBdy, Transects, true)
%      Produce diagnostic plot and return handles to plotted line data.

MaxIntersections = 5;

if ~exist('DiagPlot','var') || isempty(DiagPlot)
    DiagPlot = false;
end

if DiagPlot && (~exist('AX','var') || isempty(AX))
    AX = gca;
end

Offsets = nan(1,size(Transects,1), MaxIntersections);

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
        CrossingDist = sort(sqrt((Xint - Transects{TranNo}(1,1)).^2 + ...
                                 (Yint - Transects{TranNo}(1,2)).^2), ...
                            1, 'descend');
        Offsets(1, TranNo, 1:min(MaxIntersections, ...
                                 size(CrossingDist,1))) = ...
            permute(CrossingDist(1:min(MaxIntersections, ...
                                       size(CrossingDist,1))), ...
            [3,2,1]);
    end
end

% Plot only if specified
if DiagPlot
    Line1 = plot(AX,WetBdy(:,1),WetBdy(:,2),'k');
    axis equal
    hold(AX,'on')
    for TranNo = 1:size(Transects,1)
    
        Line2 = plot(AX,Transects{TranNo}(:,1),Transects{TranNo}(:,2),'g--');
        Line3 = plot(AX,Transects{TranNo}(1,1),Transects{TranNo}(1,2),'gx');
        LineLength = sqrt((Transects{TranNo}(2,1) - Transects{TranNo}(1,1)).^2 + ...
                          (Transects{TranNo}(2,2) - Transects{TranNo}(1,2)).^2);
        plotX = Transects{TranNo}(1,1) + ...
                (Transects{TranNo}(2,1) - Transects{TranNo}(1,1)) * ...
                (permute(Offsets(1,TranNo,:),[2,3,1])/LineLength);
        plotY = Transects{TranNo}(1,2) + ...
                (Transects{TranNo}(2,2) - Transects{TranNo}(1,2)) * ...
                (permute(Offsets(1,TranNo,:),[2,3,1])/LineLength);
        Line4 = plot(AX,plotX,plotY,'ro','MarkerFaceColor','r');
        PlotHs = [Line1;Line2;Line3;Line4];
    end
end

end

%% Local function
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