

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

%% Log results to Workspace
modulePath = [modelName, '/Module1'];
probeSignals = { ...
    'batteryCurrent', 'batteryVoltage', 'n.v', ...
    'numCycles', 'p.v', 'socCell', 'socParallelAssembly', 'vParallelAssembly'};

addProbeAndOrganizeClean(modelName, modulePath, probeSignals);
tryAddLine(modelName, 'Probe_Module1/1', 'batteryCurrent_Out/1');
tryAddLine(modelName, 'Probe_Module1/2', 'batteryVoltage_Out/1');
tryAddLine(modelName, 'Probe_Module1/3', 'n_v_Out/1');  % '.' replaced with '_'
tryAddLine(modelName, 'Probe_Module1/4', 'numCycles_Out/1');
tryAddLine(modelName, 'Probe_Module1/5', 'p_v_Out/1');  % '.' replaced with '_'
tryAddLine(modelName, 'Probe_Module1/6', 'socCell_Out/1');
tryAddLine(modelName, 'Probe_Module1/7', 'socParallelAssembly_Out/1');
tryAddLine(modelName, 'Probe_Module1/8', 'vParallelAssembly_Out/1');



%% --- Simulation settings ---
set_param(modelName, ...
    'SimscapeLogType', 'all', ...
    'FastRestart', 'off', ...
    'StartTime', '0', ...
    'StopTime', '100000');

% %% --- Save model ---
save_system(modelName, sprintf("%s.slx", modelName));

disp(['✅ Model "', modelName, '" built and saved successfully.']);


%% Helper Functions

function addProbeAndOrganizeClean(modelName, modulePath, probeSignals)
    % Make a valid short probe block name
    [~, moduleBaseName] = fileparts(modulePath); % get 'Module1'
    probeBlkName = ['Probe_' matlab.lang.makeValidName(moduleBaseName)];
    probeName = [modelName, '/', probeBlkName];

    % Add probe if it doesn't exist
    if isempty(find_system(modelName, 'SearchDepth',1, 'Name', probeBlkName))
        add_block('nesl_utility/Probe', probeName, 'MakeNameUnique', 'on');
    end

    % Bind and set variables
    simscape.probe.setBoundBlock(probeName, modulePath);
    simscape.probe.setVariables(probeName, probeSignals);

    % Position the probe
    modulePos = get_param(modulePath, 'Position');
    set_param(probeName, 'Position', [modulePos(3)+150 modulePos(2) modulePos(3)+330 modulePos(2)+max(50,numel(probeSignals)*25)]);

    % Add To Workspace blocks (for module outports, if any)
    for i = 1:numel(probeSignals)
        varName = matlab.lang.makeValidName(probeSignals{i});
        toWorkspaceBlk = [modelName, '/', varName, '_Out'];
        if isempty(find_system(modelName, 'SearchDepth',1, 'Name', [varName, '_Out']))
            add_block('simulink/Sinks/To Workspace', toWorkspaceBlk, 'MakeNameUnique', 'on');
            set_param(toWorkspaceBlk, 'VariableName', varName, 'SaveFormat','StructureWithTime', 'SampleTime','-1', 'Decimation','1');
            set_param(toWorkspaceBlk, 'Position', [modulePos(3)+400 modulePos(2)+(i-1)*60 modulePos(3)+490 modulePos(2)+(i-1)*60+30]);
        end
    end

    % Clean layout
    Simulink.BlockDiagram.arrangeSystem(modelName);
    fprintf('✅ Probe and To Workspace blocks organized for "%s".\n', modulePath);
end

