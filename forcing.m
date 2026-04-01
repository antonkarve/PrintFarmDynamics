% forcing.m
%{
Defines F(t) handle based on F0 params. When called, F(t) returns a vector
containing F_ext magnitudes by level

Inputs:
type: periodic func type (sin, square, saw)
L: number of shelves (rows)
J: number of printers per shelf (cols)
F0: forcing function amplitude (N)
freq: periodic function frequency (Hz)
phi_j: phase diff between printers on the same shelf
phi_l: phase diff between shelves

Returns:
forceVector: (L, 1) array containing summed shelf forcing functions
%}
function forceHandle = forcing(type, L, J, F0, freq, phi_j, phi_l)
    
omega = 2*pi*freq;

% create phase arrays
level_phases = (0:L-1).' * phi_l;
printer_phases = (0:J-1) * phi_j;
phases = level_phases + printer_phases;

forceHandle = @(t) computeForce(t, type, F0, omega, phases);

end

function forceHandle = computeForce(t, type, F0, omega, phases)

if type == "sin"
    forceMatrix = F0 * sin(omega * t + phases);
elseif type == "square"
    forceMatrix = F0 * square(omega * t + phases);
elseif type == "saw"
    forceMatrix = F0 * sawtooth(omega * t + phases);
else
    error("forcing:InvalidInput", "Value 'type' must be 'sin', 'square' or 'saw'.");
end

forceHandle = sum(forceMatrix, 2);

end