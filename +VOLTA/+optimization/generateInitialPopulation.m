function InitPopulation = generateInitialPopulation(InitVector, InitPopSize, variance)
% generateInitialPopulation - Generates a population of InitPopSize individuals
% by perturbing the given initial point InitVector.
%
% Inputs:
%   InitVector              - Initial point (1×D or D×1 vector)
%   InitPopSize               - Population size (integer >= 1)
%   variance - Scalar for variance of noise
%
% Output:
%   InitPopulation             - N×D matrix of individuals

    % Ensure x0 is a row vector
    InitVector = InitVector(:)';  
    D = length(InitVector);  % Number of variables = Dimension of problem

    % Handle default variation scale
    if nargin < 3
        variance = 0.1;  % default std dev for all variables
    end
    if isscalar(variance)
        variance = repmat(variance, 1, D);
    elseif length(variance) ~= D
        error('variation must be scalar or match length of x0.');
    end

    % Initialize population matrix
    InitPopulation = zeros(InitPopSize, D);
    InitPopulation(1,:) = InitVector;  % First individual is the given initial point

    % Generate N-1 individuals with random Gaussian variation
    for i = 2:InitPopSize
        noise = randn(1, D) .* sqrt(variance);
        InitPopulation(i,:) = InitVector + noise; % Population with mean around InitVector and given variance
    end
end
