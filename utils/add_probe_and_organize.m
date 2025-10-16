function add_probe_and_organize(modelName, modulePath, probeSignals)
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
