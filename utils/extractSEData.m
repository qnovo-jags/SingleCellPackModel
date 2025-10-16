function se_data = extractSEData(simout, signalNames, ambient_temperature_K, output_dir, target_id, is_qnovo_format, sampling_rate_s)
% Extracts time, current, voltage, temperature, and SOC from simout
% Supports qnovo-style CSV formatting.
%
% Inputs:
%   simout            - Simulink.SimulationOutput
%   signalNames       - cell array of signals to extract (e.g., {'batteryCurrent','batteryVoltage','socCell'})
%   ambient_temperature_K - scalar, constant temperature
%   output_dir        - folder to save CSV/MAT
%   target_id         - name for saved files
%   is_qnovo_format   - 1: string array CSV, 0: expanded numeric CSV
%
% Outputs:
%   se_data           - struct with 'original' and 'resampled' tables

    % Mandatory signals (first: current, second: voltage, third: SOC)
    mandatorySignals = {'batteryCurrent', 'batteryVoltage', 'socCell'};
    if ~exist('signalNames','var') || isempty(signalNames)
        signalNames = mandatorySignals;
    else
        % Keep only signals that exist in simout
        simVars = who(simout);  % all logged variables
        signalNames = intersect(signalNames, simVars, 'stable');
    end

    % Extract signals into struct
    se_struct = struct();
    for i = 1:numel(signalNames)
        name = signalNames{i};
        s = simout.(name);
        se_struct.(name).time   = s.time(:);
        se_struct.(name).values = s.signals.values(:);
    end

    % Reference time vector (first signal)
    all_times = se_struct.(signalNames{1}).time;
    n_orig = length(all_times);
    time_resampled = (all_times(1):sampling_rate_s:all_times(end))';
    n_res = length(time_resampled);

    % Interpolate signals to common time vector
    n_signals = numel(signalNames);
    values_orig = zeros(n_orig, n_signals);
    values_res  = zeros(n_res, n_signals);
    for i = 1:n_signals
        t = se_struct.(signalNames{i}).time;
        v = se_struct.(signalNames{i}).values;
        values_orig(:,i) = interp1(t, v, all_times, 'linear', 'extrap');
        values_res(:,i)  = interp1(t, v, time_resampled, 'linear', 'extrap');
    end

    % Add temperature as constant column
    temp_orig = ambient_temperature_K * ones(n_orig,1);
    temp_res  = ambient_temperature_K * ones(n_res,1);

    % Build tables with qnovo formatting if requested
    if is_qnovo_format
        to_str_array = @(X) arrayfun(@(i) "[" + join(string(X(i,:)), ", ") + "]", (1:size(X,1))', 'UniformOutput', false);

        se_data.original = table(all_times, ...
                                 to_str_array(values_orig(:,1)), ...
                                 to_str_array(values_orig(:,2)), ...
                                 to_str_array(temp_orig), ...
                                 to_str_array(values_orig(:,3)), ...
                                 'VariableNames', {'time_s','se_currents_A','se_voltages_V','se_temperatures_K','se_socs'});

        se_data.resampled = table(time_resampled, ...
                                  to_str_array(values_res(:,1)), ...
                                  to_str_array(values_res(:,2)), ...
                                  to_str_array(temp_res), ...
                                  to_str_array(values_res(:,3)), ...
                                  'VariableNames', {'time_s','se_currents_A','se_voltages_V','se_temperatures_K','se_socs'});
    else
        se_data.original = array2table([all_times, values_orig(:,1), values_orig(:,2), temp_orig, values_orig(:,3)], ...
                                       'VariableNames', {'time_s','se_currents_A','se_voltages_V','se_temperatures_K','se_socs'});
        se_data.resampled = array2table([time_resampled, values_res(:,1), values_res(:,2), temp_res, values_res(:,3)], ...
                                        'VariableNames', {'time_s','se_currents_A','se_voltages_V','se_temperatures_K','se_socs'});
    end

    % Add all simout
    se_data.simout = simout;

    % ---- Save CSVs ----
    if nargin >= 4 && ~isempty(output_dir)
        % Original CSV folder
        orig_dir = fullfile(output_dir, 'original');
        if ~exist(orig_dir,'dir'), mkdir(orig_dir); end
        orig_filename = fullfile(orig_dir, sprintf("%s.csv", target_id));
        writetable(se_data.original, orig_filename);
        fprintf("Original data saved: %s\n", orig_filename);
    
        % Resampled CSV folder
        res_dir = fullfile(output_dir, 'resample');
        if ~exist(res_dir,'dir'), mkdir(res_dir); end
        res_filename = fullfile(res_dir, sprintf("%s.csv", target_id));
        writetable(se_data.resampled, res_filename);
        fprintf("Resampled data saved: %s\n", res_filename);
    end
    
    % ---- Save MAT ----
    mat_dir = fullfile(output_dir, 'mat_format');
    if ~exist(mat_dir,'dir'), mkdir(mat_dir); end
    mat_filename = fullfile(mat_dir, sprintf("%s.mat", target_id));
    save(mat_filename, 'se_data', '-v7.3');
    fprintf("MAT file saved: %s\n", mat_filename);
end


% function se_data = extractSEData(simlog, ambient_temperature_K, output_dir, target_id, is_qnovo_format)
% 
% % extractSEData(simlog, ambient_temperature_K, output_dir, target_id, is_qnovo_format)
% 
% % extractSEData
% % Extracts SE-level time series data from a Simscape simlog and also
% % generates a 1-second resampled version.
% %
% % Inputs:
% %   simlog      - Simscape simulation log (struct)
% %   numModules  - Number of modules (e.g., 32)
% %   output_dir   - Folder where output CSVs will be saved
% %   target_id    - DOE target name (used in filenames)
% %
% % Outputs:
% %   se_data     - Struct with two fields:
% %                   se_data.original   -> original time vectors
% %                   se_data.resampled  -> 1 s resampled data
% %
% % Each field contains a table with:
% %   time_s, se_currents_A(1x192), se_voltages_V(1x192),
% %   se_temperatures_K(1x192), se_socs(1x192)
% 
%     % Preallocate containers
%     all_times = [];
%     numSEs = 1;
% 
%     se_currents = cell(1, numSEs);
%     se_voltages = cell(1, numSEs);
%     se_temperatures = cell(1, numSEs);
%     se_socs_frac = cell(1, numSEs);
% 
%     % ---- Add the simlogs ----
%     se_data.simlog = simlog;
% 
%     % ---- Extract Data ----
%     se_counter = 0;
%     numModules = 1;
%     for i = 1:numModules
%         % Temperature from each module
%         blockName = sprintf('Module%d', i);
% 
%         t_series = simlog.(blockName).batteryCurrent.series.time;
%         all_times = t_series;
% 
%         T_series = ambient_temperature_K * ones(size(t_series));
% 
%         % Each module has 6 SEs
%         Module = sprintf('Module%d', i);
%         for p = 1:numSEs
%             se_counter = se_counter + 1;
% 
%             % Voltage
%             v = simlog.(Module).SyCellSk603ParallelAssembly(p).vParallelAssembly.series.values;
%             t_v = simlog.(Module).SyCellSk603ParallelAssembly(p).vParallelAssembly.series.time;
% 
%             % Current (sum of two cells)
%             currents = simlog.(Module).SyCellSk603ParallelAssembly(p).batteryCurrent.series.values;
%             t_c = simlog.(Module).SyCellSk603ParallelAssembly(p).batteryCurrent.series.time;
%             i_se = currents;
% 
%             % SOC
%             soc = simlog.(Module).SyCellSk603ParallelAssembly(p).socParallelAssembly.series.values;
%             t_soc = simlog.(Module).SyCellSk603ParallelAssembly(p).socParallelAssembly.series.time;
% 
%             % Assign to arrays
%             se_voltages{se_counter} = [t_v(:), v(:)];
%             se_currents{se_counter} = [t_c(:), i_se(:)];
%             se_socs_frac{se_counter} = [t_soc(:), soc(:)];
%             se_temperatures{se_counter} = [t_series(:), T_series(:)];
%         end
%     end
% 
%     % ---- Align and Resample ----
%     t_min = max(cellfun(@(x) x(1,1), se_currents));
%     t_max = min(cellfun(@(x) x(end,1), se_currents));
%     time_resampled = (t_min:1:t_max)';
% 
%     % Allocate arrays
% 
%     n_orig = length(all_times);
%     n_res  = length(time_resampled);
% 
%     se_currents_A_orig = zeros(n_orig, numSEs);
%     se_voltages_V_orig = zeros(n_orig, numSEs);
%     se_temperatures_K_orig = zeros(n_orig, numSEs);
%     se_socs_orig = zeros(n_orig, numSEs);
% 
%     se_currents_A_res = zeros(n_res, numSEs);
%     se_voltages_V_res = zeros(n_res, numSEs);
%     se_temperatures_K_res = zeros(n_res, numSEs);
%     se_socs_res = zeros(n_res, numSEs);
% 
%     % ---- Interpolate both versions ----
%     for k = 1:numSEs
%         % Resample to all_times (original reference grid)
%         se_currents_A_orig(:,k)     = interp1(se_currents{k}(:,1), se_currents{k}(:,2), all_times, 'linear', 'extrap');
%         se_voltages_V_orig(:,k)     = interp1(se_voltages{k}(:,1), se_voltages{k}(:,2), all_times, 'linear', 'extrap');
%         se_temperatures_K_orig(:,k) = interp1(se_temperatures{k}(:,1), se_temperatures{k}(:,2), all_times, 'linear', 'extrap');
%         se_socs_orig(:,k)           = interp1(se_socs_frac{k}(:,1), se_socs_frac{k}(:,2), all_times, 'linear', 'extrap');
% 
%         % Resample to 1s grid
%         se_currents_A_res(:,k)     = interp1(se_currents{k}(:,1), se_currents{k}(:,2), time_resampled, 'linear', 'extrap');
%         se_voltages_V_res(:,k)     = interp1(se_voltages{k}(:,1), se_voltages{k}(:,2), time_resampled, 'linear', 'extrap');
%         se_temperatures_K_res(:,k) = interp1(se_temperatures{k}(:,1), se_temperatures{k}(:,2), time_resampled, 'linear', 'extrap');
%         se_socs_res(:,k)           = interp1(se_socs_frac{k}(:,1), se_socs_frac{k}(:,2), time_resampled, 'linear', 'extrap');
%     end
% 
%     if is_qnovo_format == 1
%         % 1. ---- Convert rows to string arrays for CSV ----
%         % to_str_array = @(x) cellstr("[" + join(string(x), ", ") + "]");
%         to_str_array = @(X) arrayfun(@(i) "[" + join(string(X(i,:)), ", ") + "]", (1:size(X,1))', 'UniformOutput', false);
% 
% 
%         se_data.original = table(all_times, ...
%             to_str_array(se_currents_A_orig), ...
%             to_str_array(se_voltages_V_orig), ...
%             to_str_array(se_temperatures_K_orig), ...
%             to_str_array(se_socs_orig), ...
%             'VariableNames', {'time_s', 'se_currents_A', 'se_voltages_V', 'se_temperatures_K', 'se_socs'});
% 
%         se_data.resampled = table(time_resampled(:), ...
%             to_str_array(se_currents_A_res), ...
%             to_str_array(se_voltages_V_res), ...
%             to_str_array(se_temperatures_K_res), ...
%             to_str_array(se_socs_res), ...
%             'VariableNames', {'time_s', 'se_currents_A', 'se_voltages_V', 'se_temperatures_K', 'se_socs'});
% 
%         % ---- Save CSVs ----
%         if nargin >= 3 && ~isempty(output_dir)
%             if ~exist(output_dir, 'dir'), mkdir(output_dir); end
%             orig_dir = fullfile(output_dir, 'original');
%             if ~exist(orig_dir, 'dir'), mkdir(orig_dir); end
%             resample_dir = fullfile(output_dir, 'resample');
%             if ~exist(resample_dir, 'dir'), mkdir(resample_dir); end
% 
%             % Original
%             orig_filename = fullfile(orig_dir, sprintf("%s_original.csv", target_id));
%             if exist(orig_filename, 'file'), delete(orig_filename); end
%             writetable(se_data.original, orig_filename);
%             fprintf("Original data saved: %s\n", orig_filename);
% 
%             % Resampled
%             resampled_filename = fullfile(resample_dir, sprintf("%s.csv", target_id));
%             if exist(resampled_filename, 'file'), delete(resampled_filename); end
%             writetable(se_data.resampled, resampled_filename);
%             fprintf("Resampled data saved: %s\n", resampled_filename);
%         end 
% 
%     % 2. Expanded format---- Tables ----
%     else
%         col_I = strcat("se_currents_A_", string(1:numSEs));
%         col_V = strcat("se_voltages_V_", string(1:numSEs));
%         col_T = strcat("se_temperatures_K_", string(1:numSEs));
%         col_SOC = strcat("se_socs_", string(1:numSEs));
% 
%         se_data.original = array2table([all_times(:), se_currents_A_orig, se_voltages_V_orig, ...
%                                     se_temperatures_K_orig, se_socs_orig], ...
%         'VariableNames', [{'time_s'}, col_I, col_V, col_T, col_SOC]);
% 
%         se_data.resampled = array2table([time_resampled(:), se_currents_A_res, se_voltages_V_res, ...
%                                          se_temperatures_K_res, se_socs_res], ...
%             'VariableNames', [{'time_s'}, col_I, col_V, col_T, col_SOC]);
% 
% 
%         % ---- Save CSVs ----
%         if nargin >= 3 && ~isempty(output_dir)
%             if ~exist(output_dir, 'dir')
%                 mkdir(output_dir);
%             end
%             orig_dir = fullfile(output_dir, 'original');
%             if ~exist(orig_dir, 'dir')
%                 mkdir(orig_dir);
%             end
% 
%             % Save Original
%             orig_filename = fullfile(orig_dir, sprintf("%s_original_expanded.csv", target_id));
%             if exist(orig_filename, 'file'), delete(orig_filename); end
%             writetable(se_data.original, orig_filename);
%             fprintf("Original data saved: %s\n", orig_filename);
% 
%             % Save Resampled
%             resampled_filename = fullfile(output_dir, sprintf("%s_expanded.csv", target_id));
%             if exist(resampled_filename, 'file'), delete(resampled_filename); end
%             writetable(se_data.resampled, resampled_filename);
%             fprintf("Resampled data saved: %s\n", resampled_filename);
%         end
%     end
% 
%     % Save individual MAT file per DOE
%     mat_dir      = fullfile(output_dir, "mat_format");
%     mat_filename = fullfile(mat_dir, sprintf("%s.mat", target_id));
% 
%     % Delete existing file if it exists
%     if exist(mat_filename, 'file')
%         delete(mat_filename);
%     end
%     save(mat_filename, 'se_data', '-v7.3');
%     fprintf("Saved MAT for DOE %s: %s\n", target_id, mat_filename);
% 
% end
