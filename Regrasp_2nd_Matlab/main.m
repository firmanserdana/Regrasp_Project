close all; fclose('all'); clc; clear;

try
    addpath('Regrasp_Dependency/Xippmex')
catch
    disp('Download Xippmex and add it to the path (Regrasp_Dependency/Xippmex) to use the Xippmex functions')
end

addpath('Functions')

%% Start NIP
status = 0;
try
    status = xippmex;
    while ~status
        status = xippmex;
    end
catch
    disp(["Could not find NIP."; "Check wired connection and open Trellis app."]);
    % delete(app);
end

%% Find all Stim and Micro/Nano channels and Corresponding FE's
stimChans  = xippmex('elec','stim');
%make sure there is at least one micro+stim front end present
if isempty(stimChans); error('No stimulation hardware detected');  end

stimChans = stimChans(1);   % solo a scopo dimostrativo, scrivo il codice
% per un solo canale ma nell'app posso scegliere il canale tra quelli disponibili

% Flush stim buffer
xippmex('spike',stimChans,1);
% the buffer is emptied soon after it's read, so no need to do it manually

% Activate 'stim' data stream
% Note only stim and spike streams are managed individually
if ~isempty(stimChans)
    xippmex('signal',stimChans,'stim',ones(1,length(stimChans)));
end
