% Add required directories (and subdirectories)
addpath(genpath('..\functions'))
addpath(genpath('..\inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% Compare twist
TestFiles = {'2015\10\Hurunui2\Hurunui2_15-10-07_15-28-52-74.jpg';...
             '2016\01\Hurunui2\Hurunui2_16-01-04_17-03-37-07.jpg';...
             '2016\09\Hurunui2\Hurunui2_16-09-14_09-15-45-24.jpg';...
             '2016\10\Hurunui2\Hurunui2_16-10-01_07-31-43-89.jpg';...
             '2016\03\Hurunui2\Hurunui2_16-03-01_07-07-16-90.jpg';...
             '2016\03\Hurunui2\Hurunui2_16-03-01_10-52-16-83.jpg';...
             '2017\03\Hurunui2\Hurunui2_17-03-02_15-40-15-77.jpg';...
             '2017\12\Hurunui2\Hurunui2_17-12-01_06-23-55-37.jpg'};

for ImageNo = 6%1:length(TestFiles)
    TestImage = imread(fullfile(Config.DataFolder,Config.PhotoFolder,TestFiles{ImageNo}));
    
%     TestImageGray = double(rgb2gray(TestImage));
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
                  
    [Twist,Edge] = measureTwist(TestImage,Config.Cam2,true)
    
%     CorrectedImage = imtranslate(TestImage,-Twist,'FillValues',nan(3,1));
%     figure
%     imshow(CorrectedImage)
end