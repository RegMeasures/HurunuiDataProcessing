function [TimeMatchedPhotos] = timeMatchPhotos(PhotoTable)
%TIMEMATCHEDPHOTOS   Combine photos from both cameras into 1 lookup table
%   [TimeMatchedPhotos] = TIMEMATCHEDPHOTOS(PhotoTable)
%   
%   where:
%   PhotoTable is a table which must have the following fields:
%      - CaptureTime (datenum value)
%      - CameraNo    (1 or 2)
%   TimeMatchedPhotos is a table containing fields:
%      - UniqueTime  = list of Unique datenum values (sorted, increasing)
%      - Cam1Photo   = row number correspoonding to Cam1 image at this time
%      - Cam2Photo   = row number correspoonding to Cam2 image at this time
%                      Note: if only 1 image is present for given time then
%                            either Cam1Photo or Cam2Photo will equal nan.
%
%   See also: UNIQUE, GENPHOTODATATABLE

% Get list of unique timestamps
UniqueTime = unique(PhotoTable.CaptureTime);

% create index for each camera based on timestamp
Cam1Photo = nan(size(UniqueTime));
Cam2Photo = nan(size(UniqueTime));
for ii = 1:size(UniqueTime,1)
    cam1index = find(PhotoTable.CameraNo==1 & ...
                     PhotoTable.CaptureTime==UniqueTime(ii));
    if size(cam1index) > 0
        Cam1Photo(ii,1) = cam1index(1);       
    end
    cam2index = find(PhotoTable.CameraNo==2 & ...
                     PhotoTable.CaptureTime==UniqueTime(ii));
    if size(cam2index) > 0
        Cam2Photo(ii,1) = cam2index(1);       
    end
end

% store everything in a table
TimeMatchedPhotos = table(UniqueTime, Cam1Photo, Cam2Photo);
end

