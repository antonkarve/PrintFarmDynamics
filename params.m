% params.m
% Define all base parameters to be called in other funcs

function p = params()
    p.L = 3; % number of rows/shelves
    p.J = 3; % number of printers per shelf
    p.phi_L = pi/2; % phase diff between forcing func. of consecutive shelves
    p.phi_J = 0; % phase diff between forcing func. of consecutive printers
    p.printerMass = 12.95; % kg, printer + 1kg filament
    p.shelfMass = 3; % kg
    p.k = 8000; % base spring coefficient (N/m)
    p.zeta = 0.02; % damping ratio of metal
    p.c = 19.2; % base damping coefficient (Ns/m)
    p.F0 = 20 * 0.3; % forcing function amplitude (N)
    p.freq = 3.3; % forcing function frequency (Hz)
    p.forcingFunc = 'sin'; % forcing function waveform
    p.y0 = 0; % initial conditions
    p.p_ref = {'L','J','phi_L','phi_J','printerMass','shelfMass','c','k','F0','freq','y0','forcingFunc'};
end