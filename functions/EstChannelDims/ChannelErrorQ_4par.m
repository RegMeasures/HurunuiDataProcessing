function Error = ChannelErrorQ_4par(ChannelParams, Q, E_us, E_ds, Manning, PlotError)
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

Q_model = nan(size(E_us));
for i = 1:size(Q,1)
    Q_model(i) = OutletQ(E_us(i), E_ds(i), Channel, 20);
end

if PlotError
    figure
    plot(Q,'-r')
    hold on
    plot(Q_model,'-b')
    legend('observed','modelled')
    ylabel('upstream Q [m^3/s]')
    xlabel('time')
end

Error = Q_model - Q;
end
