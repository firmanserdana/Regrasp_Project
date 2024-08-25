clear all
close all
clc

addpath(genpath(pwd))


%% GUI parameters
load_paramsGUI;


%% Instantiate the classes
xipp = xippmex_handler;
pillow = pillowbutton_handler;
%sessantaquattro = sessantaquattroplus_handler;
sessantaquattro = rippleEMG_handler;
plots = plot_handler;


%% Connect with stimulator and setup stimulation
xipp.initializeXipp();
xipp.setupStim();


%% Connect with binary control device
if strcmp(paramsGUI.binDevice,'Pillow') % Pillow

    pillow.openSerial('COM3');

elseif strcmp(paramsGUI.binDevice,'eego') % eeg

end


%% Connect with proportional control device
if strcmp(paramsGUI.propDevice,'Sessantaquattro+') % 64+

    sessantaquattro.openSocket();
    sessantaquattro.configure();

elseif strcmp(paramsGUI.propDevice,'MTw Awinda') % MTw Awinda

end


%% Initialize plots
figure;
binCmdAxes = subplot(3,1,1);
propCmdAxes = subplot(3,1,2);
stimAxes = subplot(3,1,3);
plots.initializePlot(binCmdAxes, propCmdAxes, stimAxes,sessantaquattro.EMGsFreq);

scopeEMG = timescope( ...
    'NumInputPorts',2, ...
    'Name','EMG', ...
    'SampleRate',[sessantaquattro.EMGsFreq,sessantaquattro.EMGsFreq], ...
    'TimeDisplayOffset',[0,sessantaquattro.readWind/2], ...
    'TimeSpanSource','Property', ...
    'TimeSpan',10, ...
    'YLimits',[-1 1], ...
    'TimeSpanOverrunAction','Scroll');


%% Control loop (to start when I press the start stim button on the GUI)
% Initialization of stimulation parameters
xipp.gestureIdx = 1;
xipp.stimCh = paramsGUI.stimCh(1);
xipp.stimPW = paramsGUI.stimPW(1);
xipp.stimAmp = paramsGUI.stimAmp(1);
xipp.stimFreq = paramsGUI.stimFreq(1);

% Enable stim
xipp.enableStim();
stimEN = 1;

% ...
ccPlot = 0;

% GO
if strcmp(paramsGUI.propDevice,'Sessantaquattro+') % 64+

    while(stimEN)

        % -------------------- BINARY CONTROL -----------------------------
        pillow.readButtonState();

        if pillow.binCmd

            % Change the grasp type
            xipp.switchStim(paramsGUI);
        end
        % -----------------------------------------------------------------


        % -------------------- PROPORTIONAL CONTROL -----------------------
        if ~pillow.blockStim

            % Read EMG data
            sessantaquattro.receiveData();

            % Process EMG data to compute the proportional cmd
            sessantaquattro.processData(paramsGUI);

            % Compute stimulation output based on proportional cmd
            xipp.stimOutput(sessantaquattro.propCmd, paramsGUI);
        end
        % -----------------------------------------------------------------


        % --------------------- SEND STIM COMMAND -------------------------
        % Check if NIP is connected
        xipp.checkNIP();

        % Send stimulation cmd
        xipp.sendStimCmd();       
        % -----------------------------------------------------------------


        % ----------------------------- PLOT ------------------------------
        ccPlot = ccPlot + 1;

        plots.plotBinCmd(ccPlot, pillow.binSig);
        plots.plotPropCmd(ccPlot, sessantaquattro.propCmd)
        plots.plotStimVar(ccPlot, paramsGUI, xipp.stimAmp, xipp.stimFreq)

        scopeEMG(sessantaquattro.dataNorm',sessantaquattro.propCmd*ones(length(sessantaquattro.dataNorm),1)); 
        %scopeEMG(sessantaquattro.data(1,:)',sessantaquattro.propCmd*ones(size(sessantaquattro.data,2),1)); 
        % -----------------------------------------------------------------

    end

    % Disable stim
    xipp.disableStim();

    % Close xippmex
    xipp.close();

    % Close pillow
    pillow.closeSerial();

    % Close 64+ TCP socket
    sessantaquattro.close();


elseif strcmp(paramsGUI.propDevice,'MTw Awinda') % MTw Awinda

    while(paramsGUI.stimEN)



    end

    % Disable stim
    xipp.disableStim();
end

