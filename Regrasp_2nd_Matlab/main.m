close all; fclose('all'); clc; clear;

try

    addpath(genpath('/home/firep1/Documents/gitworks/phd/ReWire/Rewire_Project/Regrasp_2nd_Matlab/Regrasp_Dependency'))
catch
    disp('Download Xippmex and add it to the path (Regrasp_Dependency/Xippmex) to use the Xippmex functions')
end

addpath('Functions')

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

% % Initialization
FSAMP = 2;      % if MODE != 3: 0 = 500 Hz,  1 = 1000 Hz, 2 = 2000 Hz
                 % if MODE == 3: 0 = 2000 Hz, 1 = 4000 Hz, 2 = 8000 Hz
 NCH  = 3;       % 0 = 8 channels, 1 = 16 channels, 2 = 32 channels, 3 = 64 channels
 MODE = 0;       % 0 = Monopolar, 1 = Bipolar, 2 = Differential, 3 = Accelerometers, 6 = Impedance check, 7 = Test Mode
 HRES = 0;       % 0 = 16 bits, 1 = 24 bits
 HPF  = 1;       % 0 = DC coupled, 1 = High pass filter active
 EXTEN = 0;      % 0 = standard input range, 1 = double range, 2 = range x 4, 3 = range x 8
 TRIG = 0;       % 0 = Data transfer and REC on SD controlled remotely, 3 = REC on SD controlled from the pushbutton
 REC  = 0;       % 0 = Stop data recording on SD card, 1 = start data recording on SD card
 GO   = 1;       % 0 = just send the settings, 1 = send settings and start the data transfer

 NumCycle = 10;

% % Conversion factor for the bioelectrical signals to get the values in mV
 ConvFact = 0.000286;

% % -------------------------------------------------------------------------
% % Create the command to send to Sessantaquattro
 Command = 0;
 Command = Command + GO;
 Command = Command + REC * 2;
 Command = Command + TRIG * 4;
 Command = Command + EXTEN * 16;
 Command = Command + HPF * 64;
 Command = Command + HRES * 128;
 Command = Command + MODE * 256;
 Command = Command + NCH * 2048;
 Command = Command + FSAMP * 8192;

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

    
        cs = 1;          % Control strategy {'AM', 'FM'}
        stimFreq      = 50;     % stimulation Frequency (Hz)
        phaseDur_us   = 200;    % Duration of cathodic and anodic phases of stim (must be multiples of 33.3333333 for this eg.)
        fs_us         = 200;    % duration of stim fast settle of recording (us)

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
    bufdata = dsp.AsyncBuffer(buf_win*Fs_EMG); % buffer

% % Conversion from decimal integer to its binary representation
 dec2bin(Command)

sessantaquattroplus_handler.createCommand(FSAMP, NCH, MODE, HRES, HPF, EXTEN, TRIG, REC, GO);
sessantaquattroplus_handler.getNumChannels(NCH, MODE);
sessantaquattroplus_handler.getSamplingFrequency(FSAMP, MODE);
t = sessantaquattroplus_handler.openSocket();
fwrite(t, Command, 'int16');
xippmex_handler.setupStimulation();
xippmex_handler.initializeStimulation(stimChans, cs, phaseDur_us, fs_us, stimFreq, pulseAmpSteps);

while true
    data = sessantaquattroplus_handler().receiveData(t, NumChan, sampFreq, HRES);
    stimulationsignals = xippmex_handler().runStimulationLoop(data, h, bufdata, selected_elecs, read_win, stimChans, cs, env_thr, forceRange_mV, MVC, nipClock_us, msec2nip_clk, AMP_STIM, cmd, cmdClear);
    % plot later
end

