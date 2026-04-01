% modal_analysis.m

%{ 
Calculates natural (undamped) frequencies, mode shapes and decay times of each rack level
- Natural frequencies: undamped resonant frequencies of the rack.

- Mode shapes: relative angular displacements (of the displacement
waveforms) of each level, for each natural frequency.
    - eg: L1 -0.2 rad, L2 0 rad, L 0.2 rad means L1 and L3 are moving in opposite directions while L2 is stationary.
    - Horizontally arranged vectors, where each column corresponds to a
    specific natural frequency.

- Decay time τ: time taken for natural response to decay to e^-1 of
original magnitude
%}

function [phi, omega, tau] = modal_analysis(input_params)

[phi, omega2] = eig(input_params.K, input_params.M);
omega = diag(sqrt(omega2));

% calculate time constant tau (time taken for ~63.2% decay)
tau = 1 ./ (input_params.p_run.zeta * omega);

end