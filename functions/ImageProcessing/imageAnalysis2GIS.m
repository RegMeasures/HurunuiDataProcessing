function imageAnalysis2GIS(CamImage1,CamImage2,WL,Config,FileName)
%IMAGEANALYSIS2GIS Output camera images and calculated metrics to GIS
%   Projects

%% Process the images

% Measure pole twist
Twist1 = measureTwist(CamImage1,Config.Cam1);
Twist2 = measureTwist(CamImage2,Config.Cam2);

% find wet edges
[~, WetBdy1] = WetDry2(CamImage1, Config.FgBgMask1, ...
                       Config.SeedPixel1, Twist1, false);
[~, WetBdy2] = WetDry2(CamImage2, Config.FgBgMask2, ...
                       Config.SeedPixel2, Twist2, false);

% convert WetBdys to easting northing
[BdyEasting1, BdyNorthing1] = ...
    ProjectToMap(Config.Cam1, WL, Twist1, WetBdy1(:,1), WetBdy1(:,2));
[BdyEasting2, BdyNorthing2] = ...
    ProjectToMap(Config.Cam2, WL, Twist2, ...
                 WetBdy2(:,1), WetBdy2(:,2));
WetBdy1 = [BdyEasting1, BdyNorthing1];
WetBdy2 = [BdyEasting2, BdyNorthing2];

% Remove backshore part of WetBdy polygon to leave polyline along barrier
WetBdy1 = cleanWetBdy(WetBdy1);
WetBdy2 = cleanWetBdy(WetBdy2);

% Calc offsets along transects to WetBdy
WetBdy = [WetBdy1; ...
          nan(1,2); ...
          WetBdy2];
[Offsets] = measureOffsets(WetBdy,Config.Transects);
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

%% Export to GIS for nice figure production

% Export shapefile of wetbdy
shapewrite([FileName,'_WetBdy.shp'], 'polyline', ...
           {WetBdy1;WetBdy2}, {'CamNo'}, [1;2]);

% Export shapefile of offsets
shapewrite([FileName,'_Offsets.shp'], 'point', ...
           OffsetXYT(:,[1,2]), {'TransectNo'}, OffsetXYT(:,3));

% display projected image as surface ready to export raster
FigH = figure;
MapAx = plotProjected(CamImage1, Twist1, WL, Config.Cam1,...
                      Config.FgBgMask1, []);
hold(MapAx,'on')
plotProjected(CamImage2, Twist2, WL, Config.Cam2, ...
              Config.FgBgMask2, MapAx);

% save to tiff with location info
plot2GeoRaster([FileName,'_projected.tif'],FigH,MapAx)

close(FigH)
end

