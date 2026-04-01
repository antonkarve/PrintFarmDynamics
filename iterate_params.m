% iterate_params.m

% Builds time series data based on inputted parameter ranges using ndgrid.
%{
Inputs:
- fixed: struct containing all fixed params
- sweep1/2: structs containing params to iterate through
    - field = param name (must match params.m name conventions)
    - value = array of sweep values
- tdelta: time resolution of simulation (default 0.001)

Outputs:
- results_summary: struct array containing:
    - .summary : summary metrics for run i (max x, xddot, steady state values)
    - .params : specific parameter set for run i
%}
function results_summary = iterate_params(p_ref, fixed, sweep1, sweep2, tdelta)
    arguments
        p_ref cell
        fixed struct
        sweep1 struct
        sweep2 struct = struct([])
        tdelta double = 0.001
    end

% input validation: check that all structs are scalar (1x1 structs)
if ~isscalar(fixed)
    error("iterate_params:InvalidInput", "fixed struct is not scalar.")
elseif ~isscalar(sweep1)
    error("iterate_params:InvalidInput", "sweep1 struct is not scalar.")
elseif ~isscalar(sweep2) && ~isempty(sweep2)
    error("iterate_params:InvalidInput", "sweep2 struct is not scalar.")
end

% input validation: check that all required fields are filled
received_fields = [fieldnames(fixed);fieldnames(sweep1);fieldnames(sweep2)];
deviations = setdiff(p_ref,received_fields);
if ~isempty(deviations)
    error("iterate_params:IncompleteInput", "Input missing the following fields: %s", strjoin(deviations, ', '))
end

% create sweep_matrix based on sweep requirements
if ~isscalar(sweep2) % sweep2 not populated, 1D sweep
    sweep1_mat = struct2array(sweep1);
    sweep2_mat = 0;
else % sweep2 populated, 2D sweep
    [sweep1_mat, sweep2_mat] = ndgrid(struct2array(sweep1),struct2array(sweep2));
end

% preallocate results_summary struct array using template struct
n_runs = size(sweep1_mat,1) * size(sweep1_mat,2);
template.params = struct();
template.summary = struct();
results_summary = repmat(template, size(sweep1_mat,1), size(sweep1_mat,2));

if sweep2_mat == 0 % 1D sweep
    for i = 1:1:length(sweep1_mat)
        fprintf("Run %d of %d\n", i, n_runs)

        % set up p_run with fixed and sweep params
        p_run = fixed; % copy fixed params into p_run
        sweep_field = fieldnames(sweep1);
        p_run.(sweep_field{1}) = sweep1_mat(i);

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
        ss_index = ceil(5*max(tau)/tdelta); % index at which transient response has decayed 99%

        % simulate with run input_params
        [t,y] = ode45(@(t,y) ode_fun(t, y, input_params), tspan, y0);

        % parse output array to get organised results struct
        results = parse_ode_data(t, y, input_params);

        % get key metrics from results struct
        run_metrics = calculate_metrics(t, results, ss_index);

        % load run summary metrics into summary array
        results_summary(i).params = p_run;
        results_summary(i).summary = run_metrics;
        results_summary(i).natfreq = omega/(2*pi);

    end

else % 2D sweep
    size(sweep1_mat)
    size(sweep2_mat)
    for i = 1:1:size(sweep1_mat,1) % row iteration
        for j = 1:1:size(sweep1_mat, 2) % col iteration
            fprintf("Run %d of %d\n", (i-1)*size(sweep1_mat,2) + j, n_runs)

            % set up p_run with fixed and sweep params
            p_run = fixed; % copy fixed params into p_run
            sweep1_field = [fieldnames(sweep1)];
            sweep2_field = [fieldnames(sweep2)];
            p_run.(sweep1_field{1}) = sweep1_mat(i,j);
            p_run.(sweep2_field{1}) = sweep2_mat(i,j);
    
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
            ss_index = ceil(5*max(tau)/tdelta); % index at which transient response has decayed 99%

            % simulate with run input_params
            [t,y] = ode45(@(t,y) ode_fun(t, y, input_params), tspan, y0);
    
            % parse output array to get organised results struct
            results = parse_ode_data(t, y, input_params);
    
            % get key metrics from results struct
            run_metrics = calculate_metrics(t, results, ss_index);
    
            % load run summary metrics into summary array
            results_summary(i, j).params = p_run;
            results_summary(i, j).summary = run_metrics;
            results_summary(i, j).natfreq = omega/(2*pi);
        end
    end
end
