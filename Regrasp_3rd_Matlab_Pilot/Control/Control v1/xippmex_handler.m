classdef xippmex_handler

    methods(Static)


        %% Initialize NIP
        function [nipOffTime, lastNipTime] = initializeNIP()

            status = xippmex;

            if status == 1
                disp('NIP connected')
            else
                error('Xippmex Did Not Initialize'); 
            end

            lastNipTime = 0;
            nipOffTime = 0;
        end


        %% Setup stimulation
        function [stimChsID, stimCmd, cmdClear] = setupStim(vars)

            % Find all Stim and Micro/Nano channels and Corresponding FE's
            stimChsID = xippmex('elec','stim');

            % Make sure there is at least one Micro+stim FE present
            if isempty(stimChsID)
                error('No stimulation hardware detected');
            end

            % Initialize stimulation command (AMP and FREQ = 0 for all chs)
            stimCmd = struct([]);

            for iCh = 1:length(stimChsID)
                stimCmd(iCh).elec = stimChsID(iCh);
                stimCmd(iCh).period = floor(1000 / vars.baseFreq * vars.msec2nip_clk); % baseline Freq [clock cycles]
                stimCmd(iCh).repeats = vars.baseFreq; % # repetitions of stim cmd (we set it so that the cmd is repetead for 1 sec)
                stimCmd(iCh).action = vars.action; % when we want the stim command to be processed (immediately)
                stimCmd(iCh).seq(1) = struct('length', 1, 'ampl', 0, 'pol', 0, 'fs', 0, ...
                    'enable', 1, 'delay', 0, 'ampSelect', vars.AMP_STIM); % cathodic phase of stim
                stimCmd(iCh).seq(2) = struct('length', 1, 'ampl', 0, 'pol', 0, 'fs', 0, ...
                    'enable', 0, 'delay', 0, 'ampSelect', vars.AMP_STIM); % interphase interval
                stimCmd(iCh).seq(3) = struct('length', 1, 'ampl', 0, 'pol', 1, 'fs', 0,...
                    'enable', 1, 'delay', 0, 'ampSelect', vars.AMP_STIM); % anodic phase of stim

                fs_cycls = floor(vars.fs_us / vars.nipClock_us); % fast settle after stim pulse
                if fs_cycls > 0
                    stimCmd(iCh).seq(4) = struct('length', fs_cycls, 'ampl', 0, 'pol', 1, ...
                        'fs', 1, 'enable', 1, 'delay', 0, 'ampSelect', vars.AMP_STIM);
                end
            end

            % Command clear to use for not used chs
            cmdClear = stimCmd(1);
            
        end


        %% Enable stimulation
        function enableStim()

            % Enable stimulation
            % NOTE: If stimulation is not enabled, xippmex will enable and disable
            % stimulation for each stim sequence it receives. This will have the
            % undesirable side effect of killing queued stimulation sequences. Always
            % enable stimulation on the NIP before queueing multiple stimulation
            % sequences.
            xippmex('stim', 'enable', 1);
            pause(0.5)

        end


        %% Disable stimulation
        function disableStim()

            xippmex('stim', 'enable', 0);
            pause(0.5)

        end


        %% Switch between grasp types based on binary command
        function [graspIdx, stimCh, stimPW] = switchStim(graspIdx, varsGUI)

            graspIdx = graspIdx+1;
            if graspIdx>varsGUI.nGrasps
                graspIdx = 1;
            end

            % Set stimulation channel
            stimCh = varsGUI.stimCh(graspIdx);

            % Set pulse-width
            stimPW = varsGUI.stimPW(graspIdx);
        end


        %% Compute stimulation output based on proportional command
        function [stimAmp, stimFreq] = stimOutput(propCmd, varsGUI, graspIdx)

            if propCmd >= varsGUI.propThr

                if propCmd > varsGUI.propSat
                    propCmd = varsGUI.propSat; % saturation
                end

                if varsGUI.modType == 1 % AM
                    stimAmp = (varsGUI.maxAmp(graspIdx) - varsGUI.minAmp(graspIdx))/...
                        (varsGUI.propSat - varsGUI.propThr) * propCmd;
                    stimFreq = varsGUI.stimFreq(graspIdx);
                elseif varsGUI.modType == 2 % FM
                    stimFreq = (varsGUI.maxFreq(graspIdx) - varsGUI.minFreq(graspIdx))/...
                        (varsGUI.propSat - varsGUI.propThr) * propCmd;
                    stimAmp = varsGUI.stimAmp(graspIdx);
                end

            else
                stimAmp = 0;
                stimFreq = 1;
            end
        end

        
        %% Check if NIP is still ONLINE
        function [nipOffTime, lastNipTime] = checkNIP(nipOffTime, lastNipTime)

            curNipTime = xippmex('time'); % get the current NIP time

            if curNipTime == lastNipTime
                if nipOffTime == 0
                    tic;
                end
                nipOffTime = toc;
                
                if nipOffTime > 1 % if the NIP has been offline for a second abort the program
                    xippmex('close');
                    error('NIP appears to be off-line. Exiting program... Bye!')
                end
                
            else % if the NIP is on-line clear the off timer
                nipOffTime = 0; 
            end 
            lastNipTime = curNipTime; % update NIP time for the next pass through the loop

        end


        %% Send stimulation command
        function sendStimCmd(obj, stimCmd, stimChsID, stimCh, stimPW, stimAmp, stimFreq, cmdClear, vars)

            % CHECK THAT STIM DOES NOT EXCEED SAFETY LIMITS!!!!!!!!!!!
            if stimPW*stimAmp>vars.safeLimit
                obj.disableStim();
                xippmex('close');
                error('STIM EXCEEDS SAFETY LIMITS! Stim has been disabled.')
            end

            % Parameter conversion
            stimPW_cycles = floor(stimPW / vars.nipClock_us); % [clock cycles]
            stimAmp_steps = floor(stimAmp / vars.ampStepSize); % [steps]
            stimFreq_cycles = floor(1000 / stimFreq * vars.msec2nip_clk); % [clock cycles]

            % Create stim command for selected stimCh
            stimCmd(stimCh).seq(1).length = stimPW_cycles; % PW cathodic phase
            stimCmd(stimCh).seq(3).length = stimPW_cycles; % PW anodic phase

            stimCmd(stimCh).seq(1).ampl = stimAmp_steps; % AMP cathodic phase
            stimCmd(stimCh).seq(3).ampl = stimAmp_steps; % AMP anodic phase

            stimCmd(stimCh).period = stimFreq_cycles; % FREQ
            stimCmd(stimCh).repeats = stimFreq; % # repetitions of stim cmd (we set it so that the cmd is repetead for 1 sec)

            % Clear stim command for other stimChs (AMP and FREQ = 0)
            otherChs = find([1:length(stimChsID)]~=stimCh);
            for iC = otherChs
                stimCmd(iC) = cmdClear;
            end

            % Send stim command
            try
                xippmex('stimseq', stimCmd);               
            catch
                disp('Error in the stim command')
            end
        end

    end
end


