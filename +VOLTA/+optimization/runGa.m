function [xOpt, fVal, exitFlag, gaOut] = runGa(gaParams, plotParams, varParams, modelParams, spec)
%runGa Run GA optimization for ADC design variables with custom plotting.
%
%   [xOpt, fVal, exitFlag, gaOut] = runGa(gaParams, plotParams, varParams, modelParams, spec)
%   performs a Genetic Algorithm (GA) optimization of ADC design variables.
%
%   INPUTS:
%       gaParams   : GA options structure (optimoptions)
%       plotParams : Structure containing plotting parameters for GA output function
%       varParams  : Structure array describing ADC variables
%       modelParams  : Structure containing ADC model parameters
%       spec       : Structure containing ADC specifications
%
%   OUTPUTS:
%       xOpt     : 1xN vector of optimized variables (scaled 0-1)
%       fVal     : Fitness value at optimum (FoM scaled)
%       exitFlag : GA exit flag
%       gaOut    : GA output structure (all generations and info)
%
%   NOTES:
%       - The GA operates on variables scaled between 0 and 1.
%       - Fitness function is the normalized Schreier Figure-of-Merit (FoM).
%       - Constraints are normalized for GA convergence.
%       - A custom OutputFcn visualizes GA progress in real-time.

    %------------------------------
    % Input validation
    %------------------------------
    validateattributes(gaParams,   {'struct'}, {}, mfilename, 'gaParams');
    validateattributes(plotParams, {'struct'}, {}, mfilename, 'plotParams');
    validateattributes(varParams,  {'struct'}, {'vector'}, mfilename, 'varParams');
    validateattributes(modelParams,  {'struct'}, {}, mfilename, 'modelParams');
    validateattributes(spec,       {'struct'}, {}, mfilename, 'spec');

    %------------------------------
    % Number of design variables
    %------------------------------
    nVars = numel(varParams);

    %------------------------------
    % Define GA fitness and nonlinear constraint functions
    %------------------------------
    fitnessFcn = @(varsScaled) VOLTA.optimization.computeFoMScaled(varsScaled, varParams, modelParams, spec);
    nonlconFcn = @(varsScaled) VOLTA.optimization.computePerfConstraintsScaled(varsScaled, varParams, modelParams, spec, gaParams);

    %------------------------------
    % Scaled variable bounds [0,1]
    %------------------------------
    lbScaled = zeros(1, nVars);
    ubScaled = ones(1, nVars);

    %------------------------------
    % Set GA output function for visualization
    %------------------------------
    gaParams.OutputFcns = @(options, state, flag) VOLTA.visualization.plotOptiResults(...
        options, state, flag, varParams, plotParams, modelParams, spec, gaParams);

    %------------------------------
    % Run GA optimization
    %------------------------------
    [xOpt, fVal, exitFlag, gaOut] = ga(...
        fitnessFcn, nVars, [], [], [], [], lbScaled, ubScaled, ...
        nonlconFcn, gaParams);
end
