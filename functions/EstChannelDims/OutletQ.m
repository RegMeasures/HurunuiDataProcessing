function [Q] = OutletQ(E_us, E_ds, Channel, Q0)
% OUTLETQ Calculates outlet flow rate from water level and channel details 
% Assumes rectangular cross section shape.

% Define optimisation function
OptimFun = @(Q) (OutletWL(Q, E_ds, Channel)-E_us);

% Set bounds on flow
lb = 0.1;
ub = 1000;

% supress output
opts1=  optimset('display','off');

% Optimise to find flow which gives correct upstream water level
Q = lsqnonlin(OptimFun, Q0, lb, ub, opts1);

end

