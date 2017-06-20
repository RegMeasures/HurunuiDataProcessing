function [h] = solveDsEnergy(Q,B,E,Zb)
% Solve for (critical-subcritical) downstream water level from total energy
% and channel details

% (E-Zb) = h + q^2 / (2*g*h^2)
% h + q^2 / (2*g*h^2) - (E-Zb) = 0 = y
% dy/dh = 1 - q^2 / (2*g*h^3)

g = 9.81;
q = Q/B;

% initial guess
h = E-Zb;

% iterate using Newton-Raphson
iteration = 0;
iterationLimit = 100;
y = h + q^2 / (2*g*h^2) - (E-Zb);
while abs(y) > 0.001 && iteration < iterationLimit; % while error > 1mm
    iteration = iteration + 1;
    dydh = 1 - q^2 / (2*g*h^3);
    h = h - y/dydh;
    y = h + q^2 / (2*g*h^2) - (E-Zb);
end

% check WL greater than critical
h_crit = (q/sqrt(g))^(2/3);

if isnan(h) || h<h_crit
    h = h_crit;
end

end