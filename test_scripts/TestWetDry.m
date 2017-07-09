% Test/develop wet area classification

addpath(genpath('..\functions'))
addpath('..\inputs')

%% Inputs
% TestFiles = {'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2015\10\Hurunui1\Hurunui1_15-10-07_15-28-48-75.jpg';...
%              'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2016\01\Hurunui1\Hurunui1_16-01-04_17-03-46-38.jpg';...
%              'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2016\01\Hurunui1\Hurunui1_16-01-13_10-49-18-65.jpg';...
%              'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2016\09\Hurunui1\Hurunui1_16-09-14_18-00-49-56.jpg';...
%              'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2016\10\Hurunui1\Hurunui1_16-10-01_07-31-52-74.jpg';...
%              'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2016\03\Hurunui1\Hurunui1_16-03-01_07-07-32-37.jpg';...
%              'H:\Hapua\Individual_Hapua\Hurunui\PhotoRecord\ImageStore\2016\03\Hurunui1\Hurunui1_16-03-01_10-52-32-92.jpg'};

TestFiles = {'E:\Hurunui\PhotoRecord\HighRes\Hurunui1_15-10-07_15-28-48-75.jpg';...
             'E:\Hurunui\PhotoRecord\HighRes\Hurunui1_16-01-04_17-03-46-38.jpg';...
             'E:\Hurunui\PhotoRecord\HighRes\Hurunui1_16-01-13_10-49-18-65.jpg';...
             'E:\Hurunui\PhotoRecord\HighRes\Hurunui1_16-09-14_18-00-49-56.jpg';...
             'E:\Hurunui\PhotoRecord\HighRes\Hurunui1_16-10-01_07-31-52-74.jpg';...
             'E:\Hurunui\PhotoRecord\HighRes\Hurunui1_16-03-01_07-07-32-37.jpg';...
             'E:\Hurunui\PhotoRecord\HighRes\Hurunui1_16-03-01_10-52-32-92.jpg'};
         
load('FgBgMask1');

WetXY = [1628, 1013];

load('CamSettings')
         
for ImageNo = 1:length(TestFiles)
    
    %% read image
    RawImage = imread(TestFiles{ImageNo});
    
    %% measure Twist
    Twist = MeasureTwist1(RawImage);
    
    %% image classification
    [WetMask, WetBdy] = WetDry2(RawImage, FgBgMask1, WetXY, Twist, true);
%     print('-dpdf',TestFiles{ImageNo}(end-32:end-10))
    
%     %% bdy projection test
%     if ImageNo==1;
%         % load surveyed waters edge
%         SurveyPts = readRtkSurveyCsv('H:\Hapua\Individual_Hapua\Hurunui\Survey\2015-10-07 barrier RTK\Survey_Pts_Beach_Barrier_Oct15.csv');
%         LagoonWE = SurveyPts(3:108,:);
%         MouthWE = SurveyPts(117:131,:);
%         WL = mean(LagoonWE.Elevation);
%         
%         % convert WetBdy to easting northing
%         [BdyEasting, BdyNorthing] = ...
%             ProjectToMap(Cam1, WL, [], WetBdy(:,2), WetBdy(:,1));
%         
%         % plot
%         figure
%         plot(BdyEasting,BdyNorthing,'k-')
%         
%         % overlay surveyed waters edge
%         hold on
%         plot(LagoonWE.Easting, LagoonWE.Northing, 'r-x')
%         plot(MouthWE.Easting, MouthWE.Northing, 'g-x')
%         hold off
%     end
   
end