function foMNorm = computeFoMScaled(varsScaled, varParams, modelParams, spec)
%computeFoMScaled Compute normalized Figure of Merit (FoM) for GA optimization.
%
%   foMNorm = foMScaled(varsScaled, varParams, modelParams, spec) scales
%   design variables for GA optimization, evaluates the ADC model, and
%   returns a normalized FoM suitable for GA objectives.
%
%   INPUTS:
%       varsScaled : 1×N numeric array
%           Normalized design variables in [0, 1] for GA optimization.
%
%       varParams  : 1×N struct array
%           Parameter bounds for each design variable, used for unscaling.
%
%       modelParams  : struct
%           ADC parameter set (e.g., architecture and device parameters).
%
%       spec       : struct
%           ADC performance specifications (e.g., SNR, bandwidth).
%
%   OUTPUT:
%       foMNorm : numeric scalar
%           Normalized Schreier Figure of Merit, scaled to [-1, 0] for GA
%           minimization.
%
%   NOTES:
%       - Input variables are unscaled before calling the ADC FoM function.
%       - Output FoM is scaled by modelParams.maxFoM to normalize magnitude.
%       - This function is intended as an objective function in
%         nonlinear constrained GA optimization.

    %------------------------------
    % Input validation
    %------------------------------
    validateattributes(varsScaled, {'numeric'}, {'vector'}, mfilename, 'varsScaled');
    validateattributes(varParams,  {'struct'},  {'vector'}, mfilename, 'varParams');
    validateattributes(modelParams,  {'struct'}, {}, mfilename, 'modelParams');
    validateattributes(spec,       {'struct'}, {}, mfilename, 'spec');

    %------------------------------
    % Unscale variables for actual ADC evaluation
    %------------------------------
    vars = VOLTA.utilities.unscaleVariables(varsScaled, varParams);

    %------------------------------
    % Compute actual Figure of Merit
    %------------------------------
    foM = VOLTA.optimization.computeFoM(vars, modelParams, spec);

    %------------------------------
    % Normalize FoM for GA
    %------------------------------
    % Scale by modelParams.maxFoM so that FoM is in [0, 1]
    % Multiply by -1 because GA performs minimization
    foMNorm = -foM / modelParams.maxFoM;
end
