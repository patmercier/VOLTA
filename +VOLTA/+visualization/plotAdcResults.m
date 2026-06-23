function plotAdcResults(varParams, modelParams, spec, plotParams)
%plotAdcResults Generate line or surface plots for a specified ADC metric.
%
%   plotAdcResults(varParams, modelParams, spec, plotParams) generates plots for
%   a metric defined in plotParams.name from the ADC model output.
%   Supports 1D line sweeps and 2D surface sweeps.
%
%   INPUTS:
%       varParams  : 1×N struct array describing ADC variables
%       modelParams  : struct containing ADC model parameters
%       spec       : struct containing ADC performance specifications
%       plotParams : struct with fields:
%                       - name         : string, metric field in adc.perf or adc.perfAux
%                       - plotRangeX   : [min max] for X axis (line/surface)
%                       - plotRangeY   : [min max] for Y axis (surface)
%                       - constantRef  : numeric reference line/plane (optional)
%
%   OUTPUTS: None (plots are displayed)
%
%   BEHAVIOR:
%       - Calls varSetup to generate sweep arrays
%       - Iterates through VARS, evaluating ADC_MODEL at each point
%       - Extracts the metric and plots vs sweep variables
%       - Line sweep: metric vs variable with optional reference line
%       - Surface sweep: 3D surface and contour projection with optional reference plane


    %------------------------------
    % Generate sweep variables
    %------------------------------
    varsOut = VOLTA.utilities.setupVariables(varParams);
    nVars = numel(varParams);
    isSurface = strcmpi({varParams.analysisType}, 'surface');
    nSurface = sum(isSurface);

    %------------------------------
    % Prepare storage for metric values
    %------------------------------
    if nSurface == 2
        [nY, nX, ~] = size(varsOut);
        metricValues = zeros(nY, nX);
    elseif nSurface == 0
        [~, L, ~] = size(varsOut);
        metricValues = zeros(L,1);
    else
        error('Surface mode requires exactly 2 Surface variables.');
    end

    nonFixedIdx = find(~strcmpi({varParams.analysisType}, 'Fixed'));

    %------------------------------
    % Evaluate metric across sweep points
    %------------------------------
    if nSurface == 0
        % 1D line sweep
        for i = 1:L
            varPoint = squeeze(varsOut(:,1,:));
            varPoint = varPoint(:,i);  % Extract i-th point

            adcObj = VOLTA.model.evaluateAdcModel(varPoint, modelParams, spec);

            fieldName = plotParams.name;
            if isfield(adcObj.perf, fieldName)
                metricValues(i) = adcObj.perf.(fieldName);
            elseif isfield(adcObj.perfAux, fieldName)
                metricValues(i) = adcObj.perfAux.(fieldName);
            else
                error('Field "%s" not found in adc.perf or adc.perfAux', fieldName);
            end
        end

        % Plot line
        xVarIdx = nonFixedIdx;
        if isempty(xVarIdx)
            error('No variable available for X axis (all Fixed).');
        end
        xVar = squeeze(varsOut(:,1,xVarIdx));
        figure;
        plot(xVar, metricValues, 'LineWidth', 2);
        xlabel(varParams(xVarIdx).name);
        ylabel(fieldName);
        grid on;
        title(sprintf('%s vs %s', fieldName, varParams(xVarIdx).name));

        % Optional X-axis limits
        if isfield(plotParams,'plotRangeX') && ~isempty(plotParams.plotRangeX)
            xlim(plotParams.plotRangeX);
        end

        % Optional reference line
        if isfield(plotParams, 'constantRef') && ~isempty(plotParams.constantRef)
            hold on;
            yline(plotParams.constantRef, '--r', 'LineWidth', 1.5);
            hold off;
        end

    else
        % 2D surface sweep
        idxSurf = find(isSurface);
        var1 = squeeze(varsOut(:,:,idxSurf(1)));
        var2 = squeeze(varsOut(:,:,idxSurf(2)));

        for ix = 1:nY
            for iy = 1:nX
                varPoint = squeeze(varsOut(ix,iy,:));
                adcObj = VOLTA.model.evaluateAdcModel(varPoint, modelParams, spec);

                fieldName = plotParams.name;
                if isfield(adcObj.perf, fieldName)
                    metricValues(ix,iy) = adcObj.perf.(fieldName);
                elseif isfield(adcObj.perfAux, fieldName)
                    metricValues(ix,iy) = adcObj.perfAux.(fieldName);
                else
                    error('Field "%s" not found in adc.perf or adc.perfAux', fieldName);
                end
            end
        end

        % -----------------------------
        % Surface plot + contour projection
        % -----------------------------
        figure;

        % 3D surface
        subplot(1,2,1)
        surf(var1, var2, metricValues);
        shading faceted;
        xlabel(varParams(idxSurf(1)).name);
        ylabel(varParams(idxSurf(2)).name);
        zlabel(fieldName);
        title(sprintf('%s Surface', fieldName));
        ax = gca;
        ax.FontSize = ax.FontSize + 2;        % axis scale (tick labels)
        
        hx = xlabel(varParams(idxSurf(1)).name); hx.FontSize = hx.FontSize + 4;
        hy = ylabel(varParams(idxSurf(2)).name); hy.FontSize = hy.FontSize + 4;
        hz = zlabel(fieldName);               hz.FontSize = hz.FontSize + 4;
        
        ht = title(sprintf('%s Surface', fieldName));
        ht.FontSize = ht.FontSize + 2;

        colorbar;
        view(120, 15);

        % Highlight min/max
        [minVal, idxMin] = min(metricValues(:));
        [maxVal, idxMax] = max(metricValues(:));
        [rowMin, colMin] = ind2sub(size(metricValues), idxMin);
        [rowMax, colMax] = ind2sub(size(metricValues), idxMax);
        hold on;
        plot3(var1(rowMin,colMin), var2(rowMin,colMin), minVal, 'go', 'MarkerSize', 10, 'LineWidth', 2);
        plot3(var1(rowMax,colMax), var2(rowMax,colMax), maxVal, 'ro', 'MarkerSize', 10, 'LineWidth', 2);

        % Optional reference plane
        if isfield(plotParams, 'constantRef') && ~isempty(plotParams.constantRef)
            plot3(var1, var2, plotParams.constantRef*ones(size(var1)), '-', 'Color', 'cyan', 'LineWidth', 1.5);
        end
        hold off;

        % Apply axis limits if provided
        if isfield(plotParams,'plotRangeX') && ~isempty(plotParams.plotRangeX)
            xlim(plotParams.plotRangeX);
        end
        if isfield(plotParams,'plotRangeY') && ~isempty(plotParams.plotRangeY)
            ylim(plotParams.plotRangeY);
        end

        % Contour projection
        subplot(1,2,2)
        contourf(var1, var2, metricValues, 25);
        xlabel(varParams(idxSurf(1)).name);
        ylabel(varParams(idxSurf(2)).name);
        title(sprintf('%s Contour Projection', fieldName));
        ax = gca;
        ax.FontSize = ax.FontSize + 2;        % axis scale (tick labels)
        
        hx = xlabel(varParams(idxSurf(1)).name); hx.FontSize = hx.FontSize + 4;
        hy = ylabel(varParams(idxSurf(2)).name); hy.FontSize = hy.FontSize + 4;
        
        ht = title(sprintf('%s Contour Projection', fieldName));
        ht.FontSize = ht.FontSize + 2;

        colorbar;
        grid on;
    end
end
