% ------------------------------------------------------------------------
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
% This script initializes all parameters using the validationSet and gaSet 
% config files, runs the genetic algorithm optimization and returns the
% results.

% Note:
% - Users should ensure that the library root (folder VOLTA-Lib)
%   is on the MATLAB path prior to running this script. 
% - Refer README for details on library setup, organization and usage
% ------------------------------------------------------------------------
tic
close all
configSetChoice = 0;    % Baseline Model, design walkthrough
%configSetChoice = 1;   % Model A
%configSetChoice = 2;   % Model B
subSet = 1;

% Load validation configuration 
switch(configSetChoice)
    case 0 
        % Baseline Model
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSet(subSet);
        [gaParams,plotParams] = VOLTA.scripts.configs.optimizationSet(varParams);
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = false;
    case 1
        % Model A
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSetA(subSet);
        [gaParams,plotParams] = VOLTA.scripts.configs.optimizationSetA(varParams);
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = true;
        modelParams.variantName = 'VOLTA.model.variants.evaluateAdcModelA';        
    case 2
        % Model B
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSetB(subSet);
        [gaParams,plotParams] = VOLTA.scripts.configs.optimizationSetB(varParams);
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = true;
        modelParams.variantName = 'VOLTA.model.variants.evaluateAdcModelB';        
    otherwise
        error('Invalid validationSetChoice: %d. Must be 0, 1, or 2.', ...
          configSetChoice);
end
[xOptScaled, fVal, exitFlag, gaOut] = VOLTA.optimization.runGa(gaParams, plotParams, varParams, modelParams, spec);

xOpt = VOLTA.utilities.unscaleVariables(xOptScaled,varParams);
fprintf('\nOptimized Design Variables : \n')
for k = 1:length(varParams)
    fprintf('%s: %g\n', varParams(k).name, xOpt(k));
end
fprintf('\nOptimized ADC : \n')
adcOpt = VOLTA.model.evaluateAdcModel(xOpt,modelParams,spec);
adcOpt.printPerf;
adcOpt.printPerfAux;
runTimeOptimization = toc;