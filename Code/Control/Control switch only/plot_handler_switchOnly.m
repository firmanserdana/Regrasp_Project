classdef plot_handler_switchOnly < handle

    properties (Access = public)

        % Paramters
        plotTimeSpan = 5; % [s]

        % ...
        binCmdAxes
        stimAxes

        binCmdLine;
        stimLine;

    end

    methods (Access = public)

        %% Initialize plot
        function initializePlot(obj, binCmdAxes, stimAxes, loopFreq, paramsGUI)

            % Binary command axes
            obj.binCmdAxes = binCmdAxes;
            title(obj.binCmdAxes,'Binary Command');
            obj.binCmdAxes.YLim = [0 1];

            obj.binCmdLine = animatedline(obj.binCmdAxes,'LineStyle','-','LineWidth',0.5,...
                'MaximumNumPoints',round(obj.plotTimeSpan*loopFreq));

            clearpoints(obj.binCmdLine);

            % Stim axes
            obj.stimAxes = stimAxes;
            title(obj.stimAxes,'Stim ch');

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


        %% Plot modulated stim variable
        function plotStimVar(obj, ccPlot, stimCh)

            for iCh = 1:length(stimCh)
                addpoints(obj.stimLine{iCh}, ccPlot, stimCh(iCh));
            end

            drawnow;

        end

    end
end
