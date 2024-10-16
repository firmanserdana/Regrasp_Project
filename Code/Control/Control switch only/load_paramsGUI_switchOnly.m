% Control parameters 
paramsGUI.binDevice = 'Pillow'; % Pillow or eego

% Stimulation parameters
paramsGUI.gestures = {'hand open','sphere'}; % gestures name
paramsGUI.nGestures = length(paramsGUI.gestures); % # gestures
paramsGUI.stimCh = [5 ; 15]; % vector of length nGrasps, each element can take an integer value between 1 and 64 
paramsGUI.stimPW = [40 ; 40]; % [us] vector of length nGrasps
paramsGUI.stimAmp = [500 ; 500]; % [uA] vector of length nGrasps
paramsGUI.stimFreq = [30 ; 30]; % [uA] vector of length nGrasps