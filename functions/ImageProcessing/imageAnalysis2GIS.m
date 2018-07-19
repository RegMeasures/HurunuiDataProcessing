function imageAnalysis2GIS(Config, FileName, Cam1Image, Cam2Image, ...
                           WL, Twist, WetBdy, Offsets)
%IMAGEANALYSIS2GIS Output camera images and calculated metrics to GIS
%   Converts WetBdy and Offsets data to shapefiles and images to
%   georeferenced tiff file.
%
%   IMAGEANALYSIS2GIS(Config, FileName, CamImage1, CamImage2, ...
%                     WL, Twist, WetBdy, Offsets)
%   
%   All inputs except Config and FileName are optional:
%       - If CamImage1, CamImage2, WL and Twist are supplied then projected
%         images will be output to "FileName_projected.tif" with
%         accompanying georeferencing data stored in the world file
%         "FileName_projected.tfw".
%       - If WetBdy is supplied then WetBdy will be output to the polyline
%         shapefile "FileName_WetBdy.shp".
%       - If Offsets is supplied then Offsets will be output to the point
%         shapefile "FileName_Offsets.shp".
%
%   Cam1Image and Cam2Image must be supplied as matlab data (created using
%   imread).

%% Export WetBdy as shapefile
if exist('WetBdy','var') && ~isempty(WetBdy)
    % prep data for shapewrite
    PolylineData = WetBdy;
    RepeatPoints = [all(PolylineData(1:end-1, :) == PolylineData(2:end, :), 2); false];
    PolylineData = PolylineData(~RepeatPoints, :);
    DataGaps = find(isnan(PolylineData(:,1)));
    PolylineData = PolylineData(setdiff(1:end, DataGaps),:);
    DataGaps = unique(DataGaps - (1:length(DataGaps))');
    DataBlocks = [DataGaps; size(PolylineData,1)] - ...
                 [0; DataGaps];
    PolylineData = mat2cell(PolylineData, DataBlocks, 2);
    PolylineData = PolylineData(DataBlocks>1);
    % write out shapefile
    shapewrite([FileName,'_WetBdy.shp'], 'polyline', PolylineData)
%     NoOfLines = size(PolylineData, 1);
%     ShapeData = struct('Geometry', repmat({'Line'}, [NoOfLines, 1]), ...
%                        'BoundingBox', cell(NoOfLines, 1), ...
%                        'X', cellfun(@(x) [x(:,1)', NaN], PolylineData, 'UniformOutput', false), ...
%                        'Y', cellfun(@(x) [x(:,2)', NaN], PolylineData, 'UniformOutput', false), ...
%                        'Id', num2cell(zeros(NoOfLines,1)));
%     for LineNo = 1:NoOfLines
%         ShapeData(LineNo).BoundingBox = ...
%             [min(ShapeData(LineNo).X), min(ShapeData(LineNo).Y); ...
%              max(ShapeData(LineNo).X), max(ShapeData(LineNo).Y)];
%     end
%     shapewrite(ShapeData, [FileName,'_WetBdy'])
end

%% Export shapefile of offsets
if exist('Offsets','var') && ~isempty(Offsets)
    OffsetXYT = nan(size(Offsets,2)*size(Offsets,3),2);
    for TranNo = 1:size(Config.Transects,1)
        LineLength = sqrt((Config.Transects{TranNo}(2,1) - Config.Transects{TranNo}(1,1)).^2 + ...
                          (Config.Transects{TranNo}(2,2) - Config.Transects{TranNo}(1,2)).^2);
        OffsetXYT((TranNo-1)*5+(1:5),1) = Config.Transects{TranNo}(1,1) + ...
                                          (Config.Transects{TranNo}(2,1) - Config.Transects{TranNo}(1,1)) * ...
                                          (permute(Offsets(1,TranNo,:),[2,3,1])/LineLength);
        OffsetXYT((TranNo-1)*5+(1:5),2) = Config.Transects{TranNo}(1,2) + ...
                                          (Config.Transects{TranNo}(2,2) - Config.Transects{TranNo}(1,2)) * ...
                                          (permute(Offsets(1,TranNo,:),[2,3,1])/LineLength);
        OffsetXYT((TranNo-1)*5+(1:5),3) = TranNo;
    end
    OffsetXYT = OffsetXYT(~isnan(OffsetXYT(:,1)),:);
    shapewrite([FileName,'_Offsets.shp'], 'point', ...
               OffsetXYT(:,[1,2]), {'TransectNo'}, OffsetXYT(:,3));
end

%% Export projected image
if exist('Cam1Image', 'var') && ~isempty(Cam1Image) && ...
        exist('Cam2Image', 'var') && ~isempty(Cam2Image) && ...
        exist('WL', 'var') && ~isempty(WL)&& ...
        exist('Twist', 'var') && ~isempty(Twist)
    % display projected image as surface ready to export raster
    FigH = figure;
    MapAx = plotProjected(Cam1Image, Twist, WL, Config.Cam1,...
                          Config.FgBgMask1, []);
    hold(MapAx,'on')
    plotProjected(Cam2Image, ...
                  [Twist(1), -Twist(2)*Config.Cam2.ViewWidth/Config.Cam1.ViewWidth, -Twist(3)], ...
                  WL, Config.Cam2, Config.FgBgMask2, MapAx);

    % save to tiff with location info
    plot2GeoRaster([FileName,'_projected.tif'], FigH, MapAx)

    close(FigH)
end
end

