function controlStimulation(env, env_thr, forceRange_mV, cs, stimChans)
    % Settings
    stimFreqMin = 10;
    stimFreqMax = 100;
    trainFreqRng = stimFreqMax - stimFreqMin;
    pulseAmp = 100;
    pulseAmpSteps = floor(pulseAmp / stimStepSize);

    % Stimulation parameters
    pw_cycls = floor(phaseDur_us / nipClock_us);
    fs_cycls = floor(fs_us / nipClock_us);

    % Loop through stimulation channels
    for i = 1:length(stimChans)
        cmd(i).elec = stimChans(i);
        cmd(i).period = 1;
        cmd(i).repeats = 200;
        cmd(i).action = 'immed';

        % Initialize cathodic phase of stim
        cmd(i).seq(1) = struct('length', pw_cycls, 'ampl', 0, 'pol', 0, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);

        % Initialize interphase interval
        cmd(i).seq(2) = struct('length', 2, 'ampl', 0, 'pol', 0, ...
            'fs', 0, 'enable', 0, 'delay', 0, 'ampSelect', AMP_STIM);

        % Initialize anodic phase of stim
        cmd(i).seq(3) = struct('length', pw_cycls, 'ampl', 0, 'pol', 1, ...
            'fs', 0, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);

        % Initialize fast settle after stimulation pulse
        if fs_cycls > 0
            cmd(i).seq(4) = struct('length', fs_cycls, 'ampl', 0, 'pol', 1, ...
                'fs', 1, 'enable', 1, 'delay', 0, 'ampSelect', AMP_STIM);
        end

        % Set stimulation parameters based on control strategy
        if cs == 1 % AM
            cmd(i).seq(1).ampl = floor(127 * (env - env_thr) / forceRange_mV);
            cmd(i).seq(3).ampl = floor(127 * (env - env_thr) / forceRange_mV);
        elseif cs == 2 % FM
            frqRngFrac = min((env - env_thr) / forceRange_mV, 1);
            frq = stimFreqMin + trainFreqRng * frqRngFrac;
            cmd(i).period = floor(1000 / frq * msec2nip_clk);
        end
    end

    % Enable stimulation on the NIP
    xippmex('stim', 'enable', 0); pause(0.5)
    xippmex('stim', 'enable', 1); pause(0.5)

    % Send stimulation sequence
    xippmex('stimseq', cmd);
end
