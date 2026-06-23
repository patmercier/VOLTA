function [cScaled, cEqScaled] = computePerfConstraintsScaled(varsScaled, varParams, modelParams, spec, gaParams)
%computePerfConstraintsScaled Compute normalized constraints for GA/nonlinear optimization.
%
%   [cScaled, cEqScaled] = computePerfConstraintsScaled(varsScaled, varParams, modelParams, spec)
%   unscales the design variables, evaluates the ADC model constraint violations,
%   and normalizes them using scale factors. Returns constraints suitable
%   for GA or other nonlinear constrained optimization routines.
%
%   INPUTS:
%       varsScaled : 1×N numeric array
%           Normalized design variables in [0, 1].
%
%       varParams  : 1×N struct array
%           Parameter bounds for unscaling.
%
%       modelParams  : struct
%           ADC parameters (architecture, devices, etc.).
%
%       spec       : struct
%           ADC performance specifications.
%
%   OUTPUTS:
%       cScaled   : 1×M numeric array
%           Normalized inequality constraints (c <= 0 at spec, >0 if violated).
%
%       cEqScaled : 1×K numeric array
%           Normalized equality constraints (empty if none).

    %------------------------------
    % Unscale design variables
    %------------------------------
    vars = VOLTA.utilities.unscaleVariables(varsScaled, varParams);

    %------------------------------
    % Evaluate constraints
    %------------------------------
    [c, cEq, scaleFactor] = VOLTA.optimization.computePerfConstraints(vars, modelParams, spec, gaParams);

    %------------------------------
    % Scale constraints by scaleFactor for optimizer
    %------------------------------
    cScaled   = zeros(size(c));
    cEqScaled = zeros(size(cEq));

    for idx = 1:length(c)
        cScaled(idx) = c(idx) / scaleFactor(idx);

        % Only scale equality constraints if they exist at this index
        if idx <= length(cEqScaled)
            cEqScaled(idx) = cEq(idx) / scaleFactor(idx);
        end
    end
end
