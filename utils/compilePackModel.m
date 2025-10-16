function [] = compilePackModel(SYPACK, target_ambient_temp)
%COMPILEPACKMODEL Generate module structs and DOE deviations for Simulink
%
% Inputs:
%   SYPACK : Struct containing all pack parameters, including damaged cell info and percent deviations
%
% Outputs:
%   Modules      : 1 x numModules struct array with all module parameters

numCells    = 1;
numParallel = 1;
numCycles   = 1;

fields = {"AmbientTemperature"};

for i = 1:numel(fields)
    assignin("base", fields{i}, SYPACK.(fields{i}));
end

% Get fixed cell parameters
cell_param = ev_pack_cell_parameters();

% Get initial target SOCs
soc0       = repmat(SYPACK.SocCell0, numCells, 1); % nominal SOC


% Assign fixed cell parameters
Module1.BatteryCapacityCell = cell_param.BatteryCapacityCell;
Module1.SOCBreakpointsCell = cell_param.SOCBreakpointsCell;
Module1.TemperatureBreakpointsCell = cell_param.TemperatureBreakpointsCell;
Module1.OpenCircuitVoltageThermalCell = cell_param.OpenCircuitVoltageThermalCell;
Module1.VoltageRangeCell = cell_param.VoltageRangeCell;
Module1.ResistanceSOCBreakpointsCell = cell_param.ResistanceSOCBreakpointsCell;
Module1.ResistanceTemperatureBreakpointsCell = cell_param.ResistanceTemperatureBreakpointsCell;
Module1.R0ThermalCell = cell_param.R0ThermalCell;
Module1.R1ThermalCell = cell_param.R1ThermalCell;
Module1.Tau1ThermalCell = cell_param.Tau1ThermalCell;
Module1.BatteryThermalMassCell = 0.01;
Module1.AmbientResistance = 0;


% Runtime parameters (column vectors)
Module1.socCell             = soc0;         % 12x1
Module1.numCycles           = repmat(numCycles,numCells,1); % 12x1
Module1.batteryTemperature  = repmat(target_ambient_temp,numCells,1); % 12x1
Module1.batteryVoltage      = zeros(numCells,1);           % 12x1
Module1.batteryCurrent      = zeros(numCells,1);           % 12x1
Module1.vParallelAssembly   = zeros(numParallel,1);        % 6x1
Module1.socParallelAssembly = SYPACK.SocCell0 * ones(numParallel,1);         % 6x1

assignin('base', 'Module1', Module1);

end

