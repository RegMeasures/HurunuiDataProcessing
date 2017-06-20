function Error = ChannelError_4par(ChannelParams, Q, E_us, E_ds, Manning, PlotError)
% Return error in US WL associated with current guess for channel
% dimensions

if ~exist('PlotError','var')
    PlotError = false;
end

Channel.B_us = ChannelParams(1);
Channel.B_ds = ChannelParams(1);
Channel.Zb_us = ChannelParams(2);
Channel.Zb_ds = ChannelParams(3);
Channel.L = ChannelParams(4);
Channel.n = Manning;

E_us_model = nan(size(E_us));
for i = 1:size(Q,1)
    E_us_model(i) = OutletWL(Q(i), E_ds(i), Channel);
end

if PlotError
    figure
    plot(E_us,'-r')
    hold on
    plot(E_us_model,'-b')
    legend('observed','modelled')
    ylabel('upstream WL [m-LVD]')
    xlabel('time')
end

Error = E_us_model - E_us;
end
