function currentData = setupCurrentInput(CellNominalCapacityAh, numParallelCells, ...
                            samplingFreq, RestTime0, RestTime1, chargeRate, ...
                           RestTime2, dischargeRate, RestTime3, ...
                           numChargeCycles, depthOfCharge, depthOfdischarge)
% setupCurrentInput  Generate and assign current input profile for simulation.
%
%   setupCurrentInput(CellNominalCapacityAh, samplingFreq, RestTime0, RestTime1, ...
%                     chargeRate, RestTime2, dischargeRate, RestTime3, ...
%                     numChargeCycles)
%
%   This function generates a multi-cycle current input profile using the
%   multicycleSampler function and assigns the resulting current data to
%   the MATLAB base workspace as the variable 'currentData'.
%
%   INPUTS:
%       CellNominalCapacityAh : (numeric) Nominal cell capacity in ampere-hours.
%       samplingFreq          : (numeric) Sampling frequency in Hz.
%       RestTime0             : (numeric) Initial rest time before cycling [s].
%       RestTime1             : (numeric) Rest time after charge [s].
%       chargeRate            : (numeric) Constant current charge rate [C-rate].
%       RestTime2             : (numeric) Rest time after first discharge [s].
%       dischargeRate         : (numeric) Constant current discharge rate [C-rate].
%       RestTime3             : (numeric) Final rest time after discharge [s].
%       numChargeCycles       : (integer) Number of charge/discharge cycles.
%
%   OUTPUTS:
%       None. The function assigns the generated current profile as
%       'currentData' in the MATLAB base workspace.
%
%   EXAMPLE:
%       setupCurrentInput(60, 10, 300, 600, 0.5, 600, 1.0, 900, 3)
%
%   See also: multicycleSampler
%
%   Author: Jagmohan Fanshal
%   Date:   2025-10-08

    % Generate the current profile using user-defined parameters

    currentData = multicycleSampler(CellNominalCapacityAh, ...
                                    numParallelCells, ...
                                    samplingFreq, ...
                                    RestTime0, ...
                                    RestTime1, ...
                                    chargeRate, ...
                                    RestTime2, ...
                                    dischargeRate, ...
                                    RestTime3, ...
                                    numChargeCycles, ...
                                    depthOfCharge, ...
                                    depthOfdischarge);

    % Assign to base workspace for Simulink access
    assignin('base', 'currentData', currentData);
end
