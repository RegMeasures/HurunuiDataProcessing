% TestHindcastQ


% Make up Lagoon properties table
Elevation = [0:0.5:4]';
Area = [0; 5000; 10000; 20000; 35000; 45000; 52000; 60000; 70000];

Volume = zeros(size(Area));
for i = 2:size(Area)
    Volume(i) = Volume(i-1) + ...
               (Elevation(i)-Elevation(i-1)) * (Area(i)+Area(i-1))/2;
end

Lagoon = table(Elevation,Area,Volume);

%plot(Lagoon.Area,Lagoon.Elevation)
%plot(Lagoon.Volume,Lagoon.Elevation)

% Make up TS data
StartDate = datenum(2016,1,1,0,0,0);
DateTime = [StartDate:1/24/4:StartDate+1]';
WL = 1.5+0.5*sin(([0:0.25:24]')/12.5*2*pi());
Qin = 40*ones(size(DateTime));

TS = table(DateTime,WL,Qin);

%plot(DateTime,WL)

%clean up
clear Elevation Area Volume StartTime DateTime WL Qin


% Test the function
OutletQ = HindcastQ(Lagoon,TS);

% Check the test still works if I only feed it 2 time steps
OutletQ = HindcastQ(Lagoon,TS(5:6,:));