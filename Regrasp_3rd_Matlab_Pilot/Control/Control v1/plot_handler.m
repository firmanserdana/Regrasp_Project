classdef plot_handler

    methods(Static)
        
        %% Initialize plot
        function [figStreams, binCmdLine, propCmdLine, stimLine] = initializePlot(vars)
            
            figStreams = figure;

            % Binary command axes
            binCmdAxes = subplot(3,1,1);
            title(binCmdAxes,'Binary Command');
            binCmdAxes.YLim = [0 1];

            binCmdLine = animatedline(binCmdAxes,'LineStyle','-','LineWidth',0.5,...
                'MaximumNumPoints',round(vars.plotTimeSpan/vars.readWind));
            
            % Proportional command axes
            propCmdAxes = subplot(3,1,2);
            title(propCmdAxes,'Proportional Command');
            %propCmdAxes.YLim = [0 1];

            propCmdLine = animatedline(propCmdAxes,'LineStyle','-','LineWidth',0.5,...
                'MaximumNumPoints',round(vars.plotTimeSpan/vars.readWind));
            
            % Stim axes
            stimAxes = subplot(3,1,3);
            title(stimAxes,'Modulated stim parameter');

            stimLine = animatedline(stimAxes,'LineStyle','-','LineWidth',0.5,...
                'MaximumNumPoints',round(vars.plotTimeSpan/vars.readWind));

        end


        %% Plot binary command
        function plotBinCmd(figStreams, binCmdLine, binCmd, ccPlot)

            figure(figStreams);

            addpoints(binCmdLine, ccPlot, binCmd);
            
            drawnow;
        end
        
        %% Plot proportional command
        function plotPropCmd(figStreams, propCmdLine, propCmd, ccPlot)

            figure(figStreams);

            addpoints(propCmdLine, ccPlot, propCmd);
            
            drawnow;

        end
        
        %% Plot modulated stim variable
        function plotStimVar(figStreams, stimLine, stimAmp, stimFreq, varsGUI, ccPlot)

            figure(figStreams);
            
            if varsGUI.modType==1 % AM
                addpoints(stimLine, ccPlot, stimAmp);
            elseif varsGUI.modType==2 % FM
                addpoints(stimLine, ccPlot, stimFreq);
            end
            
            drawnow;


        end

    end
end
