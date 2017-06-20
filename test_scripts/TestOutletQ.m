%% Test OutletQ function

E_us = 1;
E_ds = 0;
Channel.B_us = 20;
Channel.B_ds = 20;
Channel.Zb_us = -0.5;
Channel.Zb_ds = -0.5;
Channel.L = 200;
%Channel.K_ds = 0.5;
%Channel.K_us = 0.5;
Channel.n = 0.02;

Q0 = 10;

[Q] = OutletQ(E_us, E_ds, Channel, Q0)

USerror = OutletWL(Q, E_ds, Channel) - E_us