function [Channel,RMSE,ExitFlag] = FitChannel(Q, E_us, E_ds, Manning)
% Back calculate channel dimensions to best fit observed flows and levels
% Q, E_us and E_ds are vectors of time varying values

OptimFun = @(ChannelParams)ChannelError(ChannelParams, Q, E_us, E_ds, Manning);
% ChannelParams(1) = Channel.B_us
% ChannelParams(2) = Channel.B_ds
% ChannelParams(3) = Channel.Zb_us
% ChannelParams(4) = Channel.Zb_ds
% ChannelParams(5) = Channel.L

lb = [1,1,-2,-2,10];
ub = [200,200,3,2,1500];
x0 = [20,20,0,0,100];

[ChannelParams,~,~,ExitFlag] = lsqnonlin(OptimFun, x0, lb, ub);

%% Get (and optionally plot) the error
%error = ChannelError(ChannelParams, Q, E_us, E_ds, Manning, true);
error = ChannelError(ChannelParams, Q, E_us, E_ds, Manning, false);

%% Prep output struct
Channel.B_us = ChannelParams(1);
Channel.B_ds = ChannelParams(2);
Channel.Zb_us = ChannelParams(3);
Channel.Zb_ds = ChannelParams(4);
Channel.L = ChannelParams(5);
Channel.n = Manning;

RMSE = sqrt(mean(error.^2));

end