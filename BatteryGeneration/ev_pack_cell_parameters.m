function cell_param = ev_pack_cell_parameters()
% Function to create the parameters of the pouch cell in the EV pack.
%
% Output:
%   cell_param (struct) - Cell parameters structure.

% ----------------------- BEGIN MODIFIABLE SECTION ------------------------
% Battery capacity, A*hr
cell_param.BatteryCapacityCell = 60.0;

% State of charge breakpoints, SOC
cell_param.SOCBreakpointsCell = [
    0;
    0.05;
    0.1;
    0.15;
    0.2;
    0.25;
    0.3;
    0.35;
    0.4;
    0.45;
    0.5;
    0.55;
    0.6;
    0.65;
    0.7;
    0.75;
    0.8;
    0.85;
    0.9;
    0.95;
    1];

% Temperature breakpoints, T, K
cell_param.TemperatureBreakpointsCell = [
    283.15;
    298.15;
    328.15];

% Open-circuit voltage, OCV(SOC,T), V
cell_param.OpenCircuitVoltageThermalCell = [
    2.500,  2.500,  2.500;
    3.420,	3.386,	3.338;
    3.464,	3.428,	3.409;
    3.520,	3.481,	3.460;
    3.568,	3.535,	3.519;
    3.597,	3.577,	3.564;
    3.623,	3.606,	3.612;
    3.651,	3.642,	3.639;
    3.681,	3.671,	3.669;
    3.721,	3.707,	3.703;
    3.777,	3.753,	3.746;
    3.835,	3.817,	3.824;
    3.879,	3.864,	3.868;
    3.915,	3.903,	3.905;
    3.946,	3.944,	3.936;
    3.990,	3.988,	3.977;
    4.044,	4.041,	4.046;
    4.080,	4.077,	4.078;
    4.097,	4.092,	4.091;
    4.126,	4.116,	4.114;
    4.177,	4.132,	4.114];

% Open-circuit voltage, OCV(SOC,T) = OCV(SOC,T=298.15K), V
cell_param.OpenCircuitVoltageThermalCell = repmat(cell_param.OpenCircuitVoltageThermalCell(:,2), 1, 3);


% Terminal voltage operating range, [Min Max], V
cell_param.VoltageRangeCell = [0, Inf];

% State of charge breakpoints for resistance, SOC
cell_param.ResistanceSOCBreakpointsCell = [
    0;
    0.05;
    0.1;
    0.15;
    0.2;
    0.25;
    0.3;
    0.35;
    0.4;
    0.45;
    0.5;
    0.55;
    0.6;
    0.65;
    0.7;
    0.75;
    0.8;
    0.85;
    0.9;
    0.95;
    1];

% Temperature breakpoints for resistance, T, K
cell_param.ResistanceTemperatureBreakpointsCell = [283.15;298.15;328.15];

% Instantaneous resistance, R0(SOC,T), Ohm
cell_param.R0ThermalCell = [
    0.00123,	0.00091,	0.00066;
    0.00121,	0.00086,	0.00060;
    0.00119,	0.00084,	0.00058;
    0.00118,	0.00082,	0.00058;
    0.00117,	0.00080,	0.00057;
    0.00114,	0.00080,	0.00057;
    0.00111,	0.00076,	0.00054;
    0.00109,	0.00076,	0.00054;
    0.00109,	0.00076,	0.00055;
    0.00107,	0.00075,	0.00055;
    0.00105,	0.00073,	0.00054;
    0.00104,	0.00074,	0.00054;
    0.00103,	0.00072,	0.00053;
    0.00103,	0.00072,	0.00054;
    0.00104,	0.00072,	0.00053;
    0.00102,	0.00073,	0.00053;
    0.00103,	0.00073,	0.00054;
    0.00106,	0.00073,	0.00053;
    0.00107,	0.00076,	0.00054;
    0.00112,	0.00077,	0.00055;
    0.00118,	0.00077,	0.00055];

% First polarization resistance, R1(SOC,T), Ohm
cell_param.R1ThermalCell = [
    0.00282,	0.00235,	0.00107;
    0.00207,	0.00189,	0.00119;
    0.00201,	0.00153,	0.00081;
    0.00170,	0.00126,	0.00070;
    0.00154,	0.00117,	0.00069;
    0.00145,	0.00103,	0.00069;
    0.00150,	0.00099,	0.00060;
    0.00162,	0.00111,	0.00065;
    0.00179,	0.00123,	0.00071;
    0.00199,	0.00138,	0.00078;
    0.00191,	0.00153,	0.00087;
    0.00133,	0.00099,	0.00056;
    0.00132,	0.00088,	0.00051;
    0.00139,	0.00094,	0.00055;
    0.00151,	0.00107,	0.00062;
    0.00161,	0.00112,	0.00066;
    0.00166,	0.00117,	0.00069;
    0.00163,	0.00119,	0.00072;
    0.00187,	0.00126,	0.00076;
    0.00246,	0.00151,	0.00082;
    0.00398,	0.00166,	0.00082];

% First time constant, Tau1(SOC,T), s
cell_param.Tau1ThermalCell = [
    50.95,	42.56,	38.69;
    57.57,	64.21,	45.21;
    61.03,	54.25,	34.53;
    55.95,	48.47,	30.64;
    50.92,	48.53,	33.22;
    47.21,	43.96,	36.26;
    46.85,	40.39,	32.31;
    48.24,	40.96,	31.95;
    51.23,	42.55,	31.84;
    58.02,	44.80,	32.66;
    67.05,	50.89,	33.71;
    45.16,	43.39,	29.98;
    45.58,	35.89,	28.25;
    48.85,	40.34,	33.14;
    51.26,	45.08,	37.71;
    52.09,	45.16,	38.84;
    55.16,	48.64,	42.75;
    61.86,	57.62,	53.28;
    61.72,	58.26,	54.49;
    64.16,	55.73,	46.35;
    93.74,	55.21,	46.35];

% Battery thermal mass, J/K
cell_param.BatteryThermalMassCell = 100;

% Cell level ambient thermal path resistance, K/W
cell_param.AmbientResistance = 25;

% Inter-cell thermal path resistance, K/W
cell_param.InterCellThermalResistance = 1;

% Inter-parallel assembly thermal path resistance, K/W
cell_param.InterParallelAssemblyThermalResistance = 1;

% Inter-cell radiation heat transfer area, m^2
cell_param.InterCellRadiationArea = 1e-3;

% Inter-cell radiation heat transfer coefficient, W/(m^2*K^4)
cell_param.InterCellRadiationCoefficient = 1e-6;

% Inter-parallel assembly area for radiation heat transfer, m^2
cell_param.InterParallelAssemblyRadiationArea = 1e-3;

% Inter-parallel assembly coefficient for radiation heat transfer, W/(m^2*K^4)
cell_param.InterParallelAssemblyRadiationCoefficient = 1e-6;
% ------------------------ END MODIFIABLE SECTION -------------------------

