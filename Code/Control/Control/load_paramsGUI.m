% Control parameters 
paramsGUI.binDevice = 'Pillow'; % Pillow or eego
paramsGUI.propDevice = 'MTw Awinda'; % Sessantaquattro+ or MTw Awinda
paramsGUI.propThr = 0.3; % between 0 and 1
paramsGUI.propSat = 0.7; % between 0 and 1 (propSat > propThr)

% Calibration parameters
paramsGUI.emgMVC = 200; % MVC of control muscle
paramsGUI.minPitch = -20; % min of pitch angle from IMU
paramsGUI.maxPitch = 0; % max of pitch angle from IMU

% Stimulation parameters
paramsGUI.modType = 'FM'; % 1 for amp modulation, 2 for freq modulation
paramsGUI.gestures = {'hand open','pinch','sphere'}; % gestures name
paramsGUI.nGestures = length(paramsGUI.gestures); % # gestures
paramsGUI.stimCh = [5; 10; 15]; % vector of length nGrasps, each element can take an integer value between 1 and 64 
paramsGUI.stimPW = [40; 40; 40]; % [us] vector of length nGrasps
paramsGUI.stimAmp = [500; 500; 500]; % [uA] if modType==1 -> stimAmp = zeros(nGrasps,1); if modType==2 -> 
% stimAmp is a vector of length nGrasps with each element to check that
% PW(i)*stimAmp(i) < 120 nC
paramsGUI.stimFreq = [50; 50; 50]; % [Hz] if modType==1 -> stimFreq is a vector of length nGrasps with values entered in the GUI
% if modType==2 -> stimFreq==zeros(nGrasps,1) 
paramsGUI.minAmp = [100; 0; 100]; % [uA] if modType==1 -> minAmp is a vector of length nGrasps with each element to check that
% PW(i)*minAmp(i) < 120 nC; if modType==2 -> minAmp = zeros(nGrasps,1); 
paramsGUI.maxAmp = [500; 200; 500]; % [uA] maxAmp(i)>minAmp(i); if modType==1 -> maxAmp is a vector of length nGrasps with each element to check that
% PW(i)*maxAmp(i) < 120 nC; if modType==2 -> maxAmp = zeros(nGrasps,1); 
paramsGUI.minFreq = [10; 10; 10]; % [Hz] if modType==1 -> minFreq = zeros(nGrasps,1); if modType==2 -> 
% minFreq is a vector of length nGrasps with values entered in the GUI;
paramsGUI.maxFreq = [100; 100; 100]; % [Hz] maxFreq(i)>minFreq(i); if modType==1 -> maxFreq = zeros(nGrasps,1); if modType==2 -> 
% maxFreq is a vector of length nGrasps with values entered in the GUI;