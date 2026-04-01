% freq_response.m

% Calculates how each level responds to various forcing frequencies
% note: not being used in current computations

function amplitude = freq_response(omegas, M, C, K, F0)

% preallocate matrix for speed
X = zeros(size(M, 1), length(omegas));

% loop through omega range and calculate steady state displacement amplitudes
for n = 1:length(omegas)
    w = omegas(n);
    Z = -w^2 * M + 1i * w * C + K;
    X(:, n) = Z \ F0;
end

amplitude = abs(X);