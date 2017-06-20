function [PhotoDataTable] = photoQuality(PhotoFolder, PhotoDataTable, ...
                                         PhotosPrevious)
%PHOTOQUALITY   Add image quality metrics to PhotoDataTable
%   Calculate image sharpness, contrast and brightness metrics for each
%   photo in PhotoDataTable. PHOTOQUALITY is parralelised using parfor to
%   enable faster processing but still runs (single core) if the matlab
%   parrallel toolbox is not available.
%   
%   [PhotoDataTable] = PHOTOQUALITY(PhotoFolder, PhotoDataTable, ...
%                                   PhotosPrevious)
%   
%   Where inputs are:
%      PhotoFolder    = Main directory where photos are stored
%      PhotoDataTable = Data table with 1 row for each photo. 
%                       PhotoDataTable is typically created using 
%                       genPhotoDataTable. Required columns are:
%         .FileSubDir = Sub directory where individual photo is located
%         .FileName   = Filename of photo (no extension, .jpg assumed)
%      PhotosPrevious = Previously calculated output PhotoDataTable
%                       (optional) 
%   and outputs are:
%      PhotoDataTable = Same as input PhotoDataTable but with extra columns
%                       containing quality metrics:
%         .Sharpness   = estimate_sharpness(ImageGray);
%         .Contrast    = std(ImageGray(:));
%         .Brightness  = mean(ImageGray(:));
%
%   See also: GENPHOTODATATABLE, ESTIMATE_SHARPNESS

% WOULD BE GOOD TO MOVE PHOTODATATABLE OUT OF THIS FUNCTION TO MAKE IT MORE
% GENERIC

%% Create new variables ready to fill with quality metrics
% (note these need to be seperate variables rather than tabkle columns so
% that they work in a parfor loop)
NoOfPhotos = size(PhotoDataTable,1);
Sharpness = nan(NoOfPhotos,1);
Contrast = nan(NoOfPhotos,1);
Brightness = nan(NoOfPhotos,1);

%% Import old data if available
if exist('PhotosPrevious','var');
    [~,IA,IB] = intersect(PhotosPrevious.FileName, ...
                          PhotoDataTable.FileName,'stable');
    Sharpness(IB) = PhotosPrevious.Sharpness(IA);
    Contrast(IB) = PhotosPrevious.Contrast(IA);
    Brightness(IB) = PhotosPrevious.Brightness(IA);
    fprintf(['Imported %d quality metrics from matching photos in ', ...
             'database of %d previously processed photos.\n'], ...
            size(IA,1),size(PhotosPrevious.FileName,1));
end

%% Calculate metrics

% start parrallel pool (if license available)
if license('test','Distrib_Computing_Toolbox')
    myPool = parpool();
else
    fprintf(['No license for Matlab parallel computing toolbox',...
             'available. Single-core processing only.\n'])
end

% set up progress reporting as this can be slow if there are lots of photos
fprintf('Calculating Quality Metrics.\nRequired time %s\nCurrent time  \n', ...
        repmat('.',1,min(70,NoOfPhotos)));
    
parfor PhotoNo = 1:NoOfPhotos
        
    % Display approx progress
    if rand<(70/NoOfPhotos)
        fprintf(1,'\b.\n'); % \b is backspace
    end
    
    % Only process image if quality parameters are not already available
    if isnan(Sharpness(PhotoNo))
        % Load image
        ImageRGB = imread(fullfile(PhotoFolder, ...
                                   PhotoDataTable.FileSubDir{PhotoNo}, ...
                                   [PhotoDataTable.FileName{PhotoNo},'.jpg']));

        % Convert to grayscale
        ImageGray = double(rgb2gray(ImageRGB));

        % Calculate quality metrics
        Sharpness(PhotoNo) = estimate_sharpness(ImageGray);
        Contrast(PhotoNo) = std(ImageGray(:));
        Brightness(PhotoNo) = mean(ImageGray(:));

    
%         imshow(TestImageRGB);
%         text(10, 60 ,...
%              sprintf('Sharpness = %1.2f\nContrast = %1.2f\nBrightness = %1.2f', ...
%                      Contrast(ImageNo), Brightness(ImageNo)),...
%              'BackgroundColor', 'white');
    end
    
end
%close(WaitH)

% Add quality metrics as columns in photo data table
PhotoDataTable.Sharpness = Sharpness;
PhotoDataTable.Contrast = Contrast;
PhotoDataTable.Brightness = Brightness;

end

