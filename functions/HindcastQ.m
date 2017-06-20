function [OutletQ, LagoonVol] = HindcastQ(Hypsometry,TS)
%HINCASTQ Hindcast outlet flow using water balance
%   Perform water balance calculation to calculate outlet flow
%
% Hypsometry = table with columns:
%   1. Elevation [m] (increasing order)
%   2. Area [m2](water surface area at given elevation)
%   3. Volume [m3]
%
% TS = table of observed timeseries data with columns:
%   1. DateTime (increasing)
%   2. WL = lagoon WL [m]
%   3. Qin = Lagoon inflow rate [m/s]
%
% OutletQ = table of hindcast outlet flow rate
%
% CURRENTLY NO ALLOWANCE FOR SEEPAGE!!!!!!

dT = (TS.DateTime(2:end)-TS.DateTime(1:end-1)) * 60*60*24;
Tmid = (TS.DateTime(2:end)+TS.DateTime(1:end-1))/2;

LagoonVol = interp1(Hypsometry.Elevation,Hypsometry.Volume,TS.WL,'spline');
dLagoonVol = LagoonVol(2:end)-LagoonVol(1:end-1);
dSdT = dLagoonVol./dT;
TS.dSdT = [dSdT(1);...
           interp1(Tmid,dSdT,TS.DateTime(2:end-1));...
           dSdT(end)];

OutletQ = TS.Qin - TS.dSdT;

DateTime = (TS.DateTime(2:end)+TS.DateTime(1:end-1))/2;

end

