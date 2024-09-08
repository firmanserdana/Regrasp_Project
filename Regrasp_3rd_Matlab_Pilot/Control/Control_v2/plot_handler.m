classdef plot_handler < handle

    properties (Access = public)

        % Paramters
        plotTimeSpan = 5; % [s]

        % ...
        binCmdAxes
        propCmdAxes
        stimAxes

        binCmdLine;
        propCmdLine;
        stimLine;

    end

    methods (Access = public)

        %% Initialize plot
        function initializePlot(obj, binCmdAxes, propCmdAxes, stimAxes, loopFreq, paramsGUI)

            % Binary command axes
            obj.binCmdAxes = binCmdAxes;
            title(obj.binCmdAxes,'Binary Command');
            obj.binCmdAxes.YLim = [0 1];

            obj.binCmdLine = animatedline(obj.binCmdAxes,'LineStyle','-','LineWidth',0.5,...
                'MaximumNumPoints',round(obj.plotTimeSpan*loopFreq));

            clearpoints(obj.binCmdLine);

            % Proportional command axes
            obj.propCmdAxes = propCmdAxes;
            title(obj.propCmdAxes,'Proportional Command');
            obj.propCmdAxes.YLim = [0 1];

            obj.propCmdLine = animatedline(obj.propCmdAxes,'LineStyle','-','LineWidth',0.5,...
                'MaximumNumPoints',round(obj.plotTimeSpan*loopFreq));

            clearpoints(obj.propCmdLine);

            % Stim axes
            obj.stimAxes = stimAxes;
            title(obj.stimAxes,'Modulated stim parameter');

            obj.stimLine = {};

            for iCh = 1:size(paramsGUI.stimCh,2)
                obj.stimLine{iCh} = animatedline(obj.stimAxes,'LineStyle','-','LineWidth',0.5,...
                    'MaximumNumPoints',round(obj.plotTimeSpan*loopFreq));
                clearpoints(obj.stimLine{iCh});
            end

        end


        %% Plot binary command
        function plotBinCmd(obj, ccPlot, binCmd)

            addpoints(obj.binCmdLine, ccPlot, binCmd);

            drawnow;
        end

        %% Plot proportional command
        function plotPropCmd(obj, ccPlot, propCmd)

            addpoints(obj.propCmdLine, ccPlot, propCmd);

            drawnow;

        end

        %% Plot modulated stim variable
        function plotStimVar(obj, ccPlot, varsGUI, stimAmp, stimFreq)

            if strcmp(varsGUI.modType,'AM') % AM
                for iCh = 1:length(stimAmp)
                    addpoints(obj.stimLine{iCh}, ccPlot, stimAmp(iCh));
                end
            elseif strcmp(varsGUI.modType,'FM') % FM
                for iCh = 1:length(stimFreq)
                    addpoints(obj.stimLine{iCh}, ccPlot, stimFreq(iCh));
                end
            end

            drawnow;

        end

    end
end
