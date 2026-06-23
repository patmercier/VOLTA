%% ------------------------------------------------------------------------
% runValidation.m
% Wrapper Script for VOLTA: VCO-ADC Model Optimization Toolbox
% ------------------------------------------------------------------------
% Author         : Sumukh Nitundil
% Affiliation    : EEMS Group, University of California, San Diego
% Email          : snitundil@ucsd.edu
% MATLAB Version : R2024a
% License        : GNU General Public License v3 (GPLv3)
% ------------------------------------------------------------------------
% Description:
% This script initializes all parameters using the validationSet config
% files, runs the VCO-ADC model, and prints the results to validate against 
% expectations from circuit simulators or silicon measurements.

% Note:
% - Users should ensure that the library root (folder VOLTA-Lib)
%   is on the MATLAB path prior to running this script. 
% - Refer README for details on library setup, organization and usage
% -----------------------------------------------------
% -------------------
tic

configSetChoice = 0;    % Baseline Model, design walkthrough
%configSetChoice = 1;   % Model A
%configSetChoice = 2;   % Model B
subSet = 0;

% Load validation configuration 
switch(configSetChoice)

    case 0 
        % Baseline Model
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSet(subSet);
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = false;
    case 1
        % Model A
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSetA(subSet);
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = true;
        modelParams.variantName = 'VOLTA.model.variants.evaluateAdcModelA';
    case 2
        % Model B
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSetB(subSet);
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = true;
        modelParams.variantName = 'VOLTA.model.variants.evaluateAdcModelB';
    otherwise
        error('Invalid validationSetChoice: %d. Must be 0, 1, or 2.', ...
          configSetChoice);
end
adcOut = VOLTA.model.evaluateAdcModel(varsValidation,modelParams,spec);
adcOut.printPerf;
adcOut.printPerfAux;
runTimeValidation = toc;