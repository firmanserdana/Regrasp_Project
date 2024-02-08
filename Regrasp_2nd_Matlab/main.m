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
xippmex_handler.initializeStimulation(vars.stimChans, vars.cs, vars.phaseDur_us, vars.fs_us, vars.stimFreq, vars.pulseAmpSteps, vars.nipClock_us, vars.nip_clk2sec, vars.nip_clk2msec, vars.nip_clk2usec, vars.AMP_STIM);

figure;  % Create a new figure window for the plot
data = [];
stimulationsignals =[] ;
subplot(2, 1, 1);  % Create the first subplot for data
hData = plot(data);  % Plot the data
title('Data');

subplot(2, 1, 2);  % Create the second subplot for stimulation signals
hStim = plot(stimulationsignals);  % Plot the stimulation signals
title('Stimulation Signals');

while true
    data = sessantaquattroplus_handler().receiveData(t, vars.HRES, numChannels, sampFreq, vars.readWind);
    [dataNorm,dataEnv] = sessantaquattroplus_handler().processData(data,vars.MVC,vars.chX,bufData);
    %stimulationsignals = xippmex_handler().runStimulationLoop(data, vars.h, vars.bufdata, vars.selected_elecs, vars.read_win, vars.stimChans, vars.cs, vars.env_thr, vars.forceRange_mV, vars.MVC, vars.nipClock_us, vars.msec2nip_clk, vars.AMP_STIM, cmd, cmdClear);
    
    % Update the data plot
    plot(data);
    
    % Update the stimulation signals plot
    %set(hStim, 'YData', stimulationsignals);
    
    drawnow;  % Update the plot immediately
    
    % Add any additional code or conditions for the loop termination
    
end
