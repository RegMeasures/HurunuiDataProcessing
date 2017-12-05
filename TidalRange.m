%% Calc basic tidal stats

% Add required directories (and subdirectories)
addpath(genpath('functions'))

% Read lagoon time series (already processed)
LagoonTS = readtable('outputs\LagoonTS.csv');
LagoonTS.DateTime = datetime(LagoonTS.DateTime);

% Calculate tidal peaks and troughs
[HWTimes,HWLevels] = tidePeaks(LagoonTS.DateTime,LagoonTS.SeaLevel);
[LWTimes,LWLevels] = tidePeaks(LagoonTS.DateTime,-LagoonTS.SeaLevel);
LWLevels = -LWLevels;

% For simplicity make them the same length
MinLength = min(size(HWLevels,1),size(LWLevels,1));
HWTimes = HWTimes(1:MinLength);
HWLevels = HWLevels(1:MinLength);
LWTimes = LWTimes(1:MinLength);
LWLevels = LWLevels(1:MinLength);
clear MinLength

% Range
TideRange = HWLevels-LWLevels;

% Check
plot(HWTimes,HWLevels)
hold on
plot(LWTimes,LWLevels)

% Summarise
MHW = mean(HWLevels)
MLW = mean(LWLevels)
MeanRange = MHW - MLW
MeanRange2 = mean(TideRange)

% Plot range distribution
histogram(TideRange)