% %% ------------------------------------------------------------------------
function simulation_results = doe_fast_restart_loop(modelName, myDOE, ...
                                target_sequence, CellNominalCapacityAh, ...
                                numParallelCells, output_dir, is_qnovo_format, signalNames)
% run_doe_fast_restart_loop
% Runs all DOEs in a filtered run_sequence using Fast Restart and extracts data
%
% Inputs:
%   modelName        - Name of Simulink model
%   myDOE            - Full DOE struct array
%   target_sequence  - Run sequence number
%   CellNominalCapacityAh
%   numParallelCells
%   numModules       - Number of modules
%   output_dir       - Folder to save CSVs
%
% Outputs:
%   simulation_results - Struct with DOE IDs as fields containing extracted data

    % Filter DOE for the run sequence
    filtered_DOE = myDOE([myDOE.run_sequence] == target_sequence);

    simulation_results = struct();

    % Enable Fast Restart
    set_param(modelName, 'FastRestart', 'on');

    for k = 1:length(filtered_DOE)
        selectedDOE = filtered_DOE(k);
        target_id = selectedDOE.doe_id;

        % Extract current input
        currentData = setupCurrentInput(CellNominalCapacityAh, ...
                                        numParallelCells, ...
                                        selectedDOE.sampling_rate_s, ...
                                        selectedDOE.initial_rest_s, ...
                                        selectedDOE.rest_before_charge_s, ...
                                        selectedDOE.charge_crate, ...
                                        selectedDOE.rest_after_charge_s, ...
                                        selectedDOE.discharge_crate, ...
                                        selectedDOE.rest_after_discharge_s, ...
                                        selectedDOE.number_of_cycles, ...
                                        selectedDOE.depth_of_charge, ...
                                        selectedDOE.depth_of_discharge);
        ambient_temperature_K = selectedDOE.ambient_temperature_K;

        % Assign currentData to base workspace
        assignin("base", "currentData", currentData);

        % Setup simulation input
        in = Simulink.SimulationInput(modelName);
        in = in.setVariable('AmbientTemperature', ambient_temperature_K);
        stop_time = currentData(end,1);
        in = in.setModelParameter('StartTime', '0', 'StopTime', num2str(stop_time));

        % Run simulation
        simout = sim(in);

        % Get Simscape log
        simulation_results.(target_id) = extractSEData(simout, signalNames, ...
            ambient_temperature_K, output_dir, target_id, ...
            is_qnovo_format, selectedDOE.sampling_rate_s);

        fprintf("DOE %s completed and saved.\n", target_id);
    end
end