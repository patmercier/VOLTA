function [state, options, optChanged] = plotOptiResults(options, state, flag, varParams, plotParams, modelParams, spec, gaParams)
%plotOptiResults GA Output Function for real-time monitoring and visualization.
%
%   Usage:
%       options = optimoptions('ga', 'OutputFcn', ...
%                   @(options,state,flag) plotOptiResults(options,state,flag,varParams,plotParams,modelParams,spec,gaParams));
%
%   Tracks fitness, constraint violation, variable statistics, diversity,
%   and optionally plots surface sweeps.
%
%   INPUTS:
%       options     : GA options structure (passed by GA)
%       state       : GA state structure (population, scores, generation, etc.)
%       flag        : GA stage ('init', 'iter', 'done')
%       varParams   : struct array describing design variables
%       plotParams  : struct describing plotting options (name, ranges, reference, varnames)
%       modelParams   : struct containing ADC parameters
%       spec        : struct containing ADC specifications
%       gaParams    : struct with GA-specific parameters (e.g., TolCon)
%
%   OUTPUTS:
%       state       : GA state (unchanged)
%       options     : GA options (unchanged)
%       optChanged  : logical flag (false, no options modified)

    optChanged = false;

    %------------------------------
    % Persistent history arrays
    %------------------------------
    persistent figHandle popHistory popScoresHistory cvHistory ...
               histBest histMean histCvBest histCvMean ...
               histVarMin histVarMean histVarMax histDiv;

    %------------------------------
    % Initialize figure and histories
    %------------------------------
    if isempty(figHandle) || ~isvalid(figHandle)
        figHandle = figure('Name','GA Optimization Monitor','NumberTitle','off');
    end

    switch lower(flag)
        case 'init'
            % Clear histories at start
            histBest = []; histMean = [];
            histCvBest = []; histCvMean = [];
            histVarMin = []; histVarMean = []; histVarMax = [];
            histDiv = [];
            popHistory = [];
            popScoresHistory = [];
            cvHistory = [];
            return;

        case 'iter'
            gen = max(1, state.Generation);  % generation index
            pop = state.Population;
            scores = state.Score;
            nPop = size(pop,1);

            %------------------------------
            % Constraint violation (scaled)
            %------------------------------
            cv = zeros(nPop,1);
            for i = 1:nPop
                [c, ceq] = VOLTA.optimization.computePerfConstraintsScaled(pop(i,:), varParams, modelParams, spec, gaParams);
                cv(i) = sum(max(c(:),0)) + sum(abs(ceq(:)));
            end
            cvHistory = [cvHistory; cv];

            %------------------------------
            % Store history metrics
            %------------------------------
            histBest(gen) = min(scores);
            histMean(gen) = mean(scores);
            histCvBest(gen) = min(cv);
            histCvMean(gen) = mean(cv);

            % Variable stats
            histVarMin(gen,:) = min(pop, [], 1);
            histVarMean(gen,:) = mean(pop, 1);
            histVarMax(gen,:) = max(pop, [], 1);

            % Diversity metric
            histDiv(gen) = VOLTA.optimization.computeDiversity(pop);

            % Update population history
            popHistory = [popHistory; pop];
            popScoresHistory = [popScoresHistory; scores];

            %------------------------------
            % 4-panel live plots
            %------------------------------
            figure(figHandle);
            
            % ----- Subplot 1: Fitness -----
            subplot(2,2,1); cla; hold on;
            plot(1:gen, histBest(1:gen), 'LineWidth', 2);
            plot(1:gen, histMean(1:gen), 'LineWidth', 2);
            grid on; xlabel('Generation','FontSize',18); ylabel('Fitness','FontSize',18);
            title('Population Fitness','FontSize',20); 
            lgd = legend('Best','Mean'); lgd.FontSize = 16;
            set(gca,'FontSize',18);
            hold off;
            
            % ----- Subplot 2: Constraint Violation -----
            subplot(2,2,2); cla; hold on;
            plot(1:gen, histCvMean(1:gen), 'LineWidth', 2);
            set(gca,'YScale','log'); grid on;
            xlabel('Generation','FontSize',18); ylabel('Constraint Violation','FontSize',18);
            title('Mean Constraint Violation','FontSize',20);
            set(gca,'FontSize',18);
            hold off;
            
            % ----- Subplot 3: Mean Variables -----
            subplot(2,2,3); cla; hold on;
            nVars = size(pop,2);
            colors = lines(nVars);
            if isfield(plotParams,'varnames')
                varNames = plotParams.varnames;
            else
                varNames = arrayfun(@(k) sprintf('Var%d',k), 1:nVars, 'UniformOutput', false);
            end
            for k = 1:nVars
                plot(1:gen, histVarMean(1:gen,k), 'LineWidth',2,'Color',colors(k,:));
            end
            grid on; xlabel('Generation','FontSize',18); ylabel('Scaled Variable Value','FontSize',18);
            title('Mean Population Variables','FontSize',20); 
            lgd = legend(varNames,'Location','bestoutside'); lgd.FontSize = 16;
            set(gca,'FontSize',18);
            hold off;
            
            % ----- Subplot 4: Diversity -----
            subplot(2,2,4); cla; hold on;
            plot(1:gen, histDiv(1:gen),'LineWidth',2);
            grid on; xlabel('Generation','FontSize',18); ylabel('Diversity','FontSize',18);
            title('Mean Euclidean Diversity','FontSize',20);
            set(gca,'FontSize',18);
            hold off;
            
            drawnow;

        case 'done'
            %------------------------------
            % Final surface plot
            %------------------------------
            idxSurf = find(strcmpi({varParams.analysisType}, 'Surface'));
            if numel(idxSurf) ~= 2
                warning('Surface plot requires exactly 2 Surface variables. Skipping surface visualization.');
                return;
            end

            % Determine best individual
            [~, bestIdx] = min(state.Score);
            bestScaled = state.Population(bestIdx,:);
            bestUnscaled = zeros(1,numel(varParams));

            for k = 1:numel(varParams)
                lb = varParams(k).bounds(1);
                ub = varParams(k).bounds(2);
                bestUnscaled(k) = lb + bestScaled(k)*(ub - lb);
                varParams(k).fixedValue = bestUnscaled(k);
            end

            % Generate sweep for surface variables
            varsSurface = VOLTA.utilities.setupVariables(varParams);
            X = squeeze(varsSurface(:,:,idxSurf(1)));
            Y = squeeze(varsSurface(:,:,idxSurf(2)));
            Z = zeros(size(X));

            for i = 1:size(X,1)
                for j = 1:size(X,2)
                    v = squeeze(varsSurface(i,j,:));
                    Z(i,j) = VOLTA.optimization.computeFoM(v, modelParams, spec);  % FoM for each point
                end
            end

            % Unscale all populations
            allPopUnscaled = zeros(size(popHistory));
            for k = 1:numel(varParams)
                lb = varParams(k).bounds(1);
                ub = varParams(k).bounds(2);
                allPopUnscaled(:,k) = lb + popHistory(:,k).*(ub - lb);
            end

            FoMVals = -popScoresHistory*modelParams.maxFoM;  % Match GA scaling
            isFeasible = (cvHistory <= gaParams.TolCon);

            %------------------------------
            % Plot surface and population
            %------------------------------
            fig = figure('Name','GA Population on Surface','NumberTitle','off');
            set(fig,'Units','pixels','Position',get(0,'ScreenSize'));
            surf(X,Y,Z,'FaceAlpha',0.6); hold on;
            colormap turbo; shading interp; colorbar; view(-50,30);
            plot_idx = idxSurf;

            % Feasible points (green)
            h1 = scatter3(allPopUnscaled(isFeasible, idxSurf(1)), ...
                     allPopUnscaled(isFeasible, idxSurf(2)), ...
                     FoMVals(isFeasible), 40,'g','filled');

            % Infeasible points (red)
            h2 = scatter3(allPopUnscaled(~isFeasible, idxSurf(1)), ...
                     allPopUnscaled(~isFeasible, idxSurf(2)), ...
                     FoMVals(~isFeasible), 40,'r');

            % Optimum (blue star)
            h3 = scatter3(bestUnscaled(idxSurf(1)), bestUnscaled(idxSurf(2)), ...
                     -state.Score(bestIdx)*modelParams.maxFoM, 200,'b','p','filled');

            xlabel(varParams(idxSurf(1)).name,'FontSize',20,'FontWeight','bold');
            ylabel(varParams(idxSurf(2)).name,'FontSize',20,'FontWeight','bold');
            zlabel('FoM','FontSize',12,'FontWeight','bold');
            legend([h1 h2 h3], ...
                {'Feasible', 'Infeasible', 'Optimum'}, ...
                'Location','southeastoutside', ...
                'FontSize',18);        
            title('Optimization Solution Space','FontSize',22,'FontWeight','bold');
            hold off;
    end

%% Save genetic algorithm population data in outputs folder
    % Output directory (relative to this function file)
    outDir = fullfile(fileparts(mfilename('fullpath')), '..', 'outputs');
    
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    
    save(fullfile(outDir, 'histBest.mat'),         'histBest');
    save(fullfile(outDir, 'histMean.mat'),         'histMean');
    save(fullfile(outDir, 'histCvBest.mat'),       'histCvBest');
    save(fullfile(outDir, 'histCvMean.mat'),       'histCvMean');
    
    save(fullfile(outDir, 'histVarMin.mat'),       'histVarMin');
    save(fullfile(outDir, 'histVarMean.mat'),      'histVarMean');
    save(fullfile(outDir, 'histVarMax.mat'),       'histVarMax');
    
    save(fullfile(outDir, 'histDiv.mat'),          'histDiv');
    
    save(fullfile(outDir, 'popHistory.mat'),       'popHistory');
    save(fullfile(outDir, 'popScoresHistory.mat'), 'popScoresHistory');
end