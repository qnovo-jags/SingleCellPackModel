
%% --- Setup paths ---

PACK_ID = 1;
common_path = sprintf('single_cell_pack_model/SYPACK%d/metadata', PACK_ID);
if ~exist(common_path, 'dir')
    mkdir(common_path);
end

% %% --- 1. Save cell_parameters.json ---

cell_param = ev_pack_cell_parameters();  % fixed cell parameters

cellParamFile = fullfile(common_path, 'cell_parameters.json');
fid = fopen(cellParamFile, 'w');
fprintf(fid, '%s', jsonencode(cell_param));
fclose(fid);
fprintf('Saved cell parameters JSON: %s\n', cellParamFile);

% %% Pack Parameters - Architechture and Thermal

SYPACK(PACK_ID).num_series_elements = 1;
SYPACK(PACK_ID).num_parallel_elements = 1;
SYPACK(PACK_ID).se_resistance_adjustments_ohm = zeros(1,1);

SYPACK(PACK_ID).numCellsPerModule = 1;
SYPACK(PACK_ID).numModules = 1;

SYPACK(PACK_ID).temperature_ref_K = 273.15 + 25;
SYPACK(PACK_ID).r_bol_soc_ranges_frac = [0.20, 0.75];

% %% --- 2. Save pack_parameters.json ---
pack_params = SYPACK(PACK_ID);
packParamFile = fullfile(common_path, 'pack_parameters.json');
fid = fopen(packParamFile, 'w');
fprintf(fid, '%s', jsonencode(pack_params));
fclose(fid);
fprintf('Saved pack parameters JSON: %s\n', packParamFile);

% % Initial conditions: SoCs

SYPACK(PACK_ID).SocCell0                                 = 0.15;
SYPACK(PACK_ID).AmbientTemperature = SYPACK(PACK_ID).temperature_ref_K; % Kelvin

% %% ================================
%  SAVE PACK CONFIGURATION
%  ================================
metadata_dir = fullfile('single_cell_pack_model', sprintf('SYPACK%d', PACK_ID), 'metadata');

% Create folder if not already present
if ~exist(metadata_dir, 'dir')
    fprintf('Creating directory: %s\n', metadata_dir);
    mkdir(metadata_dir);
end

% Save configuration
save(fullfile(metadata_dir, 'pack_config.mat'), 'SYPACK');
fprintf('Pack configuration saved successfully for SYPACK%d.\n', PACK_ID);
