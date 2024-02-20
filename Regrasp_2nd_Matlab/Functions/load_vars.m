% -------------------------- Fixed parameters -----------------------------

% SAFETY LIMIT
vars.safeLimit = 0.12; % [pC]

% NIP parameters
vars.nipClock_us = 1e6/3e4; % 33.333 us
vars.msec2nip_clk   = 30;
vars.AMP_STIM = 1; % used to set the input channel amp to measure stim voltage
vars.baseFreq = 1; % [Hz] baseline frequency (we set it at 1 Hz)
vars.action = 'immed'; % The command will be processed as soon as the NIP receives it
vars.fs_us = 200;    % duration of stim fast settle of recording (us)
vars.ampStepSize = 7.5; % [uA]

% 64+ parameters 
vars.FSAMP = 2;      % if MODE != 3: 0 = 500 Hz,  1 = 1000 Hz, 2 = 2000 Hz
                % if MODE == 3: 0 = 2000 Hz, 1 = 4000 Hz, 2 = 8000 Hz
vars.NCH  = 0;       % 0 = 8 channels, 1 = 16 channels, 2 = 32 channels, 3 = 64 channels
vars.MODE = 1;       % 0 = Monopolar, 1 = Bipolar, 2 = Differential, 3 = Accelerometers, 6 = Impedance check, 7 = Test Mode
vars.HRES = 0;       % 0 = 16 bits, 1 = 24 bits
vars.HPF  = 1;       % 0 = DC coupled, 1 = High pass filter active
vars.EXTEN = 0;      % 0 = standard input range, 1 = double range, 2 = range x 4, 3 = range x 8
vars.TRIG = 0;       % 0 = Data transfer controlled remotely, 3 = REC on SD controlled from the pushbutton or remotely
vars.REC  = 0;       % 0 = stop data recording on SD card, 1 = start data recording on SD card
vars.GO   = 1;       % 0 = just send the settings, 1 = send settings and start the data transfer
vars.ConvFact = 0.000286; % Conversion factor for the bioelectrical signals to get the values in mV

% EMG processing parameters
vars.EMGchC = 1; % selected EMG control channel
vars.readWind = 0.08; % [s]
vars.bufWind = 0.24; % [s]
[vars.bNotch,vars.aNotch] = butter(3,[49 51]/(vars.FSAMP*1000),'stop');
[vars.bBandPass,vars.aBandPass] = butter(3,[10 500]/(vars.FSAMP*1000),'bandpass');


% Plot 
vars.plotTimeSpan = 5; % [s]