clc
clear 
close all

%% ================================
%  SIMULATION SETUP
%  ================================
PACK_ID = 1;

CellNominalCapacityAh = 60;    % Nominal capacity per cell [Ah]
numParallelCells      = 1;     % Number of parallel cells
numModules            = 1;     % Number of modules in this configuration

modelName = 'singleCellElectricalModel';  % Simulink model name


%% ================================
%  DIRECTORY STRUCTURE
%  ================================
base_dir      = "./single_cell_pack_model";
project_dir   = fullfile(base_dir, sprintf("SYPACK%d", PACK_ID));
sim_dir       = fullfile(project_dir, "simulations");
mat_dir       = fullfile(sim_dir, "mat_format");
metadata_dir  = fullfile(project_dir, "metadata");


%% ================================
%  LOAD PACK CONFIGURATION
%  ================================
config_file = fullfile(metadata_dir, "pack_config.mat");
fprintf("Loading pack configuration from: %s\n", config_file);
load(config_file, "SYPACK");

fprintf("Loaded configuration for SYPACK%d successfully.\n", PACK_ID);


%% ================================
%  LOAD DOE CONFIGURATION
%  ================================
doe_onfig_file = fullfile(metadata_dir, "doe_config.mat");
fprintf("Loading DOE configuration from: %s\n", doe_onfig_file);
load(doe_onfig_file, "DOE");

fprintf("Loaded DOE configuration for SYPACK%d successfully.\n", PACK_ID);


%% Run DOE and log results

% --- MASTER DOE RUN ---
is_qnovo_format = 0;  % 1: "[I1,I2,...]" format, 0 for expanded format
signalNames = {'batteryCurrent','batteryVoltage','socCell'};
all_run_sequences = unique([DOE.run_sequence]);

for seqIdx = 1:length(all_run_sequences)

    % --- Identify the targer run sequence
    target_sequence = all_run_sequences(seqIdx);
    fprintf("\n=== Running sequence %d/%d ===\n", target_sequence, length(all_run_sequences));

    % --- Initialize model for this run sequence
    doe_initialization(modelName, DOE, target_sequence, CellNominalCapacityAh, numParallelCells, SYPACK(PACK_ID));

    % --- Run fast restart loop to simulate all DOEs in this sequence
    simulation_results = doe_fast_restart_loop(modelName, DOE, target_sequence, ...
                                        CellNominalCapacityAh, numParallelCells, ...
                                        sim_dir, is_qnovo_format, signalNames);

    % --- Save and log SE data
    filtered_DOE = DOE([DOE.run_sequence] == target_sequence);
    % save_all_doe_simlogs(filtered_DOE, simulation_results, numModules, sim_dir, is_qnovo_format);

    fprintf("Completed run_sequence %d\n", target_sequence);
end

fprintf("\nAll run_sequences completed successfully!\n");