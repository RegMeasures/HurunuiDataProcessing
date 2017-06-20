function [E_us] = OutletWL(Q, E_ds, Channel)
% Calculate u/s head for channel of known flow and dimensions

g = 9.81;

% q = Q/B                                                               (1)

%% If u/s critical 
% (minimum E_us occurs when there is critical flow at upstream end of 
% channel)

% Energy equation
% (E - Zb) = h + v^2 / (2*g)
% (E - Zb) = h + q^2 / (2*g*h^2)                                        (2)

% Gradient of energy equation vs depth
% d(E - Zb)/dh = 1 - q^2/(g*h^3)                                        (3)

% (3) == 0 for critical flow therefor
% q_crit^2 = g * h_crit^3                                               (4)

% from (2) and (4)
% (E_crit - Zb) = (q^2/g)^(1/3) + q^2 / (2*g*(q^2/g)^(2/3)) 
% (E_crit - Zb) = 1.5 * (q^2/g)^(1/3)                                   (5)

E_us_crit = Channel.Zb_us + 1.5 * ((Q/Channel.B_us)^2 / g)^(1/3);

%% If subcritical

% get ds water level (assuming subcritical)
[h_ds] = solveDsEnergy(Q,Channel.B_ds,E_ds,Channel.Zb_ds);

% calculate backwater curve using standard step method and chezy roughness: v=C.(RS)^0.5

tol = 0.00001; % tolerance on each step equals 0.001 mm
nSteps = 100;

% split channel into steps of length dX
dX = Channel.L/nSteps;

% create arrays for channel data at each step
h = nan(nSteps+1,1);
Zb = Channel.Zb_us + (0:1/nSteps:1)' .* (Channel.Zb_ds - Channel.Zb_us);
B = Channel.B_us + (0:1/nSteps:1)' .* (Channel.B_ds - Channel.B_us);
E = nan(nSteps+1,1);
S = nan(nSteps+1,1);

% populate downstream info
h(end) = h_ds;
% E = h + Zb + v^2/2g
%E(end) = E_ds;
E(end) = h(end) + Channel.Zb_ds + (Q/(B(end)*h(end)))^2 / (2*g);
% Q = B*h^(5/3)*S^(1/2)/n  Manning with wide channel assumption
% S = (Q^2 * n^2) / (B^2 * h^(10/3))
S(end) = (Q^2 * Channel.n^2) / (B(end)^2 * h(end)^(10/3));

% loop through each step working upstream
for ii = nSteps:-1:1
    
    % initial estimate depth at h(ii)
    %h(ii) = h(ii+1);
    h(ii) = h(ii+1) + S(end)*dX; 
    
    % check initial estimate is greater than critical
    %h_crit = ((Q/B(ii))/sqrt(g))^(2/3);
    %h(ii) = max(h(ii),h_crit+0.001);
    
    % iterate (Newton-Raphson) till guess is within tolerance
    y = h(ii) + h(ii)^-2 * Q^2/(2*g*B(ii)^2) - h(ii)^(-10/3) * dX*Q^2*Channel.n^2/(2*B(ii)^2) + Zb(ii) - E(ii+1) - dX * S(ii+1)/2;
    while abs(y) > tol
        % E1 = E2 + dX * ((S1 + S2)/2)
        % h1 + z1 + v1^2/(2 * g) - dX * S1/2 = E2 + dX * S2/2 
        % v = Q / (B * h)
        % S = (Q^2 * n^2) / (B^2 * h^(10/3))
        
        % h1 + z1 + (Q/(B1*h1))^2 / (2*g) - dX * (Q^2 * n^2) / (2 * B1^2 * h1^(10/3)) - E2 - dx * S2/2 = 0 = y
        % h1 + h1^-2 * Q^2/(2*g*B1^2) - h1^(-10/3) * dX*Q^2*n^2/(2*B1^2) + z1 - E2 - dx * S2/2 = 0
        % dy/dh1 = 1 - h1^-3 * Q^2/(g*B1^2) + (10/3)*h1^(-13/3) * dX*Q^2*n^2/(2*B1^2)
        
        dydh = 1 - h(ii)^-3 * Q^2/(g*B(ii)^2) + (10/3)*h(ii)^(-13/3) * dX*Q^2*Channel.n^2/(2*B(ii)^2);
        
        h(ii) = h(ii) - y/dydh;  
        
        y = h(ii) + h(ii)^-2 * Q^2/(2*g*B(ii)^2) - h(ii)^(-10/3) * dX*Q^2*Channel.n^2/(2*B(ii)^2) + Zb(ii) - E(ii+1) - dX * S(ii+1)/2;
    end
    
    E(ii) = h(ii) + Zb(ii) + (Q/(B(ii)*h(ii)))^2 / (2*g);
    S(ii) = (Q^2 * Channel.n^2) / (B(ii)^2 * h(ii)^(10/3));
end
    
E_us = E(1);

% plot(0:dX:Channel.L,E,'r')
% hold on
% plot(0:dX:Channel.L,h+Zb,'k')
% legend('Total energy','Water level')
% ylabel('Elevation [m]')
% xlabel('Distance along outlet channel [m]')

%% decide which
if ~isreal(E_us) || E_us<E_us_crit
    E_us = E_us_crit;
end

