function [plotTimeSpan, elecs, Fs_EMG, EMG_scale, read_win, buf_win, MVC_rec, raw_rec, MVC, active_stim_ch, stimStepSize, draw_stim_exists, cs, stimFreq, stimFreqMin, stimFreqMax, trainFreqRng, pulseAmp, pulseAmpSteps, phaseDur_us, fs_us, nipClock_us, nipClock_ms, msec2nip_clk, nip_clk2sec, nip_clk2msec, nip_clk2usec, AMP_NEURAL, AMP_STIM, stimAmp2V, stimAmp2uV, env_thr, env_sat, forceRange_mV] = default_init_values(txt)
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

    if strcmp(txt,'AM')
        cs = 1;          % Control strategy {'AM', 'FM'}
        stimFreq      = 50;     % stimulation Frequency (Hz)
        phaseDur_us   = 200;    % Duration of cathodic and anodic phases of stim (must be multiples of 33.3333333 for this eg.)
        fs_us         = 200;    % duration of stim fast settle of recording (us)

    elseif strcmp(txt,'FM')
        cs = 2;
        stimFreqMin   = 10;     % Minimum stimulation Frequency (Hz)
        stimFreqMax   = 100;    % Maximum stimulation Frequency (Hz)
        trainFreqRng = stimFreqMax - stimFreqMin; % range of stimulation freq.
        pulseAmp = 100;         % uA of stimulation to deliver
        pulseAmpSteps = floor(pulseAmp/stimStepSize);   % Sets the amplitude of stim (e.g. 20*stimStepSize = 100 uA)
        phaseDur_us   = 200;    % Duration of cathodic and anodic phases of stim (must be multiples of 33.3333333 for this eg.)
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
end
