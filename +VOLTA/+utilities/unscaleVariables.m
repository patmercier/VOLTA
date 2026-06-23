function vars = unscaleVariables(varsScaled, varParams)
%unscaleVariables Map normalized variables back to their physical bounds.
%
%   vars = unscaleVariables(varsScaled, varParams) converts variables scaled
%   between 0 and 1 into their corresponding physical values using the
%   bounds defined in varParams.
%
%   INPUTS:
%       varsScaled : 1×N numeric array
%           Normalized variables, assumed to lie in [0, 1].
%
%       varParams  : 1×N struct array
%           Each element must contain a field 'bounds' of the form
%           [lowerBound, upperBound].
%
%   OUTPUT:
%       vars : 1×N numeric array
%           Unscaled variables mapped to their specified bounds.
%
%   ASSUMPTIONS:
%       - varsScaled and varParams have the same length.
%       - bounds are ordered as [min, max].
%       - Inputs are not clamped to [0,1]; scaling is strictly linear.

    %------------------------------
    % Input validation (API guard)
    %------------------------------
    validateattributes(varsScaled, {'numeric'}, {'vector'}, mfilename, 'varsScaled');
    validateattributes(varParams,  {'struct'},  {'vector'}, mfilename, 'varParams');

    assert(numel(varsScaled) == numel(varParams), ...
        'unscaleVars:DimensionMismatch', ...
        'varsScaled and varParams must have the same length.');

    % Preallocate output to enforce shape and avoid dynamic resizing
    vars = zeros(1, numel(varParams));

    %------------------------------
    % Linear unscaling
    %------------------------------
    for idx = 1:numel(varParams)
        bounds = varParams(idx).bounds;

        % Explicit bound extraction clarifies affine mapping intent
        lowerBound = bounds(1);
        upperBound = bounds(2);

        % Linear transform preserves optimizer ordering and spacing
        vars(idx) = lowerBound + ...
                    varsScaled(idx) * (upperBound - lowerBound);
    end
end
