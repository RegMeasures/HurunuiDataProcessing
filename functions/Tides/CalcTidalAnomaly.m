function [DateTime, Anomaly] = CalcTidalAnomaly(WL_TS, BaroTS)
%CALCTIDALANOMALY 
%   
%
% Richard Measures 2016

% Prepare data for tidal analysis by filling gaps
[DateTime, ObservedWL] = nanfillgaps(WL_TS.DateTime, WL_TS.WL);

% Compute barometric effect
BaroEffect = -100*(BaroTS.Baro-1000)/(1025*9.81);
BaroEffect = interp1(BaroTS.DateTime,BaroEffect,DateTime);

% Do tidal analysis to generate predicted (tidal) TS
Interval = hours(DateTime(2) - DateTime(1));
[~,~,~,PredictWL] =t_tide((ObservedWL - BaroEffect), ...
                           'interval',Interval, 'error','wboot');

% calc anomaly
Anomaly = (ObservedWL - BaroEffect) - PredictWL;

% smooth anomaly
windowSize = round(12/Interval);
Anomaly = filter(ones(windowSize,1)/windowSize,1,Anomaly);

% Plot all
figure
plot(DateTime,ObservedWL,'b-')
hold on
plot(DateTime,PredictWL,'r-')
plot(DateTime,BaroEffect,'k-')
plot(DateTime,Anomaly-0.12,'g-')
hold off
datetickzoom
legend('observed','forecast','barometric effect','anomaly')

end

