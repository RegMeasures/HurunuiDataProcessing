function plot2GeoRaster(FileName,FigH,AxH)
%PLOT2GEORASTER Export plot to georeferenced tiff
%   plot2GeoRaster(FileName,FigH,AxH)
%   Note: requires export_fig (https://github.com/altmany/export_fig)

if ~exist('FigH','var') || isempty(FigH)
    FigH = gcf;
end
if ~exist('AxH','var') || isempty(AxH)
    AxH = gca;
end

% some prelimnary modifications to the plot
set(AxH, 'Position', [0,0,1,1])
axis(AxH,'equal','off')
%grid(AxH,'off')
%set(AxH,'color','none')

% export the plot to an image file
export_fig(FileName,'-m5')

% get data for world file
XExtent = get(AxH,'xlim');
YExtent = get(AxH,'ylim');
PicInfo = imfinfo(FileName);
XPixels = PicInfo.Width;
YPixels = PicInfo.Height;
XPixSize = (XExtent(2)-XExtent(1)) / XPixels;
YPixSize = (YExtent(2)-YExtent(1)) / YPixels;

% write the world file
FileID = fopen([FileName([1:end-2,end]),'w'],'w'); % open fie for writing
fprintf(FileID,'%f\r\n%f\r\n%f\r\n%f\r\n%f\r\n%f\r\n',...
        XPixSize, 0, 0, -YPixSize, ...
        XExtent(1) + XPixSize/2, YExtent(2) - YPixSize/2);
fclose(FileID);

end

