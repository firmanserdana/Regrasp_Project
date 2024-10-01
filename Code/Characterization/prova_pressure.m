clear all
close all
clc

addpath(genpath(cd));

% Connect with xippmex
xippmex;
pause(1);

% Take zero time
t0 = xippmex('time');

% Setup the axes
pressureAxes = subplot(1,1,1);
plotTimeSpan = 5; % [s]
anLpressure = animatedline(pressureAxes,'LineStyle','-','LineWidth',0.5,'MaximumNumPoints',100*plotTimeSpan);
pressureAxes.XLim = [0 plotTimeSpan];

% Read digital events and plot
while(1)

    [~, timestamps, events] = xippmex('digin'); % timestamps based on 30 kHz clock ticks

    if ~isempty(events)
        s = double(extractfield(events,'parallel'));
        x = (timestamps-t0)/3e4;    % (s)

        addpoints(anLpressure,x,s);

        if x(end)<=plotTimeSpan
            xlim(pressureAxes,[0 plotTimeSpan]);
            addpoints(anLpressure,x,s);
        else
            if x(1)<plotTimeSpan
                idx = find(x==plotTimeSpan);
                addpoints(anLpressure,x(1:idx),s(1:idx));
                addpoints(anLpressure,x(idx+1:end),s(idx+1:end));
            else
                x_range(2) = x(end);
                x_range(1) = x_range(2)-plotTimeSpan;
                xlim(pressureAxes,x_range)
                addpoints(anLpressure,x,s);
            end
        end

    end

    pause(0.5);
end