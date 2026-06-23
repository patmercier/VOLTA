function foM = computeFoM(vars, modelParams, spec)
%computeFoM Compute the Figure of Merit (FoM) for an ADC given design variables.
%
%   foM = computeFoM(vars, modelParams, spec) runs the ADC model with the
%   specified design variables, parameters, and performance specifications.
%   It returns the Schreier Figure of Merit (FoM) from the model output.
%
%   INPUTS:
%       vars      : 1×N numeric array
%           Design variables for the ADC model.
%
%       modelParams : struct
%           ADC parameters.
%
%       spec      : struct
%           ADC performance specifications.
%
%   OUTPUT:
%       foM : numeric scalar
%           Schreier Figure of Merit computed by the ADC model.
%
%   NOTES:
%       - This function is typically used as the objective function in
%         nonlinear constrained optimization.
%       - All model evaluation details are encapsulated in the +model package.

    %------------------------------
    % Input validation (fail fast)
    %------------------------------
    validateattributes(vars, {'numeric'}, {'vector'}, mfilename, 'vars');
    validateattributes(modelParams, {'struct'}, {}, mfilename, 'modelParams');
    validateattributes(spec, {'struct'}, {}, mfilename, 'spec');

    %------------------------------
    % Evaluate ADC model
    %------------------------------
    adc = VOLTA.model.evaluateAdcModel(vars, modelParams, spec);  
    % Extract Figure of Merit from structured output; simplifies optimization calls
    foM = adc.perf.FOM;
end
