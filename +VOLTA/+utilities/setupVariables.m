function varsOut = setupVariables(varParams)
%setupVariables Generate variable sweep arrays from a parameter structure.
%
%   varsOut = setupVariables(varParams) constructs sweep matrices for each
%   design variable, supporting Fixed, Line, and Surface analysis types.
%
%   INPUT:
%       varParams : 1×N struct array
%           Fields required for each variable:
%               - name         : Variable name (string)
%               - range        : [min max] desired sweep range
%               - bounds       : [min max] hard limits
%               - analysisType : 'fixed', 'line', or 'Surface'
%               - sweepType    : 'lin' or 'log' (required for Line/Surface)
%               - sweepLength  : Number of points in sweep vector
%               - fixedValue   : Numeric value for Fixed variables
%
%   OUTPUT:
%       varsOut : 3-D array (Ny × Nx × N)
%           Sweep mesh for each variable. For Surface analysis, meshgrid is
%           applied; for Fixed, constant; for Line, 1D sweep expanded as needed.
%
%   ERRORS:
%       - More or fewer than 2 Surface variables.
%       - Non-Fixed variables when Surface sweeps exist.
%       - Missing SweepType or SweepLength for Line/Surface types.

    %------------------------------
    % Input validation
    %------------------------------
    validateattributes(varParams, {'struct'}, {'vector'}, mfilename, 'varParams');

    nVars = numel(varParams);

    % Identify Surface variables
    isSurface = strcmpi({varParams.analysisType}, 'surface');
    idxSurface = find(isSurface);

    % Validate surface sweep conditions
    if isempty(idxSurface)
        nSurface = 1; % No surface sweep → 1D
    elseif numel(idxSurface) == 2
        nSurface = 2; % 2D surface sweep
    else
        error('Exactly two variables must have analysisType="surface" for a surface sweep.');
    end

    %------------------------------
    % Prepare sweep vectors
    %------------------------------
    sweepVectors = cell(1, nVars);

    for i = 1:nVars
        p = varParams(i);

        % Ensure sweep lies within bounds
        rMin = max(p.range(1), p.bounds(1));
        rMax = min(p.range(2), p.bounds(2));

        switch lower(p.analysisType)
            case 'fixed'
                sweepVectors{i} = p.fixedValue;

            case {'line', 'surface'}
                if isempty(p.sweepType) || isempty(p.sweepLength)
                    error('sweepType and sweepLength must be specified for surface or surface analysis.');
                end

                switch lower(p.sweepType)
                    case 'lin'
                        sweepVectors{i} = linspace(rMin, rMax, p.sweepLength);
                    case 'log'
                        sweepVectors{i} = logspace(log10(rMin), log10(rMax), p.sweepLength);
                    otherwise
                        error('Unsupported sweepType "%s". Use "lin" or "log".', p.sweepType);
                end

            otherwise
                error('Unknown analysisType "%s".', p.analysisType);
        end
    end

    %------------------------------
    % Construct output VARS
    %------------------------------
    if nSurface == 2
        % 2D surface sweep
        i1 = idxSurface(1);
        i2 = idxSurface(2);

        vec1 = sweepVectors{i1};
        vec2 = sweepVectors{i2};

        [X, Y] = meshgrid(vec1, vec2);
        [nY, nX] = size(X);

        varsOut = zeros(nY, nX, nVars);

        % Assign surface variables
        varsOut(:,:,i1) = X;
        varsOut(:,:,i2) = Y;

        % Other variables must be fixed
        for i = 1:nVars
            if i == i1 || i == i2
                continue
            end
            if strcmpi(varParams(i).analysisType, 'surface')
                error('All non-surface variables must be Fixed for surface sweeps.');
            end
            varsOut(:,:,i) = varParams(i).fixedValue * ones(nY, nX);
        end

    else
        % No surface sweep → 1D sweep
        % Determine length from first non-fixed variable
        L = 1;
        for i = 1:nVars
            val = sweepVectors{i};
            if isnumeric(val) && numel(val) > 1
                L = numel(val);
                break
            end
        end

        varsOut = zeros(1, L, nVars);

        for i = 1:nVars
            val = sweepVectors{i};
            if numel(val) == 1
                varsOut(:,:,i) = val * ones(1, L);
            else
                varsOut(:,:,i) = val;
            end
        end
    end
end