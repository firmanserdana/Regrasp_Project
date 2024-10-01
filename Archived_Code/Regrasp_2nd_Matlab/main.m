close all;
fclose('all');
clc;
clear;

try
    addpath(genpath('Regrasp_2nd_Matlab/Regrasp_Dependency'))
catch
    disp('Download Xippmex and add it to the path (Regrasp_Dependency/Xippmex) to use the Xippmex functions')
end

addpath(genpath('Regrasp_2nd_Matlab/Functions'))

vars = default_init_values('AM');


sessantaquattroplus_handler = sessantaquattroplus_handler();
t = sessantaquattroplus_handler.openSocket();
[numChannels,sampFreq,bufData] = sessantaquattroplus_handler.configure(t, vars.GO, vars.REC, vars.TRIG, vars.EXTEN, vars.HPF, vars.HRES, vars.MODE, vars.NCH, vars.FSAMP, vars.bufWind);


xippmex_handler = xippmex_handler();
xippmex_handler.statusNIP();
xippmex_handler.setupStimulation();
[cmd, cmdClear] = xippmex_handler.initializeStimulation(vars.stimChans, vars.cs, vars.phaseDur_us, vars.fs_us, vars.stimFreq, vars.pulseAmpSteps, vars.nipClock_us, vars.nip_clk2sec, vars.AMP_STIM, vars.AMP_NEURAL);

figure;  % Create a new figure window for the plot
subplot(2, 1, 1);  % Create the first subplot for data
hData = plot(1);  % Plot the data
title('EMG Data');

subplot(2, 1, 2);  % Create the second subplot for stimulation signals
hStim = plot(1);  % Plot the stimulation signals
title('Stimulation Signals');

while true
    data = sessantaquattroplus_handler().receiveData(t, vars.HRES, numChannels, sampFreq, vars.readWind);
    [dataNorm,dataEnv] = sessantaquattroplus_handler().processData(data,vars.MVC,vars.chX,bufData);
    ampRngFrac = xippmex_handler().runStimulationLoop(dataEnv, bufData, vars.stimChans, vars.cs, vars.env_thr, vars.forceRange_mV, vars.MVC, vars.nipClock_us, vars.msec2nip_clk, vars.AMP_STIM, cmd, cmdClear);
    % Update the data plot
    set(hData, 'YData', dataNorm);
    % Update the stimulation signals plot
    set(hStim, 'YData', ampRngFrac);
    
    drawnow;  % Update the plot immediately
    
    % Add any additional code or conditions for the loop termination
    
end
