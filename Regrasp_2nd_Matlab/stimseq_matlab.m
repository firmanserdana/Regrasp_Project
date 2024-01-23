% qui non uso un timer ma un while
% il rallentamento della visualizzazione è risolto, dovevo cambiare stem
% (che usavo per plottare la stimolazione) con line. fallo anche
% nell'interfaccia
%% this script acquires and processes raw emg to get env @ 80 ms (can change
% this by varying read_win), then modulates amplitude or frequency (based
% on user initial input: 'AM' or 'FM').
%% Initializations 
% Clean the world
close all; fclose('all'); clc; clear;

addpath('Regrasp_Dependency/Xippmex')

%% settings
% ---------------- plot timing ----------------
plotTimeSpan = 5;   % s
% ---------------- EMG ----------------
elecs = zeros(1,16);
Fs_EMG = 2e3;
EMG_scale = 2e3;
% Read window length (sets EMG acquisition frequency) and buffer
% window (over which to compute the RMS envelope)
read_win = 0.08;    % read window
buf_win = 0.24;     % buffer window [s]; In Knutson 0.24 s
MVC_rec = [];       % temporarily stores MVC acquisition to plot it back once
raw_rec = [];       % temporarily stores raw acquisition to plot it back once
MVC = 1;            % per ora così, poi calcolalo all'inizio del trial
% ---------------- Stim ---------------
active_stim_ch = 0;
stimStepSize   = 5;              % [µA/step], da settare prima in trellis e poi qui.. vedi se devi cambiare qualcos'altro

draw_stim_exists = 0;
%% %%%%%%%%%%%%% Soft Parameter Initialization - May change as needed %%%%%%%%%%%%%%
% [da stim_ampl_mod.m di xippmex]

txt=input('AM or FM?\n','s');
if strcmp(txt,'AM')
    cs = 1;          % Control strategy {'AM', 'FM'}
    stimFreq      = 50;     % stimulation Frequency (Hz)
    phaseDur_us   = 200;    % Duration of cathodic and anodic phases of stim (must be mulitples of 33.3333333 for this eg.)
    fs_us         = 200;    % duration of stim fast settle of recording (us)

elseif strcmp(txt,'FM')
    cs = 2;
    stimFreqMin   = 10;     % Minimum stimulation Frequency (Hz)
    stimFreqMax   = 100;    % Maximum stimulation Frequency (Hz)
    trainFreqRng = stimFreqMax - stimFreqMin; % range of stimulation freq.
    pulseAmp = 100;         % uA of stimulation to deliver
    pulseAmpSteps = floor(pulseAmp/stimStepSize);   % Sets the amplitude of stim (e.g. 20*stimStepSize = 100 uA)
    phaseDur_us   = 200;    % Duration of cathodic and anodic phases of stim (must be mulitples of 33.3333333 for this eg.)
    fs_us         = 200;    % duration of stim fast settle of recording (us)
end


%% %%%%%%%%%%%%%%%% Fixed Parameter Initialization - DO NOT CHANGE %%%%%%%%%%%%%%%%%
nipClock_us    = 1e6/3e4;           % 33.333 us
nipClock_ms    = nipClock_us * 1e3; % 0.0333 ms
msec2nip_clk   = 30;
nip_clk2sec    = 1/3e4;
nip_clk2msec   = nip_clk2sec * 1e3;
nip_clk2usec   = nip_clk2sec * 1e6;
AMP_NEURAL     = 0;              % used to set the input channel amp to measure neural voltages
AMP_STIM       = 1;              % used to set the input channel amp to measure stim voltage
stimAmp2V      = 0.50863e-3;     % capisici se ti serve e se va bene questo valore!! forse servono le lookup tables nel sito di ripple
stimAmp2uV     = stimAmp2V * 1e6;

% Specific parameters used for this example
env_thr = 300;
env_sat    = 1000;  % qui sarebbe l'MVC..
forceRange_mV  = env_sat - env_thr;

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

%% Start NIP
status = 0;
try
    status = xippmex;
    while ~status
        status = xippmex;
    end
catch
    disp(["Could not find NIP."; "Check wired connection and open Trellis app."]);
    % delete(app);
end

%% Find all Stim and Micro/Nano channels and Corresponding FE's
stimChans  = xippmex('elec','stim');
%make sure there is at least one micro+stim front end present
if isempty(stimChans); error('No stimulation hardware detected');  end

stimChans = stimChans(1);   % solo a scopo dimostrativo, scrivo il codice
% per un solo canale ma nell'app posso scegliere il canale tra quelli disponibili

% Flush stim buffer
xippmex('spike',stimChans,1);
% the buffer is emptied soon after it's read, so no need to do it manually

% Activate 'stim' data stream
% Note only stim and spike streams are managed individually
if ~isempty(stimChans)
    xippmex('signal',stimChans,'stim',ones(1,length(stimChans)));
end


%% Set EMG electrode IDs
% check if elecs is not empty, otherwise fill it by calling
% xippmex. this shows the EMG recording channels in one array.
if all(elecs==0)
    elecs = xippmex('elec','EMG');
end
% make sure there's an FE connected
if isempty(elecs); error('No EMG FE detected'); end

% qui seleziono solo il primo elettrodo, ma nell'app ho l'interfaccia per
% scegliere quanti e quali desiero
selected_elecs = elecs(1);

% Set xippmex EMG xippmex filter
xippmex('filter','set',elecs,'hires notch',5); % Notch at 50/100/150 Hz
xippmex('filter','set',elecs,'hires',6); % Band-pass 15-375 Hz

pause(0.5)  % give NIP some time to process the commands sent
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

%% %%%%%%%%%%%%% Stim Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Enable stimulation on the NIP.
% NOTE: If stimulation is not enabled, xippmex will enable and disable 
% stimulation for each stim sequence it receives. This will have the 
% undesirable side effect of killing queued stimulation sequences. Always 
% enable stimulation on the NIP before queueing multiple stimulation
% sequences.
xippmex('stim', 'enable', 0); pause(0.5)
xippmex('stim', 'enable', 1); pause(0.5)

% NOTE: This size is fixed and cannot be exceeded. Overflowing the buffer
% will cause the NIP to shut down all stimulation.
stimQueueSize = 8;

pw_cycls = floor(phaseDur_us / nipClock_us);
fs_cycls = floor(fs_us / nipClock_us);

for i = 1:length(stimChans)
    cmd(i).elec    = stimChans(i);
    if cs == 1                  % AM
        cmd(i).period  = floor(1/nip_clk2sec / stimFreq);
    elseif cs == 2              % FM
        cmd(i).period  = 1;
    end
    cmd(i).repeats = 200;
    cmd(i).action  = 'immed';  % Valid 'action' options are: ['immed', 'curcyc', 'allcyc', 'at-time']
    
    % Initialize cathodic phase of stim
    if cs == 1                  % AM
        cmd(i).seq(1) = struct('length', pw_cycls, 'ampl', 0, 'pol', 0, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);
    elseif cs == 2                  % FM
        cmd(i).seq(1) = struct('length', pw_cycls, 'ampl', pulseAmpSteps, 'pol', 0, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);
    end

    % Initialize interphase interval, i.e., time between cathodic an anodic 
    % phases of bipolar waveform. In this example, it is one clock cycle.
    cmd(i).seq(2) = struct('length', 2, 'ampl', 0, 'pol', 0, ...
        'fs', 0, 'enable', 0, 'delay', 0, 'ampSelect', AMP_STIM);

    % Initialize anodic phase of stim
    if cs == 1                  % AM
        cmd(i).seq(3) = struct('length', pw_cycls, 'ampl', 0, 'pol', 1, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);
    elseif cs == 2                  % FM
        cmd(i).seq(3) = struct('length', pw_cycls, 'ampl', pulseAmpSteps, 'pol', 1, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);
    end

    % Initialize fast settle after stimulation pulse
    if fs_cycls > 0
        cmd(i).seq(4) = struct('length', fs_cycls, 'ampl', 0, 'pol', 1, ...
            'fs', 1, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);
    end
    
    cmdClear(i).elec = stimChans(i);
    cmdClear(i).period  = 20;
    cmdClear(i).repeats = 1;
    cmdClear(i).action  = 'immed';

    cmdClear(i).seq(1) = struct('length', 3, 'ampl', 0, 'pol', 0, ...
        'fs', 0, 'enable', 0, 'delay', 0, 'ampSelect', AMP_NEURAL);
end

%% %%%%%%%%%%%%%%%% Set control parameters for stimulation %%%%%%%%%%%
lastNipTime  = 0;
nipOffTime   = 0;
stimOff      = 0;

%% container for accumulating effective loop periods
time_passed = [];

%% %%%%%%%%%%%%%% Run Control Loop %%%%%%%%%%%%%%%%%%%%%%%%
while ishandle(h)
        start_meas = tic;
        % -----------------------------------------------------------------
        % -------------------- Check if NIP is online ---------------------
        % -----------------------------------------------------------------
        % take time soon after entering the cycle, for pause command
        % at end of loop.
        comp_time = tic;

        % Get the current NIP time
        curNipTime = xippmex('time');

        % check if clock time is equal to previous cycle
        if curNipTime == lastNipTime
            if nipOffTime == 0
                tic;
            end
            nipOffTime = toc;
            % if the nip has been offline for a second ABORT the program
            if nipOffTime > 1
                xippmex('close');
                error('NIP appears to be off-line. Exiting program... Bye!')
            end
            % if the NIP is on-line clear the off timer
        else
            nipOffTime = 0;
        end
        % update NIP time for the next pass through the loop
        lastNipTime = curNipTime;
        % -----------------------------------------------------------------
        % -------------------------- Read EMG -----------------------------
        % -----------------------------------------------------------------
        if ~isempty(selected_elecs)
            try
                % tic_start = tic;
                
                [EMG, timestamps] = xippmex('cont',selected_elecs,read_win*1000,'hi-res');
                
                timestamp = double(timestamps);

                % Deal with packet loss
                EMG(find(EMG<-1000)) = 0; % packet loss

                % write EMG data into buffer
                write(bufdata,EMG');

                % read data from buffer without changing no. unread samples (peek)
                % (window over which to compute the rms)
                pointData = peek(bufdata);

                % compute rms envelope
                env = rms(pointData);
                
                % Compute MVC
% % %                 if strcmp(app.MVC_list.CheckedNodes.Text,'Compute new MVC')
% % %                     % save env sample into MVC_rec for plotting
% % %                     % purpose at end of MVC acquisition
% % %                     app.MVC_rec = [app.MVC_rec, env];
% % %                     app.raw_rec = [app.raw_rec, data];
% % %                     if env>app.curr_MVC
% % %                         app.curr_MVC = env;
% % %                     end
% % %                     % Save the data into the txt file, with
% % %                     % timestamp vector
% % %                     writematrix([timestamps(end) env],new_file_MVC,'WriteMode','append');
% % %                     % display MVC being computed
% % %                     txt = sprintf('MVC: %.2f',app.curr_MVC);
% % %                     app.Disp.Value = txt;
% % %                 else    % controlling VR hand
                    % Normalize env and raw data wrt MVC
                    data = EMG./MVC;
                    env = env/MVC;

                    % -----------------------------------------------------
                    % --------------------- AM / FM -----------------------
                    % -----------------------------------------------------
                    % if the control threshold has been crossed, modulate the
                    % amplitude or the frequency of stimulation.
                    % if the control is below threshold, shut off stimulation
                    if env > env_thr
                        stimOff    = 0;
                        forceDiff  = env - env_thr;
                        if cs == 1      % AM
                            ampRngFrac = min(forceDiff/forceRange_mV, 1);
                            for i = 1:length(stimChans)
                                % qui aggiungi un if per capire se è AM o FM
                                % (in questo caso, cambia cmd(i).seq(1).period)
                                cmd(i).seq(1).ampl = floor (127 * ampRngFrac);
                                cmd(i).seq(3).ampl = floor (127 * ampRngFrac);
                            end
                        elseif cs == 2  % FM
                            frqRngFrac = min(forceDiff/forceRange_mV, 1);
                            frq        = stimFreqMin + trainFreqRng * frqRngFrac;
                            for i = 1:length(stimChans)
                                cmd(i).period = floor(1000/frq * msec2nip_clk); % can't have fractional cycle
                            end
                        end
                        xippmex('stimseq', cmd);
                        active_stim_ch = stimChans;
                    else
                        if ~stimOff
                            xippmex('stimseq', cmdClear);
                            stimOff = 1;
                        end
                        % continue
                    end
% 
%                     % Save the data into the txt files
%                     writematrix([timestamps data'],new_file_EMGraw,'WriteMode','append');
%                     writematrix([timestamps(end) env],new_file_EMGenv,'WriteMode','append');
% % %                 end

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


