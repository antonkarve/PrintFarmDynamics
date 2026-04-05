% main.m
% primary script to produce 2D and 3D summary plots for analysis

new_simulation = true; % set to true if generating new data, false if plotting with old data

if new_simulation
    clear;
    new_simulation = true;
end

% Set up params
p = params();

% set simulation time resolution
tdelta = 0.001;

% set print failure threshold (displacement)
x_fail = 2e-3; % metres
xddot_fail = 1; % m/s^2

% set up sweep param(s)
sweep1_field = 'freq';
sweep1_min = 0.5;
sweep1_max = 15;
sweep1_step = 0.5;
sweep1.(sweep1_field) = sweep1_min:sweep1_step:sweep1_max;

multi_sweep = false; % set to true for 2D sweep, false for 1D sweep (only sweep1)
sweep2_field = 'phi_J';
sweep2_min = 0;
sweep2_max = pi;
sweep2_step = pi/12;

% set observation metric (for vertical axis in plots)
% choices: 'peak_ss_x', 'peak_ss_xddot', 'mean_ss_x', 'mean_ss_xddot',
% 'peak_transient_x', 'peak_transient_xddot'
observation_metric = 'peak_ss_x';

if multi_sweep
    sweep2.(sweep2_field) = sweep2_min:sweep2_step:sweep2_max;
else
    sweep2 = struct([]);
end

% set up fixed params
fixedParams = struct('L',p.L,'J',p.J,'phi_L',p.phi_L,'phi_J',p.phi_J,'printerMass',p.printerMass,'shelfMass',p.shelfMass,'zeta',p.zeta,'k',p.k,'c',p.c,'F0',p.F0,'freq',p.freq,'y0',p.y0,'forcingFunc',p.forcingFunc);

if new_simulation
    % run simulation
    results_summary = iterate_params(p.p_ref,fixedParams,sweep1,sweep2,tdelta);
end

if multi_sweep % 2D sweep
    % pre-load arrays for 3D plotting
    sweep1_len = length(sweep1.(sweep1_field));
    sweep2_len = length(sweep2.(sweep2_field));
    Z = zeros(sweep1_len, sweep2_len);
    X = Z;
    Y = Z;
    
    % interpolated sweep axes values
    [Xq,Yq] = ndgrid(sweep1_min:sweep1_step/10:sweep1_max, sweep2_min:sweep2_step/10:sweep2_max);

    % set z-axis metric
    z_axis_param = observation_metric;

    for level = 1:p.L % creates 1 figure per level

        % set up X, Y, Z plotting matrices using results_summary
        for i = 1:1:size(results_summary,1)
            for j = 1:1:size(results_summary,2)

                S = results_summary(i,j).summary;
                P = results_summary(i,j).params;
                Q = results_summary(i,j).natfreq;
                
                X(i,j) = P.(sweep1_field);
                Y(i,j) = P.(sweep2_field);
                Z(i,j) = S.(z_axis_param)(:,level);
            end
        end
        
        % calculate interpolated z-values
        % use linear interpolation if sweeping across discreet values (L/J)
        if ismember("L",{sweep1_field,sweep2_field}) || ismember("J",{sweep1_field,sweep2_field})
            interpole = interpn(X,Y,Z,Xq,Yq,"linear");
        else % use spline interpolation for continous value sweeps
            interpole = interpn(X,Y,Z,Xq,Yq,"spline");
        end

        % divide axis by pi if sweeping over phi_L or phi_J, reflect on
        % axis label
        if isequal("phi_L",sweep1_field) || isequal("phi_J",sweep1_field)
            Xq_plot = Xq / pi;
            sweep1_label = sweep1_field + "/π";
        else
            Xq_plot = Xq;
            sweep1_label = sweep1_field;
        end
        if isequal("phi_L",sweep2_field) || isequal("phi_J",sweep2_field)
            Yq_plot = Yq / pi;
            sweep2_label = sweep2_field + "/π";
        else
            Yq_plot = Yq;
            sweep2_label = sweep2_field;
        end

        % create surface plot
        figure;
        surf(Xq_plot,Yq_plot,interpole)

        xlabel("X: " + sweep1_label);
        ylabel("Y: " + sweep2_label);
        zlabel("Z: " + z_axis_param + " at L=" + level, 'Interpreter','none');
        
        % set x,y,z display limits if needed
        % xlim([0,15]);
        % ylim([0,2]);
        % zlim([0,5]);
        
        % set x, y axes ticks if needed
        xlims = xlim;
        % xticks(xlims(1):1:xlims(2));
        % ylims = ylim;
        % yticks(ylims(1):1:ylims(2));
        
        % creates planes to visualise natural frequencies only with relevant sweep params 
        if ismember("freq",{sweep1_field,sweep2_field}) && ~ismember("J",{sweep1_field,sweep2_field})
            for i = 1:1:length(Q)
                if Q(i) >= xlims(1) && Q(i) <= xlims(2)
                    cp = constantplane("x",Q(i),"FaceColor","black","FaceAlpha",0.1);
                end
            end
        end
        
        % create failure threshold planes
        if isequal(z_axis_param, 'peak_ss_x') || isequal(z_axis_param, 'peak_transient_x') || isequal(z_axis_param, 'mean_ss_x')
            cp = constantplane("z",x_fail,"FaceColor",'r','FaceAlpha',0.3);
        elseif isequal(z_axis_param, 'peak_ss_xddot') || isequal(z_axis_param, 'peak_transient_xddot') || isequal(z_axis_param, 'mean_ss_xddot')
            cp = constantplane("z",xddot_fail,"FaceColor",'r','FaceAlpha',0.3);
        end
            
        % Build param annotations dynamically
        annotations = "Params: ";
        annotate_params = struct('L',p.L,'J',p.J,'phi_L',p.phi_L,'phi_J',p.phi_J,'forcingFunc',p.forcingFunc,'freq',p.freq,'k',p.k,'zeta',p.zeta);
        annotate_fields = fieldnames(annotate_params);
        for i = 1:length(annotate_fields)
            if ~isequal(sweep1_field, annotate_fields{i}) && ~isequal(sweep2_field, annotate_fields{i})
                if i ~= 1
                    annotations = annotations + ", ";
                end
                annotations = annotations + annotate_fields{i} + " = " + annotate_params.(annotate_fields{i});
            end
        end
        annotation('textbox', [0, 0, 0.8, 0.05], 'String', annotations, 'EdgeColor', 'none', 'HorizontalAlignment', 'left','Units','normalized');

    end


else % 1D sweep
    % pre-load arrays for 2D plotting
    sweep1_len = length(sweep1.(sweep1_field));
    Y = zeros(sweep1_len, 1);
    X = Y;

    % interpolated sweep axis values
    Xq = sweep1_min:sweep1_step/10:sweep1_max;
    
    % set y-axis metric to observe
    % choices: 'peak_ss_x', 'peak_ss_xddot', 'mean_ss_x', 'mean_ss_xddot',
    % 'peak_transient_x', 'peak_transient_xddot'
    y_axis_param = observation_metric;

    figure;
    hold on;
    for level = 1:p.L % plots all levels in one figure

        % set up X, Y plotting matrices using results_summary
        for i = 1:1:size(results_summary,2)

            S = results_summary(i).summary;
            P = results_summary(i).params;
            Q = results_summary(i).natfreq;
        
            X(i) = P.(sweep1_field);
            Y(i) = S.(y_axis_param)(:,level);
        end
        
        % calculate interpolated z-values
        % use linear interpolation if sweeping across discreet values (L/J)
        if isequal("L",sweep1_field) || isequal("J",sweep1_field)
            interpole = interp1(X,Y,Xq,"linear");
        else % use spline interpolation for continous value sweeps
            interpole = interp1(X,Y,Xq,"spline");
        end
        
        % divide axis by pi if sweeping over phi_L or phi_J
        if isequal("phi_L",sweep1_field) || isequal("phi_J",sweep1_field)
            Xq_plot = Xq / pi;
            sweep1_label = sweep1_field + "/π";
        else
            Xq_plot = Xq;
            sweep1_label = sweep1_field;
        end

        % create line plot
        plot(Xq_plot,interpole,'DisplayName',sprintf('Level %d',level))
        xlabel("X: " + sweep1_label);
        ylabel("Y: " + y_axis_param, 'Interpreter','none');

        % set xlim manually if needed
        % xlim([0,10]);
        xlims = xlim;
        % xticks(xlims(1):1:xlims(2));
        % yticks(1:1:6)
    end

    % create failure threshold line
    if isequal(y_axis_param, 'peak_ss_x') || isequal(y_axis_param, 'peak_transient_x') || isequal(y_axis_param, 'mean_ss_x')
        yline(x_fail,'-','x_f_a_i_l','Color','r','HandleVisibility','off');
    elseif isequal(y_axis_param, 'peak_ss_xddot') || isequal(y_axis_param, 'peak_transient_xddot') || isequal(y_axis_param, 'mean_ss_xddot')
        yline(xddot_fail,'-','xddot_f_a_i_l','Color','r','HandleVisibility','off');
    end
    % create lines to visualise natural frequencies only with relevant sweep param 
    if sweep1_field == "freq"
        for i = 1:1:length(Q)
            if Q(i) >= xlims(1) && Q(i) <= xlims(2)
                xline(Q(i),"-","f_n_" + i + ": " + Q(i),'LabelVerticalAlignment','top','HandleVisibility','off');
            end
        end
    end
    
    legend;
    
    % Build param annotations dynamically
    annotations = "Params: ";
    annotate_params = struct('L',p.L,'J',p.J,'phi_L',p.phi_L,'phi_J',p.phi_J,'forcingFunc',p.forcingFunc,'freq',p.freq,'k',p.k,'zeta',p.zeta);
    annotate_fields = fieldnames(annotate_params);
    for i = 1:length(annotate_fields)
        if ~isequal(sweep1_field, annotate_fields{i})
            if i ~= 1
                annotations = annotations + ", ";
            end
            annotations = annotations + annotate_fields{i} + " = " + annotate_params.(annotate_fields{i});
        end
    end
    annotation('textbox', [0, 0, 0.8, 0.05], 'String', annotations, 'EdgeColor', 'none', 'HorizontalAlignment', 'left','Units','normalized');

    hold off
end