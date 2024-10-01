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

%% Initialize plots
% -----------------------EMG-----------------------------
for ch = 1:length(selected_elecs)
    an_EMG{ch} = animatedline(EMG_Axes,'LineStyle','-','LineWidth',0.2,'MaximumNumPoints',round(Fs_EMG*(plotTimeSpan+1)));
    an_EMG_env{ch} = animatedline(EMG_Axes,'LineStyle','-','Color','b','LineWidth',2,'MaximumNumPoints',round(Fs_EMG*(plotTimeSpan+1)));
end
% Draw threshold and MVC
line(EMG_Axes,0:plotTimeSpan,env_thr*ones(1,plotTimeSpan+1),'Color','r','linewidth',1);
line(EMG_Axes,0:plotTimeSpan,env_sat*ones(1,plotTimeSpan+1),'Color','b','linewidth',1);

EMG_Axes.XLim = [0 plotTimeSpan];
% % % % % % EMG_Axes.YLim = [0 EMG_scale*(length(selected_elecs)+1)/EMG_scale];
EMG_CH_rows = 1:length(selected_elecs);
% EMG_Axes.YTick = EMG_CH_rows;
% EMG_Axes.YTickLabel = num2cell(selected_elecs-(elecs(1)-1));

% -----------------------Stimulation----------------------
an_stimulation = animatedline(Stim_Axes,'LineStyle','-','LineWidth',0.5,'MaximumNumPoints',100*plotTimeSpan);
line(Stim_Axes,0:plotTimeSpan,zeros(1,plotTimeSpan+1),'Color','k','linewidth',0.5);
% ------------------------------------------------------
% additional figure to stack stimulation being executed
%------------------------------------------------------
showWaveforms = input('\nDo you want to see the delivered waveforms stacked to check them?\n[0 - no / 1 - yes]\n','s');
if strcmp(showWaveforms,'1')
    waves = figure;
    waves_ax = axes;
    hold(waves_ax,'on');
    xlabel(waves_ax,'Clock time [33.3µs]','FontSize',12)
    ylabel(waves_ax,'Amplitude [V]','FontSize',12)
    waves_ax.FontWeight = 'bold';
end

%% Define buffer for EMG
bufdata = dsp.AsyncBuffer(buf_win*Fs_EMG); % buffer

%% Get NIP clock time right before turning streams on (30 kHz sampling)
t0 = xippmex('time');
% t0_clk = xippmex('time');

                % ---------------------------------------------------------
                % ---------------- Plot raw EMG and envelope --------------
                % ---------------------------------------------------------
                x = timestamp:3e4/2e3:(timestamp+read_win*3e4-1);
                x_s  = (x-t0)/3e4;
%                 x_env_s = x_s(1:buf_win/read_win:end); non necessario
                if x_s(end)<=plotTimeSpan
                    xlim(EMG_Axes,[0 plotTimeSpan]);
                    for ch = 1:size(data,1)
                        addpoints(an_EMG{ch},x_s,data(ch,:)); % +EMG_CH_rows(ch));
                        addpoints(an_EMG_env{ch},x_s,env*ones(length(x_s),1)); % +EMG_CH_rows(ch));
                    end
                else
                    if x_s(1)<plotTimeSpan
                        idx = find(x_s==plotTimeSpan);
%                         idx_env = round(idx/(buf_win/read_win));
                        for ch = 1:size(data,1)
                            addpoints(an_EMG{ch},x_s(1:idx),data(ch,1:idx)); % +EMG_CH_rows(ch));
                            addpoints(an_EMG_env{ch},x_s(1:idx),env*ones(length(x_s(1:idx)),1)); % +EMG_CH_rows(ch));
                        end
                        for ch = 1:size(data,1)
                            addpoints(an_EMG{ch},x_s(idx+1:end),data(ch,idx+1:end)); % +EMG_CH_rows(ch));
                            addpoints(an_EMG_env{ch},x_s(idx+1:end),env*ones(length(x_s(idx+1:end)),1)); % +EMG_CH_rows(ch));
                        end
                        line(EMG_Axes,x_s(1:idx),env_thr*ones(1,length(x_s(1:idx))),'Color','r','linewidth',1);
                        line(EMG_Axes,x_s(idx+1:end),env_sat*ones(1,length(x_s(idx+1:end))),'Color','b','linewidth',1);
                        line(Stim_Axes,EMG_Axes.XLim(1):plotTimeSpan,zeros(1,length(EMG_Axes.XLim(1):EMG_Axes.XLim(2))),'Color','k','linewidth',0.5);
                    else
                        x_range(2) = x_s(end);
                        x_range(1) = x_range(2)-plotTimeSpan;
                        xlim(EMG_Axes,x_range)
                        line(EMG_Axes,x_range(1):x_range(2),env_thr*ones(1,length(x_range(1):x_range(2))),'Color','r','linewidth',1);
                        line(EMG_Axes,x_range(1):x_range(2),env_sat*ones(1,length(x_range(1):x_range(2))),'Color','b','linewidth',1);
                        line(Stim_Axes,x_range(1):x_range(2),zeros(1,length(x_range(1):x_range(2))),'Color','k','linewidth',0.5);
                        try
                            for ch = 1:size(data,1)
                                addpoints(an_EMG{ch},x_s,data(ch,:)); % +EMG_CH_rows(ch));
                                addpoints(an_EMG_env{ch},x_s,env*ones(length(x_s),1)); % +EMG_CH_rows(ch));
                            end
                        catch
                            for ch = 1:size(data,1)-1
                                addpoints(an_EMG{ch},x_s,data(ch,:)); % +EMG_CH_rows(ch));
                                addpoints(an_EMG_env{ch},x_s,env*ones(length(x_s),1)); % +EMG_CH_rows(ch));
                            end
                            disp(['Index exceeds the number of array elements.\n' ...
                                'This may happen when updating which EMG channel to ' ...
                                'stream, since checkbox may be ticked while timer is' ...
                                ' already updating EMG lines with previous set of channels!'])
                        end
                    end
                end
                clearvars x x_s
                
                % ---------------------------------------------------------
                % --------------- Plot stimulation timestamps -------------
                % ---------------------------------------------------------
                % if a channel is stimulating, this serves to go read the buffer
                % and plot timestamps
                if active_stim_ch ~= 0
                    try
                        [stimCount, stimTimestamps, waveforms] = xippmex('spike', active_stim_ch, 1);
                        if stimCount
                            n_checks_stim_data = 0;
                            x = (stimTimestamps{1}-t0)/3e4;
                            if cs == 1      % AM
                                k = 127*ampRngFrac;
                            elseif cs == 2  % FM
                                k = 127*pulseAmpSteps;
                            end
                            % this is to get the actual voltage of the
                            % waves
%                             k = max(abs(waveforms{1,1}(1,:)));

                            if x(end)<=plotTimeSpan
                                line(Stim_Axes,repelem(x,2),repmat([-1 1]*floor(k),1,stimCount));

                            else
                                if x(1) >= plotTimeSpan   % questo caso si può forse evitare
                                    line(Stim_Axes,repelem(x,2), repmat([-1 1]*floor(k),1,stimCount));
                                else
                                    idx = find(x==plotTimeSpan);
                                    line(Stim_Axes,repelem(x(1:idx),2), repmat([-1 1]*floor(k),1,idx));
                                    line(Stim_Axes,repelem(x(idx+1:end),2), repmat([-1 1]*floor(k),1,stimCount-idx));
                                end
                            end
                            % voglio usare questo per controllare se è
                            % passato plotTimeSpan (s) dall'ultimo bunch di
                            % tick rappresnetati, in quel caso uso cla per
                            % resettare l'asse
                            drawn_stim = tic; draw_stim_exists = 1;
                            % ---------------------------------------------
                            % ---------------plot waveforms----------------
                            % plot waveforms to visually check them.. not
                            % needed for realtime experimental purposes
                            % comment if you don't want this
                            if strcmp(showWaveforms,'1')
                                for i = 1:size(waveforms{1,1},1)
                                    plot(waves_ax,waveforms{1,1}(i,:))
                                end
                            end
                            % ---------------------------------------------
                            % ---------------------------------------------
                        else
                            start_check_stim = tic;
                            if toc(start_check_stim)>plotTimeSpan
                                % put down active_stim_ch flag, so that timer doesn't lose
                                % time checking if there's stim data stream to show
                                active_stim_ch = 0;
                                % clear plot to save memory
                                clearpoints(an_stimulation)
                            end
                        end
                        % per il reset forzato di stim_axes, magari è
                        % sbagliato e domani devi sistemarmi :)
                        if draw_stim_exists && (toc(drawn_stim) > plotTimeSpan)
                            clearpoints(an_stimulation)
                        end
                    catch
                        disp('Issue in streaming Stim data')
                    end
                end
                

                % Wait for "readwin" seconds at the end of the loop
                pause(read_win-toc(comp_time));

            catch
                disp('Issue in streaming EMG data')
            end
        end
        % stop execution if too much lag
%         if toc(start_meas) > 0.82
%             error('too much delay in control loop, check timing')
%         end
        time_passed = [time_passed toc(start_meas)];
        
end

%% Diagnostics for loop duration
% plot(time_passed);
% xlabel('iterations','FontSize',12);
% ylabel('Control loop duration','FontSize',12);
% ylim([0 max(time_passed)])
% yline(0.08,'--r');

% dbstop if caught error

%% To display the waveforms
% waves = figure;
% hold(waves,'on');
% for i = 1:size(waveforms{1,1},1)
%     plot(waves,waveforms{1,1}(i,:))
% end
% xlabel(waves,'Clock time [µs]','FontSize',12)
% ylabel(waves,'Amplitude [V]','FontSize',12)


