function recruitment_curves_display_v0(ax,amp_min,amp_max,amp_step,freq,reps)

% ax:         axes
% amp_min:    min amp for the RC [uA]
% amp_max:    max amp for the RC [uA]
% amp_step:   amp step for the RC [uA]
% freq:       frequency of the pulses [Hz]
% reps:       no. pulses with same amp


% Plot
set(ax,'Color','k')
% yticks(an,'');
hold(ax,'on');
time = 0;
cc = 0;
for amp = amp_min:amp_step:amp_max
    for pulse = 1:reps
        time = time + 1/freq*cc;
        cc = cc + 1;
        % plot
        line(ax,[time time],[-amp +amp],'linewidth',3,'color','w');
    end
end

ax.XLabel.String = 'Time [s]';
ax.XLabel.FontSize = 12;

ylim(ax,[-amp_max,+amp_max]);
xlim(ax,[0,time]);

ax.XTick = 0:1/freq:time;
ax.XTickLabel = num2str(0:1/freq:time);

yline(ax,0,'Color','w')
xline(ax,0,'color','g','LineWidth',1)
