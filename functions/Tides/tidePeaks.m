function [PeakTimes,PeakLevels] = tidePeaks(WlDateTime,WlValue,Period)
% TIDEPEAKS Get list of high tides from timeseries of water level.
% Robust but slow approach accepts varying timesteps in input data and
% missing data
%
% Inputs:
%    WlDateTime = Times data are available (corresponds to WlValue),
%                 specified as a DateTime array
%    WlValue    = Water level timeseries corresponding to WlDateTime
%    Period     = Approximate duration between peaks (specified as a 
%                 "duration" variable (Optional, default = 12.4 hours)
%
% Outputs:
%    PeakTimes  = DateTime array corresponding to identified peaks
%    PeakLevels = Array of peak values
%
% Richard Measures, NIWA, 2017
% richard.measures@niwa.co.nz
%
% see also: DATETIME, DURATION

% set default period if not specified
if ~exist('Period','var') || isempty(Period)
    Period = hours(12.4);
end

% validate
if any(size(WlDateTime) ~= size(WlValue))
    error('input WlDateTime and WlValue arrays must be the same size')
end

% remove any nan data
WlDateTime = WlDateTime(~isnan(WlValue));
WlValue = WlValue(~isnan(WlValue));

% find local maxima (quick initial screening!)
LocalMaxima = [false; WlValue(2:end) >= WlValue(1:end-1)] & ...
              [WlValue(1:end-1) >= WlValue(2:end); false];
PeakTimes = WlDateTime(LocalMaxima);
PeakLevels = WlValue(LocalMaxima);

PeakMask = false(size(PeakLevels));
% loop to identify tide peaks
for LevelNo = 1:size(PeakLevels(:),1)
    if PeakLevels(LevelNo) >= ...
            max(PeakLevels(PeakTimes > (PeakTimes(LevelNo)-Period*0.7) & ...
                           PeakTimes < (PeakTimes(LevelNo)+Period*0.7)))
                PeakMask(LevelNo) = true;
    end
end
PeakTimes = PeakTimes(PeakMask);
PeakLevels = PeakLevels(PeakMask);

% check for double ups
SinglePeaks = [true;(PeakTimes(2:end) - PeakTimes(1:end-1)) > Period*0.7];
PeakTimes = PeakTimes(SinglePeaks);
PeakLevels = PeakLevels(SinglePeaks);

% test plot
% figure
% plot(WlDateTime,WlValue,'b-')
% hold on
% plot(PeakTimes,PeakLevels,'or')
% hold off

end