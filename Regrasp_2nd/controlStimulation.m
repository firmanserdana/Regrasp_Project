function controlStimulation(env, env_thr, forceRange_mV, cs, stimChans)
    % Settings
    stimFreqMin = 10;
    stimFreqMax = 100;
    trainFreqRng = stimFreqMax - stimFreqMin;
    pulseAmp = 100;
    stimStepSize = 0.1;
    pulseAmpSteps = floor(pulseAmp / stimStepSize);

    % Stimulation parameters
    phaseDur_us = 200;
    nipClock_us = 25;
    fs_us = 100;
    msec2nip_clk = 1000 / nipClock_us;
    pw_cycls = floor(phaseDur_us / nipClock_us);
    fs_cycls = floor(fs_us / nipClock_us);

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
    %xippmex('stim', 'enable', 0); pause(0.5)
    %xippmex('stim', 'enable', 1); pause(0.5)

    % Send stimulation sequence
    %xippmex('stimseq', cmd);
end
