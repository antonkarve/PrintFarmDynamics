% ode_fun.m

% Matrix calculations, solving state-space RHS for ode45

function dydt = ode_fun(t, y, input_params)
    arguments
        t double
        y (:,1) double
        input_params struct
    end

% Computes current timestep state derivates given t, y input from ode45.

% unpack input params struct
M = input_params.M;
C = input_params.C;
K = input_params.K;
F = input_params.F;

% get number of shelf rows from M matrix
L = size(M, 1);

% dydt is a vector [y1'; y2']
% derivative y1' = y2
% derivative y2' = (1/M)(F - Cy2 - Ky1)
y1 = y(1:L); % NOT derivative
y2 = y(L+1:end); % NOT derivative

dydt = [y2; M \ (F(t) - C * y2 - K * y1)];

end