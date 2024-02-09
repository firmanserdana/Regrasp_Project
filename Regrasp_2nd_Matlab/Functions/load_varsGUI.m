% Control parameters 
vars_GUI.binDevice = 1; % 1 for Pillow, 2 for eeg
vars_GUI.propDevice = 1; % 1 for 64+, 2 for MTw Awinda
vars_GUI.propThr = 0.3; % between 0 and 1
vars_GUI.propSat = 0.7; % between 0 and 1 (propSat > propThr)

% Calibration parameters
vars_GUI.emgMVC = 1; % MVC of control muscle

% Stimulation parameters
vars_GUI.modType = 1; % 1 for amp modulation, 2 for freq modulation
vars_GUI.nGrasps = 3; % # total movements inserted in the GUI
vars_GUI.stimCh = [5 10 15]; % vector of length nGrasps, each element can take an integer value between 1 and 64 
vars_GUI.stimPW = [40 40 40]; % [us] vector of length nGrasps
vars_GUI.stimAmp = [0 0 0]; % [uA] if modType==1 -> stimAmp = zeros(nGrasps,1); if modType==2 -> 
% stimAmp is a vector of length nGrasps with each element to check that
% PW(i)*stimAmp(i) < 120 nC
vars_GUI.stimFreq = [50 50 50]; % [Hz] if modType==1 -> stimFreq is a vector of length nGrasps with values entered in the GUI
% if modType==2 -> stimFreq==zeros(nGrasps,1) 
vars_GUI.minAmp = [100 100 100]; % [uA] if modType==1 -> minAmp is a vector of length nGrasps with each element to check that
% PW(i)*minAmp(i) < 120 nC; if modType==2 -> minAmp = zeros(nGrasps,1); 
vars_GUI.maxAmp = [500 500 500]; % [uA] maxAmp(i)>minAmp(i); if modType==1 -> maxAmp is a vector of length nGrasps with each element to check that
% PW(i)*maxAmp(i) < 120 nC; if modType==2 -> maxAmp = zeros(nGrasps,1); 
vars_GUI.minFreq = [0 0 0]; % [Hz] if modType==1 -> minFreq = zeros(nGrasps,1); if modType==2 -> 
% minFreq is a vector of length nGrasps with values entered in the GUI;
vars_GUI.maxFreq = [0 0 0]; % [Hz] maxFreq(i)>minFreq(i); if modType==1 -> maxFreq = zeros(nGrasps,1); if modType==2 -> 
% maxFreq is a vector of length nGrasps with values entered in the GUI;

% Buttons
stimEN = 1; % stim enable/disable