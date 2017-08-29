% test radial distort

% Add required directories (and subdirectories)
addpath(genpath('..\functions'))
addpath(genpath('..\inputs'))

% Read input parameters
Config = HurunuiAnalysisConfig;

% Creat an array of points to distort
Resolution = Config.Cam1.Resolution;
X1 = [1:50:Resolution(1)-50,Resolution(1)];
Y1 = [1:50:Resolution(2)-50,Resolution(2)]';
X1 = repmat(X1,[size(Y1,1),1]);
Y1 = repmat(Y1,[1,size(X1,2)]);
X1 = X1(:);
Y1 = Y1(:);

% Center points around 0,0
X1 = X1 - (Resolution(1)+1)/2;
Y1 = Y1 - (Resolution(2)+1)/2;

% Get distorted positions
[X2, Y2] = radialdistort(X1, Y1, Config.Cam1.k, Resolution);

% Plot
plot(X1,Y1,'bx')
hold on
plot(X2,Y2,'rx')
for ii = 1:size(X1,1)
    plot([X1(ii),X2(ii)],[Y1(ii),Y2(ii)],'k-')
end