% parse_ode_data.m
% unpacks y array, computes xddot and returns results struct

function results = parse_ode_data(t, y, input_params)

% unpack input_params
M = input_params.M;
C = input_params.C;
K = input_params.K;
F = input_params.F;
L = input_params.p_run.L;

% unpack y to y1 = x and y2 = xdot
x = y(:, 1:L);
xdot = y(:, L+1:end);

% get numerical F_ext magnitudes for all timesteps
F_mag = zeros(L, length(t));
for n = 1:length(t)
    F_mag(:, n) = F(t(n));
end

% compute xddot using ODE
xddot = (M \ (F_mag - C * xdot.' - K * x.')).';

% assemble into output struct
results.x = x;
results.xdot = xdot;
results.xddot = xddot;
end