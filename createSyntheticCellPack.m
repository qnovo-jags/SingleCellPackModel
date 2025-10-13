

% %% --- Detect if running standalone ---
caller = dbstack;
isStandalone = numel(caller) <= 1;

% %% --- Define model name (avoid shadowing conflicts) ---
modelName = 'singleCellElectricalModel';  % unique name

% %% --- Create or open model if standalone ---
if isStandalone
    clear(modelName);
    bdclose('all');
    new_system(modelName);
    open_system(modelName);
else
    if ~bdIsLoaded(modelName)
        load_system(modelName);
    end
end

% %% --- Load required libraries ---
load_system('BatteryGeneration/Batteries.slx');
load_system('fl_lib');
load_system('nesl_utility');
load_system('batt_lib');
load_system('simulink');

% %% --- Run parameter script ---
run("BatteryGeneration/ev_pack_cell_parameters.m");

% %% --- Helper functions ---
function tryAddLine(model, src, dst)
    % Adds line only if not already connected
    lines = get_param(model, 'Lines');
    srcBlk = strtok(src, '/');
    dstBlk = strtok(dst, '/');
    if ~any(arrayfun(@(L) strcmp(L.SrcBlock, srcBlk) && strcmp(L.DstBlock, dstBlk), lines))
        add_line(model, src, dst, 'autorouting', 'on');
    end
end

% %% --- Add blocks ---
% Battery Module
moduleBlock = 'Batteries/ModuleAssemblies/ModuleAssemblyType1/SyCellSk603Module';
moduleName  = [modelName, '/Module1'];
add_block(moduleBlock, moduleName, 'MakeNameUnique', 'on');

% Solver Configuration
solverBlock = [modelName, '/SolverConfig'];
add_block('nesl_utility/Solver Configuration', solverBlock, 'MakeNameUnique', 'on');

% Cycler
cyclerBlock = [modelName, '/Cycler'];
add_block('batt_lib/Cyclers/Cycler', cyclerBlock, 'MakeNameUnique', 'on');

% Current Profile (From Workspace)
currentProfile = [modelName, '/currentProfile'];
add_block('simulink/Sources/From Workspace', currentProfile, 'MakeNameUnique', 'on');
set_param(currentProfile, 'VariableName', 'currentData', ...
    'SampleTime', '10', ...
    'ShowName', 'off');

% Simulink-PS Converter
currentProfileToSimscape = [modelName, '/currentProfileToSimscape'];
add_block('nesl_utility/Simulink-PS Converter', currentProfileToSimscape, 'MakeNameUnique', 'on');
set_param(currentProfileToSimscape, 'ShowName', 'off');

% Constant block (PS Constant)
constant1 = [modelName, '/Constant1'];
add_block('fl_lib/Physical Signals/Sources/PS Constant', constant1, 'MakeNameUnique', 'on');

% Electrical Reference
electricalRef = [modelName, '/ElectricalRef'];
add_block('fl_lib/Electrical/Electrical Elements/Electrical Reference', electricalRef, 'MakeNameUnique', 'on');

% Probe
probePath = [modelName, '/PackProbe'];
add_block('nesl_utility/Probe', probePath, 'MakeNameUnique', 'on');
simscape.probe.setBoundBlock(probePath, cyclerBlock);
simscape.probe.setVariables(probePath, ["i", "v"]);

% %% --- Add connections ---
tryAddLine(modelName, 'currentProfile/1', 'currentProfileToSimscape/1');
tryAddLine(modelName, 'currentProfileToSimscape/RConn 1', 'Cycler/LConn 1');
tryAddLine(modelName, 'Constant1/RConn 1', 'Cycler/LConn 3');
tryAddLine(modelName, 'Cycler/RConn 1', 'Module1/LConn 1');
tryAddLine(modelName, 'Cycler/RConn 2', 'Module1/RConn 1');
tryAddLine(modelName, 'ElectricalRef/LConn 1', 'Module1/RConn 1');
tryAddLine(modelName, 'SolverConfig/RConn 1', 'Cycler/RConn 2');

% %% --- Simulation settings ---
set_param(modelName, ...
    'SimscapeLogType', 'all', ...
    'FastRestart', 'off', ...
    'StartTime', '0', ...
    'StopTime', '10000');

% %% --- Save model ---
save_system(modelName, sprintf("%s.slx", modelName));

disp(['✅ Model "', modelName, '" built and saved successfully.']);
