%% === DOE Generator Function ===
function DOE = generateFullFactorialDOEWithRunSequence(outputDir, profileTypes, sampling_rate_s, initialRests, ...
                                                       restBeforeCharge, chargeCrates, restAfterCharge, ...
                                                       dischargeCrates, restAfterDischarge, numberOfCycles, ambientTemps)
    % Generate full factorial DOE configurations with run_sequence

    DOE = [];
    run_sequence = 0;

    % Create output directory if missing
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Iterate through combinations
    for ptIdx = 1:numel(profileTypes)
        for atIdx = 1:numel(ambientTemps)
            run_sequence = run_sequence + 1;

            [SF, IR, RBC, CC, RAC, DC, RAD, NC] = ndgrid(1:numel(sampling_rate_s), ...
                1:numel(initialRests), 1:numel(restBeforeCharge), ...
                1:numel(chargeCrates), 1:numel(restAfterCharge), ...
                1:numel(dischargeCrates), 1:numel(restAfterDischarge), ...
                1:numel(numberOfCycles));

            totalComb = numel(SF);

            for i = 1:totalComb
                idx = numel(DOE) + 1;
                DOE(idx).doe_id = sprintf('doe%d', idx);
                DOE(idx).run_sequence = run_sequence;
                DOE(idx).profileType = profileTypes{ptIdx};
                DOE(idx).sampling_rate_s = sampling_rate_s(SF(i));
                DOE(idx).initial_rest_s = initialRests(IR(i));
                DOE(idx).rest_before_charge_s = restBeforeCharge(RBC(i));

                crate = chargeCrates(CC(i));

                % Assign depth of charge and discharge based on crate
                if crate <= 1
                    depthOfCharge = 0.8;
                elseif crate <= 1.75
                    depthOfCharge = 0.7;
                else
                    depthOfCharge = 0.55;
                end

                depthOfDischarge = depthOfCharge - 0.10;

                DOE(idx).charge_crate = crate;
                DOE(idx).depth_of_charge = depthOfCharge;
                DOE(idx).depth_of_discharge = depthOfDischarge;

                DOE(idx).rest_after_charge_s = restAfterCharge(RAC(i));
                DOE(idx).discharge_crate = dischargeCrates(DC(i));
                DOE(idx).rest_after_discharge_s = restAfterDischarge(RAD(i));
                DOE(idx).number_of_cycles = numberOfCycles(NC(i));
                DOE(idx).ambient_temperature_K = ambientTemps(atIdx);
            end
        end
    end

    % === Save Outputs ===
    DOE_table = struct2table(DOE);
    csvFile = fullfile(outputDir, 'doe_config.csv');
    matFile = fullfile(outputDir, 'doe_config.mat');

    writetable(DOE_table, csvFile);
    save(matFile, 'DOE');

    fprintf('✅ DOE configuration saved:\n   • CSV: %s\n   • MAT: %s\n', csvFile, matFile);
end
