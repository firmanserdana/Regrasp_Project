clear all
close all
clc

addpath(genpath(pwd))


%% Parameters
% Fixed parameters
load_vars;

% GUI parameters
load_varsGUI;


%% Connect with stimulator and setup stimulation
[nipOffTime, lastNipTime] = xippmex_handler.initializeNIP();
[stimChsID, stimCmd, cmdClear] = xippmex_handler.setupStim(vars);


%% Connect with binary control device
if varsGUI.binDevice==1 % Pillow

    s = pillowbutton_handler.openSerial();

elseif varsGUI.binDevice==2 % eeg

end


%% Connect with proportional control device
if varsGUI.propDevice==1 % 64+

    t = sessantaquattroplus_handler.openSocket();
    [nEMGchs,EMGsFreq,blockData,bufData] = sessantaquattroplus_handler.configure(t, vars);

elseif varsGUI.propDevice==2 % MTw Awinda

end


%% Initialize plot
[figStreams, binCmdLine, propCmdLine, stimLine] = plot_handler.initializePlot(vars);


%% Control loop (to start when I press the start stim button on the GUI)
% Initialization of stimulation parameters
graspIdx = 1;
stimCh = varsGUI.stimCh(graspIdx);
stimPW = varsGUI.stimPW(graspIdx);
stimAmp = varsGUI.stimAmp(graspIdx);
stimFreq = varsGUI.stimFreq(graspIdx);
binCmd = 0;
binCmd_pre = 0;
ccPlot = 0;

% Enable stim
xippmex_handler.enableStim();

% GO
if varsGUI.propDevice==1 % 64+

    while(varsGUI.stimEN)

        % -------------------- BINARY CONTROL -----------------------------
        binCmd = pillowbutton_handler.readButtonState(s);

        if binCmd==1

            disp('SWITCH')

            % Change the grasp type
            [graspIdx, stimCh, stimPW] = xippmex_handler.switchStim(graspIdx, varsGUI);

            % Check if NIP is connected
            [nipOffTime, lastNipTime] = xippmex_handler.checkNIP(nipOffTime, lastNipTime);

            % Send stimulation cmd
            xippmex_handler.sendStimCmd(xippmex_handler, stimCmd, stimChsID, stimCh, stimPW, stimAmp, stimFreq, cmdClear, vars);
        end

        binCmd_pre = binCmd;
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
        xippmex_handler.sendStimCmd(xippmex_handler, stimCmd, stimChsID, stimCh, stimPW, stimAmp, stimFreq, cmdClear, vars);
        % -----------------------------------------------------------------


        % ----------------------------- PLOT ------------------------------
        ccPlot = ccPlot + 1;

        plot_handler.plotBinCmd(figStreams, binCmdLine, binCmd, ccPlot);
        plot_handler.plotPropCmd(figStreams, propCmdLine, propCmd, ccPlot)
        plot_handler.plotStimVar(figStreams, stimLine, stimAmp, stimFreq, varsGUI, ccPlot)
        % -----------------------------------------------------------------

    end

    % Disable stim
    xippmex_handler.disableStim();

    % Close 64+ TCP socket
    sessantaquattroplus_handler.closeSocket();


elseif varsGUI.propDevice==2 % MTw Awinda

    while(varsGUI.stimEN)



    end

    % Disable stim
    xippmex_handler.disableStim();
end

