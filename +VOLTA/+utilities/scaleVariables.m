function varsScaled = scaleVariables(vars, varParams)
%scaleVariables Normalize variables to the unit interval.
%
%   varsScaled = scaleVariables(vars, varParams) linearly maps variables
%   defined within specified bounds to the unit interval [0, 1].
%
%   INPUTS:
%       vars : 1×N numeric array
%           Variables defined in physical units.
%
%       varParams : 1×N struct array
%           Each element must contain a field 'bounds' of the form
%           [lowerBound, upperBound].
%
%   OUTPUT:
%       varsScaled : 1×N numeric array
%           Variables mapped to the unit interval.
%
%   ASSUMPTIONS:
%       - vars and varParams have the same length.
%       - bounds are ordered as [min, max].
%       - Outputs are not clamped to [0,1]; scaling is strictly linear.

    %------------------------------
    % Input validation (API guard)
    %------------------------------
    validateattributes(vars, {'numeric'}, {'vector'}, mfilename, 'vars');
    validateattributes(varParams, {'struct'}, {'vector'}, mfilename, 'varParams');

    assert(numel(vars) == numel(varParams), ...
        'scaleVars:DimensionMismatch', ...
        'vars and varParams must have the same length.');

    % Preallocate output to enforce shape and avoid dynamic resizing
    varsScaled = zeros(1, numel(vars));

    %------------------------------
    % Linear scaling
    %------------------------------
    for idx = 1:numel(vars)
        bounds = varParams(idx).bounds;

        % Explicit extraction avoids ambiguity in affine normalization
        lowerBound = bounds(1);
        upperBound = bounds(2);

        % Linear normalization preserves optimizer geometry
        varsScaled(idx) = ...
            (vars(idx) - lowerBound) / (upperBound - lowerBound);
    end
end
