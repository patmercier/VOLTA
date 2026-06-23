function [c, cEq, scaleFactor] = computePerfConstraints(vars, modelParams, spec, gaParams)
%computePerfConstraints Compute constraint violations and normalizing factors for ADC optimization.
%
%   [c, cEq, scaleFactor] = computePerfConstraints(vars, modelParams, spec) evaluates
%   the ADC model and returns inequality constraints in the form c(x) <= 0,
%   equality constraints (empty), and scale factors used to normalize each
%   constraint for optimization purposes.
%
%   INPUTS:
%       vars      : 1×N numeric array
%           Design variables for the ADC model.
%
%       modelParams : struct
%           ADC parameter set, including architectural and device details.
%
%       spec      : struct
%           Target specifications for SNDR, Power, Bandwidth, IRN, etc.
%
%      gaParams.constraints : Constraint specification 
%           Each row defines one non-linear inequality constraint. Only
%           defined constraints are evaluated. Constraints which are
%           defined but don't exist in evaluated ADC model are skipped.
%           This allows same constraint evaluation logic for any model. 
%
%           Cell array with rows of the form:
%           {lhsExpr, rhsExpr, sign, en}
%               sign :
%                   +1 :  (lhsExpr - rhsExpr) <= 0
%                   -1 : -(lhsExpr - rhsExpr) <= 0   (i.e. LHS >= RHS)    %
%               en (boolean):
%                   true  : constraint is active and evaluated
%                   false : constraint is disabled and skipped
%
%           Example:
%               gaParams.constraints = {
%               'adc.perf.SNDR',        'spec.SNDR',           -1, true
%               'adc.perf.P_TOT',       'spec.P_TOT',           1, false
%               'vars(4)',              'adc.perfAux.NDAC_MIN', -1, true
%               };
%
%   OUTPUTS:
%       c          : 1×M numeric array
%           Inequality constraint violations. When spec is met, c(i) = 0;
%           violations produce positive values (c > 0).
%
%       cEq        : empty array
%           Equality constraints (none for this model). Included for
%           completeness and future development. 
%
%       scaleFactor : 1×M numeric array
%           Normalization factors for each constraint to aid optimizer
%           convergence.

    %------------------------------
    % Evaluate ADC model
    %------------------------------
    adc = VOLTA.model.evaluateAdcModel(vars, modelParams, spec);

    %------------------------------
    % Inequality constraints
    %------------------------------
    numConstraints = size(gaParams.constraints,1);
    
    % Preallocate maximum possible size
    c           = zeros(numConstraints,1);
    scaleFactor = zeros(numConstraints,1);
    
    % Counter for active constraints
    nActive = 0;
    
    % Loop over all declared constraints
    for k = 1:numConstraints
    
        lhsExpr = gaParams.constraints{k,1};
        rhsExpr = gaParams.constraints{k,2};
        sign     = gaParams.constraints{k,3};
        en      = gaParams.constraints{k,4};
    
        % Skip if disabled
        if ~en
            continue;
        end
    
        % Evaluate constraint only if field referenced in
        % gaParams.constraints exists in evaluated ADC model
        try
            lhs = eval(lhsExpr);
            rhs = eval(rhsExpr);
        catch
            continue;   % skip constraints referencing missing fields
        end
    
        % Increment active constraint counter
        nActive = nActive + 1;
    
        % Store constraint and scale factor
        c(nActive)           = sign * (lhs - rhs);
        scaleFactor(nActive) = rhs;
    
    end
    
    % Trim unused preallocated entries
    c           = c(1:nActive);
    scaleFactor = scaleFactor(1:nActive);
    
    %-------------------------------------------------
    % Equality constraints : Unused in V1.0 ADC Models
    %-------------------------------------------------
    cEq = [];


end
