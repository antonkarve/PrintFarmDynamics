% calculate_metrics.m

% takes results struct and array index of t=5τ, returns metrics struct

function outputMetrics = calculate_metrics(t, results, ss_index)

x = results.x;
xdot = results.xdot;
xddot = results.xddot;

outputMetrics.duration = t(end);

% peak values before ss_index (during transient response)
outputMetrics.peak_transient_x = max(x(1:ss_index,:));
outputMetrics.peak_transient_xdot = max(xdot(1:ss_index,:));
outputMetrics.peak_transient_xddot = max(xddot(1:ss_index,:));

% mean values after ss_index (after 99% transient response decay)
outputMetrics.mean_ss_x = mean(x(ss_index+1:end,:));
outputMetrics.mean_ss_xdot = mean(xdot(ss_index+1:end,:));
outputMetrics.mean_ss_xddot = mean(xddot(ss_index+1:end,:));

% peak values after ss_index (after 99% transient response decay)
outputMetrics.peak_ss_x = max(x(ss_index+1:end,:));
outputMetrics.peak_ss_xdot = max(xdot(ss_index+1:end,:));
outputMetrics.peak_ss_xddot = max(xddot(ss_index+1:end,:));

end