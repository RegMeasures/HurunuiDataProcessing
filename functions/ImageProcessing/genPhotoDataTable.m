function PhotoDataTable = genPhotoDataTable(PhotoFolder)
%GENPHOTODATATABLE   scan directory for hurunui images and extract key info
%   Scans all folders and subfolders within PhotoFolder to find all hurunui
%   timelapse images. Extracts key information about each photo by parsing 
%   the image filename and stores it in a table.
%
%   PhotoDatabase = GENPHOTODATATABLE(PhotoFolder)
%
%   All input photos must have filenames in the format:
%   'Hurunui#_yy-mm-dd_HH-MM-SS.jpg' 
%   where # = camera number and yy-mm-dd_HH-MM-SS is the capture date/time.
%
%   See also: 

% Get list of image files
PhotoFileList = rdir(fullfile(PhotoFolder,'\**\*Hurunui*.jpg'), '', true);

% Extract key data into matrices
[FileSubDir,FileName] = cellfun(@fileparts,{PhotoFileList.name}','UniformOutput',false);
CameraNo = cellfun(@(x) str2num(x(end-21)), FileName);
CaptureTime = cellfun(@(x) datenum(x(end-19:end-3), 'yy-mm-dd_HH-MM-SS'), FileName);

% correct time field to nearest 15min interval
CaptureTime = round(CaptureTime*4*24)/(4*24);

% % read metadata to extract resolution
% NoOfPhotos = size(PhotoFileList,1);
% Width = nan(NoOfPhotos,1);
% Height = nan(NoOfPhotos,1);
% for PhotoNo = 1:NoOfPhotos;
%     imMetaData = imfinfo(fullfile(PhotoFolder,PhotoFileList(PhotoNo).name));
%     Width(PhotoNo) = imMetaData.Width;
%     Height(PhotoNo) = imMetaData.Height;
% end

% store everything in a table (requires matlab 2013b or newer)
PhotoDataTable = table(FileName, FileSubDir, CameraNo, CaptureTime);
end

