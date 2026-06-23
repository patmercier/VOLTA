function [gaParams, plotParams] = optimizationSetA(varParams)
%optimizationSetA Define optimization parameter set for GA-based ADC
%optimization.For use with specific model evaluateAdcModelA.m
%
% This function returns all configuration structures required to run
% genetic-algorithm-based optimization, including GA options and plotting
% parameters.
%
% Details of the options can be found in MATLAB documentation for the ga function.
%% ------------------------------------------------------------------------
% Define gaParams - Setup variables for Genetic Algorithm Options.
% -------------------------------------------------------------------------

gaParams = struct();

%% ------------------------------------------------------------------------
% Constraints Definition
% -------------------------------------------------------------------------
gaParams.constraints = {
    'adc.perf.SNDR',         'spec.SNDR',             -1, true
    'adc.perf.P_TOT',        'spec.P_TOT',             1, true
    'adc.perf.BW',           'spec.BW',               -1, true
    'adc.perf.IRN_FLOOR',    'spec.IRN_FLOOR',         1, true
    'vars(4)',               'adc.perfAux.NDAC_MIN', -1, true
    'adc.perf.RIN',          'spec.RIN',              -1, true
    'vars(6)',               'adc.perfAux.CIN_MIN', -1, true
    'adc.perfAux.VIN_FS',   'spec.VIN_FS',           -1, true
    'adc.perfAux.BW_LOW', 'spec.BW_LOW',            1, true
};


%% ------------------------------------------------------------------------
% Initial Population
% -------------------------------------------------------------------------

gaParams.PopulationSize = 50;

% Empty Initial Population
%gaParams.InitialPopulation = [];

% ------------------------------------------------------------------------
% Initial population by random variation around an initial vector
% ------------------------------------------------------------------------
% varsInit = [32e3 120e6 1.2 9 32e3 20.66e-12];
% %varsInit = [128e3 100e6 1.2 9 128e3 20.66e-12];
% InitVector   = VOLTA.utilities.scaleVariables(varsInit,varParams);
% InitVariance = 0.3;
% gaParams.InitialPopulation = ...
%    VOLTA.optimization.generateInitialPopulation( ...
%        InitVector, gaParams.PopulationSize, InitVariance);

% ------------------------------------------------------------------------
% Random Number Generator Seed for reproducibility of runs
% ------------------------------------------------------------------------
gaParams.UseRNG = 23;

% ------------------------------------------------------------------------
% Initial Penaltly of Augmented Lagrangian
% ------------------------------------------------------------------------
%gaParams.InitialPenalty = 1; % Use low penalty to allow initial infeasibility

%% ------------------------------------------------------------------------
% Selection
% -------------------------------------------------------------------------

gaParams.FitnessScalingFcn = @fitscalingrank;      % Function which evaluates probablities from individual fitnesses
%gaParams.SelectionFcn    = @selectionstochunif;  % Default, best overall
gaParams.SelectionFcn      = @selectionremainder; % Complex, balanced exploration and exploitation. Use if initial population is infeasible and causes premature stopping
%gaParams.SelectionFcn    = @selectiontournament; % Fastest convergence, low diversity

%% ------------------------------------------------------------------------
% Reproduction : Elitism
% -------------------------------------------------------------------------

gaParams.EliteCount = 0.04 * gaParams.PopulationSize; % Keep 1-5% of population size

%% ------------------------------------------------------------------------
% Reproduction : Crossover
% -------------------------------------------------------------------------

gaParams.CrossoverFraction = 0.8;                  % Trades off diversity for fitness/convergence
gaParams.CrossoverFcn      = @crossoverscattered;  % Max diversity and exploration
%gaParams.CrossoverFcn    = @crossoversinglepoint; % Preserves gene linkage of good parents - Can be useful to fix subset of variables
%gaParams.CrossoverFcn    = @crossovertwopoint;

%% ------------------------------------------------------------------------
% Reproduction : Mutation
% -------------------------------------------------------------------------

%gaParams.MutationFcn = {@mutationguassian};       % Guassian function with scale (SD of first generation) and shrink (SD decrease rate)
%gaParams.MutationFcn = {@mutationgaussian, 0.9, 0.5};  % scale, shrink % Guassian function with scale (SD of first generation) and shrink (SD decrease rate)
gaParams.MutationFcn = @mutationadaptfeasible;     % Use when there are bounds or linear constriants - More complex nuanced control but slower

%% ------------------------------------------------------------------------
% Stopping Criteria
% -------------------------------------------------------------------------

gaParams.Generations    = 100;
gaParams.TimeLimit      = Inf;
gaParams.StallGenLimit  = 10;
gaParams.StallTimeLimit = Inf;
gaParams.TolFun         = 1e-8;  % Average change in Fitness in StallTime/StallGen which causes stop
gaParams.TolCon         = 1e-8;  % Changes nonlcon c<=0 to c<=TolCon

%% ------------------------------------------------------------------------
% Visualisation and Processing
% -------------------------------------------------------------------------

gaParams.Display     = 'diagnose';
gaParams.UseParallel = false;

gaParams.PlotFcns = {};
% gaParams.PlotFcns    = {@gaplotbestf, ...
%                         @gaplotscorediversity, ...
%                         @gaplotdistance, ...
%                         @gaplotstopping};

plotParams.varnames = cell(1, length(varParams));
for i = 1:length(varParams)
    plotParams.varnames{i} = varParams(i).name;
end

plotParams.gif_plot_vars = [2 3];  % Indices of variables used for surface plot

plotParams.lb = [];
plotParams.ub = [];
for i = 1:length(varParams)
    plotParams.lb = [plotParams.lb varParams(i).bounds(1)];
    plotParams.ub = [plotParams.ub varParams(i).bounds(2)];
end

end

