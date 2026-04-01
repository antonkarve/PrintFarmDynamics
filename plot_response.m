% plot_response.m
% plots an individual time series of system response

clear; % comment this out if you want to reuse existing sim data (eg. editing the plot)

% Set up params
p = params();

p_run = p; % copy params into p_run
L = p_run.L;
tdelta = 0.001; % set time resolution

% change any p_run params here
% p_run.forcingFunc = 'sin';
% p_run.freq = 3.18;

% assemble input_params for ode_fun
[M, C, K] = assemble_matrices(p_run.L, p_run.J, p_run.shelfMass, p_run.printerMass, p_run.zeta, p_run.k);
F = forcing(p_run.forcingFunc, p_run.L, p_run.J, p_run.F0, p_run.freq, p_run.phi_J, p_run.phi_L);
input_params = struct('M',M,'C',C,'K',K,'F',F,'p_run',p_run);

% set up initial conditions (edit this if specific initial
% conditions are needed)
y0 = [zeros(p_run.L, 1);zeros(p_run.L, 1)];

% set up tspan based on slowest decay time
[~, omega, tau] = modal_analysis(input_params);
tspan = 0:tdelta:(5*max(tau))+(5/p_run.freq); % 5x decay time + 5x forcing func periods

% simulate with input_params
[t,y] = ode45(@(t,y) ode_fun(t, y, input_params), tspan, y0);

% parse output array to get organised results struct
results = parse_ode_data(t, y, input_params);

x = results.x;
xdot = results.xdot;
xddot = results.xddot;

% plot graphs
figure;
tiledlayout(3, 1)
nexttile

% displacement plot
hold on
for level = 1:L
    plot(t, x(:,level), '-', 'DisplayName', sprintf('Level %d', level))
end
title('Displacement plot');
xlabel('Time t');
ylabel('Displacement x');
legend;

for i = 1:5
    xline(i*max(tau),'-',sprintf("%dτ",i),'LabelVerticalAlignment','bottom','HandleVisibility','off');
end
hold off

nexttile

% velocity plot
hold on
for level = 1:L
    plot(t, xdot(:,level), '-', 'DisplayName', sprintf('Level %d', level))
end
title('Velocity plot');
xlabel('Time t');
ylabel('Velocity xdot');
legend;
hold off

nexttile

% acceleration plot
hold on
for level = 1:L
    plot(t, xddot(:,level), '-', 'DisplayName', sprintf('Level %d', level))
end
title('Acceleration plot');
xlabel('Time t');
ylabel('Acceleration xddot');
legend;
hold off

annotations = sprintf("Params: L = %d, J = %d, phi_L = %dπ rad, phi_J = %dπ rad, forcingFunc = %s, freq = %d Hz, k = %d N/m, zeta = %d Ns/m",p_run.L,p_run.J,p_run.phi_L/pi,p_run.phi_J/pi,p_run.forcingFunc,p_run.freq,p_run.k,p_run.zeta);
annotation('textbox', [0, 0, 0.8, 0.05], 'String', annotations, 'EdgeColor', 'none', 'HorizontalAlignment', 'left','Units','normalized');
