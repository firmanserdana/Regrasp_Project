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
