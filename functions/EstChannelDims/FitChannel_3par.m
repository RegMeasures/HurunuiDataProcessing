function [Channel,RMSE,ExitFlag] = FitChannel_3par(Q, E_us, E_ds, Manning)
% Back calculate channel dimensions to best fit observed flows and levels
% Q, E_us and E_ds are vectors of time varying values

OptimFun = @(ChannelParams)ChannelError_3par(ChannelParams, Q, E_us, E_ds, Manning);
% ChannelParams(1) = Channel.B
% ChannelParams(2) = Channel.Zb
% ChannelParams(3) = Channel.L

lb = [1,-2,10];
ub = [200,3,1500];
x0 = [20,0,100];

[ChannelParams,~,~,ExitFlag] = lsqnonlin(OptimFun, x0, lb, ub);

%% Get (and optionally plot) the error
error = ChannelError_3par(ChannelParams, Q, E_us, E_ds, Manning, true);
%error = ChannelError_3par(ChannelParams, Q, E_us, E_ds, Manning, false);

%% Prep output struct
Channel.B = ChannelParams(1);
Channel.Zb = ChannelParams(2);
Channel.L = ChannelParams(3);
Channel.n = Manning;

RMSE = sqrt(mean(error.^2));

end