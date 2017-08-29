% Compare twist

TestFiles = {'E:\Hurunui\PhotoRecord\ImageStore\2015\10\Hurunui1\Hurunui1_15-10-07_15-28-48-75.jpg';...
             'E:\Hurunui\PhotoRecord\ImageStore\2016\01\Hurunui1\Hurunui1_16-01-04_17-03-46-38.jpg';...
             'E:\Hurunui\PhotoRecord\ImageStore\2016\01\Hurunui1\Hurunui1_16-01-13_10-49-18-65.jpg';...
             'E:\Hurunui\PhotoRecord\ImageStore\2016\09\Hurunui1\Hurunui1_16-09-14_18-00-49-56.jpg';...
             'E:\Hurunui\PhotoRecord\ImageStore\2016\10\Hurunui1\Hurunui1_16-10-01_07-31-52-74.jpg';...
             'E:\Hurunui\PhotoRecord\ImageStore\2016\03\Hurunui1\Hurunui1_16-03-01_07-07-32-37.jpg';...
             'E:\Hurunui\PhotoRecord\ImageStore\2016\03\Hurunui1\Hurunui1_16-03-01_10-52-32-92.jpg'};

k          = +0.240;           % k value for barrel distortion correction as used for lensdistort
Resolution = [2592,1944];      % Image size [across,down] (pixels)

for ImageNo = 1:length(TestFiles)
    TestImage = imread(TestFiles{ImageNo});
    
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
                  
    [Twist,Edge] = MeasureTwist1(TestImage,k,Resolution,true)
    
%     CorrectedImage = imtranslate(TestImage,-Twist,'FillValues',nan(3,1));
%     figure
%     imshow(CorrectedImage)
end