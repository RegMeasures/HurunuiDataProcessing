function [Channel,RMSE,ExitFlag] = FitChannelQ_4par(Q, E_us, E_ds, Manning)
% Back calculate channel dimensions to best fit observed flows and levels
% Q, E_us and E_ds are vectors of time varying values

OptimFun = @(ChannelParams)ChannelErrorQ_4par(ChannelParams, Q, E_us, E_ds, Manning);
% ChannelParams(1) = Channel.B
% ChannelParams(2) = Channel.Zb_us
% ChannelParams(3) = Channel.Zb_ds
% ChannelParams(3) = Channel.L

lb = [1,-2,-3,10];
ub = [100,3,0,1500];
x0 = [20,0,0,100];

[ChannelParams,~,~,ExitFlag] = lsqnonlin(OptimFun, x0, lb, ub);

%% Get (and optionally plot) the error
error = ChannelErrorQ_4par(ChannelParams, Q, E_us, E_ds, Manning, true);
%error = ChannelErrorQ_4par(ChannelParams, Q, E_us, E_ds, Manning, false);

%% Prep output struct
Channel.B = ChannelParams(1);
Channel.Zb_us = ChannelParams(2);
Channel.Zb_ds = ChannelParams(3);
Channel.L = ChannelParams(4);
Channel.n = Manning;

RMSE = sqrt(mean(error.^2));

end