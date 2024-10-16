clear all
close all
clc

addpath(genpath(pwd))


%% GUI parameters
load_paramsGUI_switchOnly;


%% Instantiate the classes
xipp = xippmex_handler_switchOnly;
pillow = pillowbutton_handler_switchOnly;
plots = plot_handler_switchOnly;


%% Connect with stimulator and setup stimulation
xipp.initializeXipp();
xipp.setupStim();


%% Connect with pillow
pillow.openSerial('COM3');


%% Read the tones associated to the grasps
%pillow.readTones;


%% Initialize plots
figure;
binCmdAxes = subplot(2,1,1);
stimAxes = subplot(2,1,2);

plots.initializePlot(binCmdAxes, stimAxes, pillow.loopFreq, paramsGUI);


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
r = rateControl(pillow.loopFreq);
reset(r);

while(stimEN)

    tic
    % -------------------- BINARY CONTROL -----------------------------
    pillow.readButtonState();

    if pillow.binCmd

        % Change the grasp type
        xipp.switchStim(paramsGUI);
    end
    % -----------------------------------------------------------------

    % --------------------- SEND STIM COMMAND -------------------------
    % Check if NIP is connected
    %xipp.checkNIP();

    % Send stimulation cmd
    xipp.sendStimCmd();
    % -----------------------------------------------------------------

    % ----------------------------- PLOT ------------------------------
    ccPlot = ccPlot + 1;

    plots.plotBinCmd(ccPlot, pillow.binSig);
    plots.plotStimVar(ccPlot, xipp.stimCh);
    % -----------------------------------------------------------------

    waitfor(r);
    disp(toc);

end

% Disable stim
xipp.disableStim();
