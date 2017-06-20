function Q_model = ChannelQ_4par_nlm(ChannelParams, E_us, E_ds, Manning)
% Return Q associated with current guess for channel
% dimensions

Channel.B_us = ChannelParams(1);
Channel.B_ds = ChannelParams(1);
Channel.Zb_us = ChannelParams(2);
Channel.Zb_ds = ChannelParams(3);
Channel.L = ChannelParams(4);
Channel.n = Manning;

Q_model = nan(size(E_us));
for i = 1:size(E_us,1)
    Q_model(i) = OutletQ(E_us(i), E_ds(i), Channel, 20);
end

end
