function [WL] = AstronomicTide(ConstituentsFile, DateTime, TimeZone)
% ASTRONOMICTIDE Predict astronomic tide from constituents
%   [WL] = AstronomicTide('FileName.cns', DateTime, TimeZone) returns
%   astronomic tidal water level (relative to mean tide level) for times
%   specified by DateTime vector of datenum values using constituents read
%   from the *.cns file. TimeZone is optional field specifying Timezone of
%   DateTime values (default = 0 hours, NZ = 12 hours).
%
%   Notes:
%   Requires the t_tide t_predict function
%
%   Richard Measures 2016
%      
%   see also ReadCns t_predict t_tide

% set defaults
if ~exist('TimeZone','var')
    TimeZone = 0;
end

% read constituents from file
[Constituent,Amplitude,Phase] = ReadCns(ConstituentsFile);

% get details of each constituent
load('t_constituents', 'const');

% set up parameters to use t_tide t_predict function
NoOfConst = size(Constituent,1);
FREQ = nan(NoOfConst,1);
for ii = 1:NoOfConst
    FREQ(ii) = const.freq(strcmp(Constituent(ii),const.name));
end
TIDECON = nan(NoOfConst,4);
TIDECON(:,1) = Amplitude;
TIDECON(:,3) = Phase;

% Predict water levels using t_predict function
WL = t_predic(DateTime - TimeZone/24,...
              Constituent,FREQ,TIDECON);

end