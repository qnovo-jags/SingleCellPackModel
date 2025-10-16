%% Generate DOE Configuration

clc;

% === Output Directory ===
PACK_ID = 1;
metadata_dir = sprintf("./single_cell_pack_model/SYPACK%d/metadata",PACK_ID);

% === User Configuration ===
profileTypes = {'Step'};
sampling_rate_s = 1;              % [Hz]
initialRestSec = 300;                 % [s]

restBeforeChargeSec = [30*60];        % [s]
chargeCrates = [0.25, 1, 1.25, 1.5, 2.5];   % [C]
restAfterChargeSec = [30*60];         % [s]
dischargeCrates = 2;                % [C]
restAfterDischargeSec = 30*60;       % [s]
numberOfCycles = 2;                 % [-]
ambientTemps = 273.15 + [10, 20, 30, 40, 55];  % [K]

% === Generate DOE ===
myDOE = generateFullFactorialDOEWithRunSequence(metadata_dir, ...
    profileTypes, sampling_rate_s, initialRestSec, ...
    restBeforeChargeSec, chargeCrates, restAfterChargeSec, ...
    dischargeCrates, restAfterDischargeSec, numberOfCycles, ambientTemps);
