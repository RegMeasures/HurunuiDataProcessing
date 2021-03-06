% Add required directories (and subdirectories)
addpath(genpath('..\functions'))
addpath(genpath('..\inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% Compare twist
TestFiles = {'2015\10\Hurunui1\Hurunui1_15-10-07_15-28-48-75.jpg';...
             '2016\01\Hurunui1\Hurunui1_16-01-04_17-03-46-38.jpg';...
             '2016\01\Hurunui1\Hurunui1_16-01-13_10-49-18-65.jpg';...
             '2016\09\Hurunui1\Hurunui1_16-09-14_18-00-49-56.jpg';...
             '2016\10\Hurunui1\Hurunui1_16-10-01_07-31-52-74.jpg';...
             '2016\03\Hurunui1\Hurunui1_16-03-01_07-07-32-37.jpg';...
             '2016\03\Hurunui1\Hurunui1_16-03-01_10-52-32-92.jpg';...
             '2017\03\Hurunui1\Hurunui1_17-03-02_15-40-47-65.jpg';...
             '2017\12\Hurunui1\Hurunui1_17-12-01_06-24-28-34.jpg'};

for ImageNo = 1:length(TestFiles)
    TestImage = imread(fullfile(Config.DataFolder,Config.PhotoFolder,TestFiles{ImageNo}));
    
    TestImageGray = double(rgb2gray(TestImage));
    
%     Sharpness(ImageNo) = estimate_sharpness(TestImageGray);
%     Contrast(ImageNo) = std(TestImageGray(:));
%     Brightness(ImageNo) = mean(TestImageGray(:));
%     figure
%     imshow(TestImage)
%     text(20,20, ...
%          sprintf('Sharpness = %1.2f, Contrast = %1.2f, Brightness = %1.2f', ...
%          Sharpness(ImageNo), Contrast(ImageNo), Brightness(ImageNo)),...
%          'units','pixels','HorizontalAlignment','left',...
%          'BackgroundColor','w');
                  
    [Twist,Edge] = MeasureTwist1(TestImage,Config.Cam1.k,Config.Cam1.Resolution,true)
    
%     CorrectedImage = imtranslate(TestImage,-Twist,'FillValues',nan(3,1));
%     figure
%     imshow(CorrectedImage)
end