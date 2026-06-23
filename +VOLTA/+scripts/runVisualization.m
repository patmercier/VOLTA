%% ------------------------------------------------------------------------
% runValidation.m
% Wrapper Script for VOLTA: VCO-ADC Model Optimization Toolbox
% ------------------------------------------------------------------------
% Author         : Sumukh Nitundil
% Affiliation    : EEMS Group, University of California, San Diego
% Email          : snitundil@ucsd.edu
% MATLAB Version : R2024a
% License        : 
% ------------------------------------------------------------------------
% Description:
% This script initializes all parameters using the validationSet config
% files, runs the VCO-ADC model, and plots the results. The varParams can
% be configured to change the swept variables and ranges to visualize the
% model's design space, and provide insight into tradeoffs. 

% Note:
% - Users should ensure that the library root (folder VOLTA-Lib)
%   is on the MATLAB path prior to running this script. 
% - Refer README for details on library setup, organization and usage
% ------------------------------------------------------------------------
tic

configSetChoice = 0;    % Baseline Model
%configSetChoice = 1;   % Model A
%configSetChoice = 2;   % Model B

% Add new model variant versions choices here

% Load validation configuration 
switch(configSetChoice)
    case 0 
        % Baseline Model
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSet();
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = false;
    case 1
        % Model A
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSetA();
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = true;
        modelParams.variantName = 'VOLTA.model.variants.evaluateAdcModelA';
    case 2
        % Model B
        [varParams, modelParams, spec] = VOLTA.scripts.configs.validationSetB();
        varsValidation = VOLTA.utilities.setupVariables(varParams);
        modelParams.variant = true;
        modelParams.variantName = 'VOLTA.model.variants.evaluateAdcModelB';
    otherwise
        error('Invalid validationSetChoice: %d. Must be 0, 1, or 2.', ...
          configSetChoice);
end
adcPlotParams = struct('name','FOM', 'plotRangeX',[],'plotRangeY',[],'constantRef',[]);
VOLTA.visualization.plotAdcResults(varParams,modelParams,spec,adcPlotParams);
runTimeVisualization = toc;