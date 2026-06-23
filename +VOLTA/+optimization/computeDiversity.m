function div = computeDiversity(pop)
%COMPUTEDIVERSITY Compute average pairwise Euclidean distance of a population.
%
%   div = computeDiversity(pop) returns a scalar measuring the mean Euclidean
%   distance between all pairs of individuals in the population matrix pop.
%   This is often used as a diversity metric in evolutionary algorithms.
%
%   INPUT:
%       pop : N x M numeric matrix
%             N = number of individuals
%             M = number of variables per individual
%
%   OUTPUT:
%       div : scalar
%             Average pairwise Euclidean distance among all individuals.
%
%   NOTES:
%       - If population has fewer than 2 individuals, div = 0.
%       - This metric is insensitive to absolute values; only relative spacing matters.

    %------------------------------
    % Input validation (fail fast)
    %------------------------------
    validateattributes(pop, {'numeric'}, {'2d'}, mfilename, 'pop');

    [numIndividuals, ~] = size(pop);

    % Less than 2 individuals → no pairwise distance possible
    if numIndividuals < 2
        div = 0;
        return;
    end

    %------------------------------
    % Compute sum of all pairwise distances
    %------------------------------
    distSum = 0;
    count = 0;

    for i = 1:numIndividuals
        for j = i+1:numIndividuals
            % Euclidean distance between individual i and j
            distSum = distSum + norm(pop(i,:) - pop(j,:));
            count = count + 1;
        end
    end

    % Average pairwise distance
    div = distSum / count;
end
