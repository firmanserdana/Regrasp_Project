function statusNIP()
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
    % END: ed8c6549bwf9
end

function setupStimulation()
    %% Find all Stim and Micro/Nano channels and Corresponding FE's
    stimChans  = xippmex('elec','stim');
    %make sure there is at least one micro+stim front end present
    if isempty(stimChans)
        error('No stimulation hardware detected');
    end

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

    pause(0.5)  % give NIP some time to process the commands sent
end

function initializeStimulation(stimChans, cs, phaseDur_us, fs_us, stimFreq, pulseAmpSteps)
    % Enable stimulation on the NIP.
    % NOTE: If stimulation is not enabled, xippmex will enable and disable 
    % stimulation for each stim sequence it receives. This will have the 
    % undesirable side effect of killing queued stimulation sequences. Always 
    % enable stimulation on the NIP before queueing multiple stimulation
    % sequences.
    xippmex('stim', 'enable', 0); 
    pause(0.5)
    xippmex('stim', 'enable', 1); 
    pause(0.5)

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

    % ... (Rest of your code)
    
    % Additional parameters you might need
    lastNipTime  = 0;
    nipOffTime   = 0;
    stimOff      = 0;
    
    % Container for accumulating effective loop periods
    time_passed = [];
end


function runStimulationLoop(h, bufdata, selected_elecs, read_win, stimChans, cs, env_thr, forceRange_mV, MVC, nipClock_us, msec2nip_clk, AMP_STIM, cmd, cmdClear)
    % Initialize variables
    lastNipTime  = 0;
    nipOffTime   = 0;
    stimOff      = 0;
    active_stim_ch = [];

    while ishandle(h)
        start_meas = tic;

        % Check if NIP is online
        comp_time = tic;
        curNipTime = xippmex('time');

        % Check if clock time is equal to the previous cycle
        if curNipTime == lastNipTime
            if nipOffTime == 0
                tic;
            end
            nipOffTime = toc;
            % If the NIP has been offline for a second, abort the program
            if nipOffTime > 1
                xippmex('close');
                error('NIP appears to be off-line. Exiting program... Bye!')
            end
        else
            nipOffTime = 0;
        end
        lastNipTime = curNipTime;

        % Read EMG data
        if ~isempty(selected_elecs)
            try
                [EMG, timestamps] = xippmex('cont', selected_elecs, read_win * 1000, 'hi-res');
                timestamp = double(timestamps);
                EMG(find(EMG<-1000)) = 0; % Handle packet loss

                % Write EMG data into buffer
                write(bufdata, EMG');

                % Read data from buffer without changing the number of unread samples (peek)
                pointData = peek(bufdata);

                % Compute rms envelope
                env = rms(pointData);

                % Normalize env and raw data with respect to MVC
                data = EMG ./ MVC;
                env = env / MVC;

                % Adjust stimulation based on control threshold
                if env > env_thr
                    stimOff    = 0;
                    forceDiff  = env - env_thr;
                    if cs == 1      % AM
                        ampRngFrac = min(forceDiff / forceRange_mV, 1);
                        for i = 1:length(stimChans)
                            cmd(i).seq(1).ampl = floor(127 * ampRngFrac);
                            cmd(i).seq(3).ampl = floor(127 * ampRngFrac);
                        end
                    elseif cs == 2  % FM
                        frqRngFrac = min(forceDiff / forceRange_mV, 1);
                        frq = stimFreqMin + trainFreqRng * frqRngFrac;
                        for i = 1:length(stimChans)
                            cmd(i).period = floor(1000 / frq * msec2nip_clk);
                        end
                    end
                    xippmex('stimseq', cmd);
                    active_stim_ch = stimChans;
                else
                    if ~stimOff
                        xippmex('stimseq', cmdClear);
                        stimOff = 1;
                    end
                end

                % Additional processing or data saving can be added here

            catch
                disp('Error reading EMG data.');
            end
        end

        % Your additional code or processing can be added here

        % Measure the time passed in the loop
        elapsed_time = toc(start_meas);
        time_passed = [time_passed, elapsed_time];

        % Optional: Pause to control loop rate
        % You can adjust the pause duration based on the desired loop rate
        pause(0.01);
    end
end

