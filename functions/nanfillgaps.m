function [DateTime2, Data2] = nanfillgaps(DateTime, Data)
%NANFILLGAPS Gap fill observed record with NaN values
%   Modifies timeseries data so that any missing timesteps are included but
%   with NaN data values
%
% DateTime = N x 1 matrix of datenum values
% Data = N x Cols matrix of data values
%
% DateTime2 = N2 x 1 matrix of datenum values (with no gaps)
% Data2 = N2 x Cols matrix of data values (with NaNs in place of missing
%         data)

Interval = (DateTime(2,1)-DateTime(1,1))*24*3600;
DataSequence = round(((DateTime(:,1) - DateTime(1,1)) * 24 * 3600) / Interval) + 1;

DateTime2 =DateTime(1,1) + (0:DataSequence(end)-1)' * Interval/(24*3600);
Data2 = nan(DataSequence(end),size(Data,2));
Data2(DataSequence,:) = Data;
end

