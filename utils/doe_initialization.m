function doe_initialization(modelName, myDOE, target_sequence, ...
                                CellNominalCapacityAh, numParallelCells, SYPACK)
% doe_initialization
% One-time model initialization using the first DOE in a given run_sequence
%
% Inputs:
%   modelName            - Name of Simulink model
%   myDOE                - Full DOE struct array
%   target_sequence      - Run sequence number
%   CellNominalCapacityAh- Cell nominal capacity
%   numParallelCells     - Number of parallel cells per module
%   SYPACK               - Pack configuration

    % Filter DOE for the run sequence
    filtered_DOE = myDOE([myDOE.run_sequence] == target_sequence);
    selectedDOE = filtered_DOE(1);

    % % --- Get ambient temperature from the first DOE in this sequence ---
    target_ambient_temp = selectedDOE.ambient_temperature_K;

    % % --- Compile pack model with this ambient temperature ---
    open_system(modelName);
    compilePackModel(SYPACK, target_ambient_temp);

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

    % --- Simulation settings ---
    set_param(modelName, 'FastRestart', 'off');

    % currentProfileBlock = [modelName, '/currentProfile'];  % use the exact block name in your model
    % set_param(currentProfileBlock, 'VariableName', 'currentData', ...
    %     'SampleTime', '-1', 'ShowName', 'off'); % variable-step
    set_param(modelName, 'Solver', 'ode15s', 'RelTol', '1e-5', ...
        'AbsTol', '1e-6', 'MaxStep', '1');

    % --- Run initialization simulation ---
    in = Simulink.SimulationInput(modelName);
    in = in.setVariable('AmbientTemperature', ambient_temperature_K);
    in = in.setModelParameter('StartTime', '0', 'StopTime', num2str(currentData(end,1)));

    % Run initialization simulation
    sim(in);
    fprintf("Model initialized using DOE: %s (Run Sequence %d)\n", selectedDOE.doe_id, target_sequence);

end
