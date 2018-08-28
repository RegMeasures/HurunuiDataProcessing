function [DailyStats] = dailyStats(TsTable)
%DAILYSTATS ouputs daily max, min & mean of tabular timeseries data 
% Richard Measures 2016

% set up struct to hold data
FirstDay = dateshift(min(TsTable{:,1}),'start','day');
LastDay = dateshift(max(TsTable{:,1}),'start','day');
NoOfDays = days(LastDay-FirstDay)+1;
DailyStats.Date = FirstDay + days(0:NoOfDays-1)';
DailyStats.Date.Format = 'dd/MM/yyyy';

% count number of input times within each day
DailyStats.NDataTimes = nan(NoOfDays,1);
for dayNo = 1:NoOfDays
    DailyStats.NDataTimes(dayNo) = ...
        sum((TsTable{:,1} >= DailyStats.Date(dayNo))&...
            (TsTable{:,1} <= DailyStats.Date(dayNo)+days(1)));
end

VarNames = TsTable.Properties.VariableNames;
for Var=VarNames(2:end);
    VarMean = nan(NoOfDays,1);
    VarMin = nan(NoOfDays,1);
    VarMax = nan(NoOfDays,1);
    for dayNo = 1:NoOfDays
        DayData = TsTable.(Var{1})((TsTable{:,1} >= DailyStats.Date(dayNo))&...
                                   (TsTable{:,1} <= DailyStats.Date(dayNo)+days(1)));
        VarMean(dayNo) = mean(DayData);
        VarMin(dayNo) = min(DayData);
        VarMax(dayNo) = max(DayData);
    end
    DailyStats.(['Mean',Var{1}]) = VarMean;
    DailyStats.(['Min',Var{1}]) = VarMin;
    DailyStats.(['Max',Var{1}]) = VarMax;
end

% convert output to table
DailyStats=struct2table(DailyStats);
end

