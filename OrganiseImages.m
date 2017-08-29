% ORGANISEIMAGES   Sort photos into preffered directory structure

%ImageDump = 'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\HighRes'; % move images from here
%ImageDump = 'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\Camera 2';
ImageDump = 'C:\Users\measuresrj\OneDrive - NIWA\pics';

ImageStore = 'C:\Users\measuresrj\OneDrive - NIWA\Hapua\Hurunui\PhotoRecord\ImageStore'; % store organised images here

CreateCopy = true; % true = copy, false = move

% Get list of image files
PhotoFileList = dir(fullfile(ImageDump,'Hurunui*.jpg'));

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
                        copyfile(fullfile(ImageDump,cell2mat(FileToMove)),CameraDir)
                    else
                        % Move CameraID
                        movefile(fullfile(ImageDump,cell2mat(FileToMove)),CameraDir)
                    end
                end
            end
        end
    end
end