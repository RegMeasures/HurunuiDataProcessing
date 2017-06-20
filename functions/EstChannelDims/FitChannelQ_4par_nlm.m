function [ChannelParams] = FitChannelQ_4par_nlm(Q, E_us, E_ds, Manning)
% Back calculate channel dimensions to best fit observed flows and levels
% Q, E_us and E_ds are vectors of time varying values

OptimFun = @(ChannelParams,X)ChannelQ_4par_nlm(ChannelParams, X(:,1), X(:,2), Manning);
% ChannelParams(1) = Channel.B
% ChannelParams(2) = Channel.Zb_us
% ChannelParams(3) = Channel.Zb_ds
% ChannelParams(3) = Channel.L

x0 = [20,0,0,100];

[ChannelParams] = fitnlm([E_us,E_ds],Q,OptimFun, x0);

%% Get (and optionally plot) the error
%error = ChannelErrorQ_4par(ChannelParams, Q, E_us, E_ds, Manning, true);
%error = ChannelErrorQ_4par(ChannelParams, Q, E_us, E_ds, Manning, false);

% %% Prep output struct
% Channel.B = ChannelParams(1);
% Channel.Zb_us = ChannelParams(2);
% Channel.Zb_ds = ChannelParams(3);
% Channel.L = ChannelParams(4);
% Channel.n = Manning;

%RMSE = sqrt(mean(error.^2));

end