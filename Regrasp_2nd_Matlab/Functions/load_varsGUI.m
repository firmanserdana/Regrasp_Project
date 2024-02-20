% Control parameters 
varsGUI.binDevice = 1; % 1 for Pillow, 2 for eeg
varsGUI.propDevice = 2; % 1 for 64+, 2 for MTw Awinda
varsGUI.propThr = 0.3; % between 0 and 1
varsGUI.propSat = 0.7; % between 0 and 1 (propSat > propThr)

% Calibration parameters
varsGUI.emgMVC = 1; % MVC of control muscle

% Stimulation parameters
varsGUI.modType = 1; % 1 for amp modulation, 2 for freq modulation
varsGUI.nGrasps = 3; % # total movements inserted in the GUI
varsGUI.stimCh = [5 10 15]; % vector of length nGrasps, each element can take an integer value between 1 and 64 
varsGUI.stimPW = [40 40 40]; % [us] vector of length nGrasps
varsGUI.stimAmp = [0 0 0]; % [uA] if modType==1 -> stimAmp = zeros(nGrasps,1); if modType==2 -> 
% stimAmp is a vector of length nGrasps with each element to check that
% PW(i)*stimAmp(i) < 120 nC
varsGUI.stimFreq = [50 50 50]; % [Hz] if modType==1 -> stimFreq is a vector of length nGrasps with values entered in the GUI
% if modType==2 -> stimFreq==zeros(nGrasps,1) 
varsGUI.minAmp = [100 100 100]; % [uA] if modType==1 -> minAmp is a vector of length nGrasps with each element to check that
% PW(i)*minAmp(i) < 120 nC; if modType==2 -> minAmp = zeros(nGrasps,1); 
varsGUI.maxAmp = [500 500 500]; % [uA] maxAmp(i)>minAmp(i); if modType==1 -> maxAmp is a vector of length nGrasps with each element to check that
% PW(i)*maxAmp(i) < 120 nC; if modType==2 -> maxAmp = zeros(nGrasps,1); 
varsGUI.minFreq = [0 0 0]; % [Hz] if modType==1 -> minFreq = zeros(nGrasps,1); if modType==2 -> 
% minFreq is a vector of length nGrasps with values entered in the GUI;
varsGUI.maxFreq = [0 0 0]; % [Hz] maxFreq(i)>minFreq(i); if modType==1 -> maxFreq = zeros(nGrasps,1); if modType==2 -> 
% maxFreq is a vector of length nGrasps with values entered in the GUI;

% Buttons
varsGUI.stimEN = 1; % stim enable/disable