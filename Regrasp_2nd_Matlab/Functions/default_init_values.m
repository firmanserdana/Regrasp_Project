function [vars] = default_init_values(txt)
    %%%%% Grapevine settings
    % ---------------- plot timing ----------------
    vars.plotTimeSpan = 5;   % s
    
    % ---------------- EMG ----------------
    vars.elecs = zeros(1,16);
    vars.Fs_EMG = 2e3;
    vars.EMG_scale = 2e3;
    
    % Read window length (sets EMG acquisition frequency) and buffer
    % window (over which to compute the RMS envelope)
    vars.read_win = 0.08;    % read window
    vars.buf_win = 0.24;     % buffer window [s]; In Knutson 0.24 s
    vars.MVC_rec = [];       % temporarily stores MVC acquisition to plot it back once
    vars.raw_rec = [];       % temporarily stores raw acquisition to plot it back once
    vars.MVC = 1;            % per ora così, poi calcolalo all'inizio del trial
    
    % ---------------- Stim ---------------
    vars.active_stim_ch = 0;
    vars.stimStepSize   = 5;              % [µA/step], da settare prima in trellis e poi qui.. vedi se devi cambiare qualcos'altro
    vars.draw_stim_exists = 0;
    
    if strcmp(txt,'AM')
        vars.cs = 1;          % Control strategy {'AM', 'FM'}
        vars.stimFreq      = 50;     % stimulation Frequency (Hz)
        vars.phaseDur_us   = 200;    % Duration of cathodic and anodic phases of stim (must be multiples of 33.3333333 for this eg.)
        vars.fs_us         = 200;    % duration of stim fast settle of recording (us)
    elseif strcmp(txt,'FM')
        vars.cs = 2;
        vars.phaseDur_us   = 200;    % Duration of cathodic and anodic phases of stim (must be multiples of 33.3333333 for this eg.)
        vars.fs_us         = 200;    % duration of stim fast settle of recording (us)
    end
    vars.stimFreqMin   = 10;     % Minimum stimulation Frequency (Hz)
        vars.stimFreqMax   = 100;    % Maximum stimulation Frequency (Hz)
        vars.trainFreqRng = vars.stimFreqMax - vars.stimFreqMin; % range of stimulation freq.
        vars.pulseAmp = 100;         % uA of stimulation to deliver
        vars.pulseAmpSteps = floor(vars.pulseAmp/vars.stimStepSize);   % Sets the amplitude of stim (e.g. 20*stimStepSize = 100 uA)
        
    %% %%%%%%%%%%%%%%%% Fixed Parameter Initialization - DO NOT CHANGE %%%%%%%%%%%%%%%%%
    vars.nipClock_us    = 1e6/3e4;           % 33.333 us
    vars.nipClock_ms    = vars.nipClock_us * 1e3; % 0.0333 ms
    vars.msec2nip_clk   = 30;
    vars.nip_clk2sec    = 1/3e4;
    vars.nip_clk2msec   = vars.nip_clk2sec * 1e3;
    vars.nip_clk2usec   = vars.nip_clk2sec * 1e6;
    vars.AMP_NEURAL     = 0;              % used to set the input channel amp to measure neural voltages
    vars.AMP_STIM       = 1;              % used to set the input channel amp to measure stim voltage
    vars.stimAmp2V      = 0.50863e-3;     % capisici se ti serve e se va bene questo valore!! forse servono le lookup tables nel sito di ripple
    vars.stimAmp2uV     = vars.stimAmp2V * 1e6;
    
    % Specific parameters used for this example
    vars.env_thr = 300;
    vars.env_sat    = 1000;  % qui sarebbe l'MVC..
    vars.forceRange_mV  = vars.env_sat - vars.env_thr;

    %% Find all Stim and Micro/Nano channels and Corresponding FE's
vars.stimChans  = xippmex('elec','stim');
%make sure there is at least one micro+stim front end present
if isempty(vars.stimChans); error('No stimulation hardware detected');  end

vars.stimChans = vars.stimChans(1);   % solo a scopo dimostrativo, scrivo il codice
% per un solo canale ma nell'app posso scegliere il canale tra quelli disponibili

% Flush stim buffer
xippmex('spike',vars.stimChans,1);
% the buffer is emptied soon after it's read, so no need to do it manually

% Activate 'stim' data stream
% Note only stim and spike streams are managed individually
if ~isempty(vars.stimChans)
    xippmex('signal',vars.stimChans,'stim',ones(1,length(vars.stimChans)));
end

    
    %%%%% SessantaQuattro Settings
    % Initialization
    vars.FSAMP = 2;      % if MODE != 3: 0 = 500 Hz,  1 = 1000 Hz, 2 = 2000 Hz
    % if MODE == 3: 0 = 2000 Hz, 1 = 4000 Hz, 2 = 8000 Hz
    vars.NCH  = 0;       % 0 = 8 channels, 1 = 16 channels, 2 = 32 channels, 3 = 64 channels
    vars.MODE = 1;       % 0 = Monopolar, 1 = Bipolar, 2 = Differential, 3 = Accelerometers, 6 = Impedance check, 7 = Test Mode
    vars.HRES = 1;       % 0 = 16 bits, 1 = 24 bits
    vars.HPF  = 1;       % 0 = DC coupled, 1 = High pass filter active
    vars.EXTEN = 0;      % 0 = standard input range, 1 = double range, 2 = range x 4, 3 = range x 8
    vars.TRIG = 0;       % 0 = Data transfer and REC on SD controlled remotely, 3 = REC on SD controlled from the pushbutton
    vars.REC  = 0;       % 0 = Stop data recording on SD card, 1 = start data recording on SD card
    vars.GO   = 1;       % 0 = just send the settings, 1 = send settings and start the data transfer
    
    vars.NumCycle = 10;
    
    % Conversion factor for the bioelectrical signals to get the values in mV
    vars.ConvFact = 0.000286;
    
    % -------------------------------------------------------------------------
    % Create the command to send to Sessantaquattro
    vars.Command = 0;
    vars.Command = vars.Command + vars.GO;
    vars.Command = vars.Command + vars.REC * 2;
    vars.Command = vars.Command + vars.TRIG * 4;
    vars.Command = vars.Command + vars.EXTEN * 16;
    vars.Command = vars.Command + vars.HPF * 64;
    vars.Command = vars.Command + vars.HRES * 128;
    vars.Command = vars.Command + vars.MODE * 256;
    vars.Command = vars.Command + vars.NCH * 2048;
    vars.Command = vars.Command + vars.FSAMP * 8192;

     % Processing
     vars.chX = 1; % EMG control channel
     vars.readWind = 0.08; % read window [s]
     vars.bufWind = 0.24; % buffer window [s];

    % Conversion from decimal integer to its binary representation
    dec2bin(vars.Command)

    % -------------------------------------------------------------------------
end
