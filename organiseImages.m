function organiseImages(ImageDumpFolder, CreateCopy)
% ORGANISEIMAGES   Sort hurunui photos into preffered directory structure
%   Moves (or optionally copies) images from a single folder into an
%   organised file structure of the format:
%       ...\YYYY\MM\CameraId\Image.jpg
%
%   The root directory is taken from the DataFolder and PhotoFolder 
%   variables stored in HurunuiAnalaysisConfig (the full directory path is
%   given by DataFolder\PhotoFolder).
%
%   ORGANISEIMAGES relies on the image file names being in the format 
%   "CameraID_YY-MM-DD_HH-MM-SS-SS.jpg". For example: 
%   "Hurunui1_18-06-15_12-28-52-23.jpg"
%
%   ORGANISEIMAGES(ImageDumpFolder, CreateCopy)
%
%   ImageDumpFolder = the path of the folder where the unsorted images are
%                     stored. If not supplied the user will be prompted to 
%                     select it.
%   CreateCopy = Boolean value indicating whether to move files (false,
%                default) or copy them (true).
%
%   See also: HURUNUIANALYSISCONFIG

if ~exist('ImageDumpFolder', 'var') || isempty(ImageDumpFolder)
    ImageDumpFolder = uigetdir([], 'Select folder containing unsorted images');
end

if ~exist('CreateCopy', 'var') || isempty(CreateCopy)
    CreateCopy = false; % true = copy, false = move
end

Config = HurunuiAnalysisConfig;
ImageStore = fullfile(Config.DataFolder, Config.PhotoFolder); % store organised images here

%% Examine images

% Get list of image files
PhotoFileList = dir(fullfile(ImageDumpFolder,'Hurunui*.jpg'));

% Get info to split into directories
FileName = {PhotoFileList.name}';
CameraNo = cellfun(@(x) str2num(x(end-25)), FileName);
CaptureTime = cellfun(@(x) datenum(x(end-23:end-7), 'yy-mm-dd_HH-MM-SS'), FileName);
[CaptureYear,CaptureMonth,~,~,~,~] = datevec(CaptureTime);

%% file photos by year
for Year = unique(CaptureYear)'
    YearDir = fullfile(ImageStore,num2str(Year));
    
    % Create year directory if not already present
    if ~exist(YearDir,'dir')
        mkdir(ImageStore,num2str(Year));
    end
    
    % File photos by month
    for Month = unique(CaptureMonth(CaptureYear == Year))'
        MonthDir = fullfile(YearDir,num2str(Month,'%02d'));
        fprintf('Filing photos in %s\n',MonthDir)
        
        % Create month directory if not already present
        if ~exist(MonthDir,'dir')
            mkdir(YearDir,num2str(Month,'%02d'));
        end
        
        % File photos by camera no
        for CameraID = 1:2
            CameraDir = fullfile(MonthDir,['Hurunui',num2str(CameraID)]);
            
            % Create camera directory if not already present
            if ~exist(CameraDir,'dir')
                mkdir(MonthDir,['Hurunui',num2str(CameraID)]);
            end
            
            % Move/copy photos
            for FileToMove = FileName(CaptureYear == Year & ...
                                      CaptureMonth == Month & ...
                                      CameraNo == CameraID)'
                if exist(fullfile(CameraDir,cell2mat(FileToMove)),'file')
                    % file already exists
                    warning('File [%s] already exists',fullfile(CameraDir,cell2mat(FileToMove)))
                else
                    % file not already there 
                    if CreateCopy
                        % Copy
                        copyfile(fullfile(ImageDumpFolder,cell2mat(FileToMove)),CameraDir)
                    else
                        % Move CameraID
                        movefile(fullfile(ImageDumpFolder,cell2mat(FileToMove)),CameraDir)
                    end
                end
            end
        end
    end
end