%% define axes for representing data
h = figure;
tiledlayout(5,1)
% EMG
EMG_Axes = nexttile(3,[2,1]);
hold(EMG_Axes,'on');
title(EMG_Axes, 'EMG CH');
EMG_Axes.FontWeight = 'bold';
EMG_Axes.YLim = [-1000 1000];
EMG_Axes.XTick = [];
EMG_Axes.YTick = [0,env_thr,env_sat];
EMG_Axes.YTickLabel = {'0','prop_thr','prop_sat'};
EMG_Axes.TickLabelInterpreter = 'none';
EMG_Axes.YTickLabelRotation = 30;
EMG_Axes.FontSize = 15;
% IMU
IMU_Axes = nexttile(1,[2,1]);
ylabel(IMU_Axes, 'IMU');
IMU_Axes.FontWeight = 'bold';
IMU_Axes.YLim = [2000 20000];
IMU_Axes.XTick = [];
IMU_Axes.YTick = [];
IMU_Axes.FontSize = 15;
% Stim
Stim_Axes = nexttile(5,[1,1]);
ylabel(Stim_Axes, 'Stim');
Stim_Axes.FontWeight = 'bold';
Stim_Axes.YLim = [-1 1]*127;    % adimensionale, moltiplicalo per lo step size per avere [µA]??
Stim_Axes.XTick = [];
Stim_Axes.YTick = []; %[-1 1]*127;
Stim_Axes.FontSize = 15;

%%  constrain xlim for Streaming Tab axes
EMG_Axes.XLim = [0 plotTimeSpan];
% set ylim for EMG axes (will have to update them runtime)
% % % % % % EMG_Axes.YLim = [0 1];
% set xlim for Stim_Axes
Stim_Axes.XLim = [0 plotTimeSpan];
% Stim_Axes.YLim = [-30,30];
hold(Stim_Axes,'on');
% tie EMG and Stim_axes to update stim axis such that it's
% synchronised with EMG
linkaxes([EMG_Axes, Stim_Axes],'x');