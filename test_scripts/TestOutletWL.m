%% Test OutletWL function

% Subcritical

Q = 10;
E_ds = 0;
Channel.B_us = 20;
Channel.B_ds = 20;
Channel.Zb_us = -0.5;
Channel.Zb_ds = -0.5;
Channel.L = 200;
%Channel.K_ds = 0.5;
%Channel.K_us = 0.5;
Channel.n = 0.04;

%[h_ds] = solveDsEnergy(Q,Channel.B_ds,E_ds,Channel.Zb_ds)
%Echeck_ds = h_ds + Channel.Zb_ds + (Q/(Channel.B_ds*h_ds))^2 / (2*9.81)

[E_us] = OutletWL(Q, E_ds, Channel)

%% Supercritical

Q = 10;
E_ds = 0;
Channel.B_us = 10;
Channel.B_ds = 10;
Channel.Zb_us = 3;
Channel.Zb_ds = -0.5;
Channel.L = 200;
Channel.K_ds = 0.5;
Channel.K_us = 0.5;
Channel.n = 0.04;

[E_us] = OutletWL(Q, E_ds, Channel)

%% critical at downstream

Q = 10;
E_ds = -1;
Channel.B_us = 10;
Channel.B_ds = 10;
Channel.Zb_us = -0.5;
Channel.Zb_ds = -0.5;
Channel.L = 200;
Channel.K_ds = 0.5;
Channel.K_us = 0.5;
Channel.n = 0.04;

[E_us] = OutletWL(Q, E_ds, Channel)
