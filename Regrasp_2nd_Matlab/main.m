clear all
close all
clc

addpath(genpath('Regrasp_Dependency'))


%% Parameters
% Fixed parameters
load_vars;

% GUI parameters
load_varsGUI;


%% Connect with stimulator and setup stimulation
[nipOffTime, lastNipTime] = xippmex_handler.initializeNIP();
[stimChsID, stimCmd, cmdClear] = xippmex_handler.setupStim(vars);


%% Connect with binary control device
if vars_GUI.binDevice==1 % Pillow

    s = pillowbutton_handler.openSerial();

elseif vars_GUI.binDevice==2 % eeg

end


%% Connect with proportional control device
if vars_GUI.propDevice==1 % 64+

    t = sessantaquattroplus_handler.openSocket();
    [nEMGchs,EMGsFreq,blockData,bufData] = sessantaquattroplus_handler.configure(t, vars);

elseif vars_GUI.propDevice==2 % MTw Awinda

end


%% Control loop (to start when I press the start stim button on the GUI)
% Initialization of stimulation parameters
graspIdx = 1;
stimCh = varsGUI.stimCh(graspIdx);
stimPW = varsGUI.stimPW(graspIdx);
stimAmp = varsGUI.stimAmp(graspIdx);
stimFreq = varsGUI.stimFreq(graspIdx);
buttonState = 0;
buttonState_pre = 0;

% Enable stim
xippmex_handler.enableStim();

% GO
if vars_GUI.propDevice==1 % 64+

    while(varsGUI.stimEN)

        % -------------------- BINARY CONTROL -----------------------------
        buttonState = pillowbutton_handler.readButtonState(s);

        % Check if the state of the button has changed from 0 to 1
        if buttonState_pre==0 & buttonState==1

            % Change the grasp type
            [graspIdx, stimCh, stimPW] = xippmex_handler.switchStim(graspIdx, varsGUI);
            
            % Check if NIP is connected
            [nipOffTime, lastNipTime] = xippmex_handler.checkNIP(nipOffTime, lastNipTime);
            
            % Send stimulation cmd
            xippmex_handler.sendStimCmd(stimCmd, stimChsID, stimCh, stimPW, stimAmp, stimFreq, cmdClear, vars);
        end
        
        buttonState_pre = buttonState;
        % -----------------------------------------------------------------


        % -------------------- PROPORTIONAL CONTROL -----------------------
        % Read EMG data
        data = sessantaquattroplus_handler.receiveData(t, blockData, vars, nEMGchs, EMGsFreq);

        % Process EMG data to compute the proportional cmd
        [propCmd, dataNorm] = sessantaquattroplus_handler.processData(data, vars, varsGUI, bufData);

        % Compute stimulation output based on proportional cmd
        [stimAmp, stimFreq] = xippmex_handler.stimOutput(propCmd, varsGUI, graspIdx);

        % Check if NIP is connected
        [nipOffTime, lastNipTime] = xippmex_handler.checkNIP(nipOffTime, lastNipTime);

        % Send stimulation cmd
        xippmex_handler.sendStimCmd(stimCmd, stimChsID, stimCh, stimPW, stimAmp, stimFreq, cmdClear, vars);
        % -----------------------------------------------------------------

    end

    % Disable stim
    xippmex_handler.disableStim();

    % Close 64+ TCP socket
    sessantaquattroplus_handler.closeSocket();


elseif vars_GUI.propDevice==2 % MTw Awinda

    while(varsGUI.stimEN)



    end

    % Disable stim
    xippmex_handler.disableStim();
end

