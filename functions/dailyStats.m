function [DailyStats] = dailyStats(TsTable)
%DAILYSTATS ouputs daily max, min & mean of tabular timeseries data 
% Richard Measures 2016

% set up struct to hold data
FirstDay = floor(min(TsTable{:,1}));
LastDay = floor(max(TsTable{:,1}));
NoOfDays = LastDay-FirstDay+1;
DailyStats.DateNum = (FirstDay:LastDay)';
DailyStats.DateStr = datestr(DailyStats.DateNum,'dd/mm/yyyy');

% count number of input times within each day
DailyStats.NDataTimes = nan(NoOfDays,1);
for day = 1:NoOfDays
    DailyStats.NDataTimes(day) = sum((TsTable{:,1}>=DailyStats.DateNum(day))&...
                                     (TsTable{:,1}<=DailyStats.DateNum(day)+1));
end

VarNames = TsTable.Properties.VariableNames;
for Var=VarNames(2:end);
    VarMean = nan(NoOfDays,1);
    VarMin = nan(NoOfDays,1);
    VarMax = nan(NoOfDays,1);
    for day = 1:NoOfDays
        DayData = TsTable.(Var{1})((TsTable{:,1}>=DailyStats.DateNum(day))&...
                                   (TsTable{:,1}<=DailyStats.DateNum(day)+1));
        VarMean(day) = mean(DayData);
        VarMin(day) = min(DayData);
        VarMax(day) = max(DayData);
    end
    DailyStats.(['Mean',Var{1}]) = VarMean;
    DailyStats.(['Min',Var{1}]) = VarMin;
    DailyStats.(['Max',Var{1}]) = VarMax;
end

% convert output to table
DailyStats=struct2table(DailyStats);
end

