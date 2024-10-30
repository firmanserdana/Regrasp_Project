classdef xippmex_handler_old < handle

    properties (Access = private)

        % ....
        safeLimit = 120*1e3;    % [pC]
        ampStepSize;            % [uA]

        % ....
        lastNipTime;    % ...
        nipOffTime;     % ...

        %
        nipClock_us = 1e6/3e4;  % 33.333 us
        msec2nip_clk = 30;
        nip_clk2sec = 1/3e4;
        nip_clk2msec = 1/3e1;
        AMP_STIM = 1;           % used to set the input channel amp to measure stim voltage
        action = 'immed';
        baseFreq = 1;           % for the clear command

    end

    properties (Access = public)
        
        %
        stimCmd;
        cmdClear;
        gestureCmd;

        stimChsID;      % ...
        gestureIdx;     % ...
        gestureName;
        stimCh;         % ...
        stimPW;         % ...
        stimAmp;        % ...
        stimFreq;       % ...
        stimDur = 1;    % [s]

    end


    methods (Access = public)

        %% Initialize NIP
        function status = initializeXipp(obj, newRipple)

            try
                if newRipple
                    status = xippmex('tcp'); % TCP communication
                    xippmex('addoper', 129); % set operator (for recording)
                else
                    status = xippmex; % UDP communication
                end
                pause(1);
            catch
                errordlg('Could not find NIP');
                status = 0;
                return
            end

            if status == 1
                disp('NIP connected')
                obj.lastNipTime = 0;
                obj.nipOffTime = 0;
            else
                errordlg('Xippmex Did Not Initialize');
                %error('Xippmex Did Not Initialize');
            end

        end

        %% Setup stimulation
        function obj = setupStim(obj, newRipple, stimRes)

            % Find all Stim and Micro/Nano channels and Corresponding FE's
            obj.stimChsID = xippmex('elec','stim');

            % Make sure there is at least one Micro+stim FE present
            if isempty(obj.stimChsID)
                errordlg('No stimulation hardware detected');
                %error('No stimulation hardware detected');
            end

            % Set stimulation step size for the available chs
            if newRipple
                xippmex('stim','res',obj.stimChsID,stimRes);
                obj.ampStepSize = 10; % [uA/step]
            else
                obj.ampStepSize = 7.5; % [uA/step]
            end

            % flush stim buffer by calling spike cmd
            xippmex('spike',obj.stimChsID,1);

            % Initialize command clear for not used chs (AMP = 0, FREQ = baseFreq, repeats)
            for iCh = 1:length(obj.stimChsID)

                obj.cmdClear(iCh).elec = obj.stimChsID(iCh);
                obj.cmdClear(iCh).period = floor(1000 ./ obj.baseFreq .* obj.msec2nip_clk); % [clock cycles]
                obj.cmdClear(iCh).repeats = 1; % # repetitions of stim cmd
                obj.cmdClear(iCh).action = obj.action; % when we want the stim command to be processed (immediately)
                obj.cmdClear(iCh).seq(1) = struct('length', 1, 'ampl', 0, 'pol', 0, 'fs', 0, ...
                    'enable', 1, 'delay', 0, 'ampSelect', obj.AMP_STIM); % cathodic phase of stim
                obj.cmdClear(iCh).seq(2) = struct('length', 1, 'ampl', 0, 'pol', 0, 'fs', 0, ...
                    'enable', 0, 'delay', 0, 'ampSelect', obj.AMP_STIM); % interphase interval
                obj.cmdClear(iCh).seq(3) = struct('length', 1, 'ampl', 0, 'pol', 1, 'fs', 0,...
                    'enable', 1, 'delay', 0, 'ampSelect', obj.AMP_STIM); % anodic phase of stim
            end
        end

        %%
        function setGestureCmd(obj, paramsGUI)

            for iG = 1:paramsGUI.nGestures

                % Take parameters
                stimChG = paramsGUI.stimCh(iG,:);
                stimPWG = paramsGUI.stimPW(iG,:);

                % Remove nans
                stimChG = stimChG(~isnan(stimChG));
                stimPWG = stimPWG(~isnan(stimPWG));

                % Parameter conversion
                stimPW_cycles = round(stimPWG ./ obj.nipClock_us); % [clock cycles]

                % Create stim command for selected stimCh
                obj.gestureCmd{iG} = obj.cmdClear;

                for iCh = 1:length(stimChG)

                    obj.gestureCmd{iG}(stimChG(iCh)).seq(1).length = stimPW_cycles(iCh); % PW cathodic phase
                    obj.gestureCmd{iG}(stimChG(iCh)).seq(3).length = stimPW_cycles(iCh); % PW anodic phase

                end
            end
        end

        %% Check if NIP is still ONLINE
        function obj = checkNIP(obj)

            curNipTime = xippmex('time'); % get the current NIP time

            if curNipTime == obj.lastNipTime
                if obj.nipOffTime == 0
                    tic;
                end
                obj.nipOffTime = toc;

                if obj.nipOffTime > 1 % if the NIP has been offline for a second abort the program
                    xippmex('close');
                    error('NIP appears to be off-line. Exiting program... Bye!')
                end

            else % if the NIP is on-line clear the off timer
                obj.nipOffTime = 0;
            end
            obj.lastNipTime = curNipTime; % update NIP time for the next pass through the loop
        end

        %% Switch between gesture types based on binary command
        function switchStim(obj, paramsGUI)

            obj.gestureIdx = obj.gestureIdx + 1;
            if obj.gestureIdx > paramsGUI.nGestures
                obj.gestureIdx = 1;
            end

            % Gesture name
            obj.gestureName = paramsGUI.gestures{obj.gestureIdx};

            % Set stimulation channel
            obj.stimCh = paramsGUI.stimCh(obj.gestureIdx,:);

            % Set pulse-width
            obj.stimPW = paramsGUI.stimPW(obj.gestureIdx,:);

            % Remove nans
            obj.stimCh = obj.stimCh(~isnan(obj.stimCh));
            obj.stimPW = obj.stimPW(~isnan(obj.stimPW));

            % Set the stim command
            obj.stimCmd = obj.gestureCmd{obj.gestureIdx};

        end

        %% Compute stimulation output based on proportional command
        function stimOutput(obj, propCmd, paramsGUI)

            % Prop command is above threshold
            if propCmd >= paramsGUI.propThr

                if propCmd > paramsGUI.propSat
                    propCmd = paramsGUI.propSat; % saturation
                end

                if strcmp(paramsGUI.modType,'AM') % AM
                    obj.stimAmp = (paramsGUI.maxAmp(obj.gestureIdx,:) - paramsGUI.minAmp(obj.gestureIdx,:))/...
                        (paramsGUI.propSat - paramsGUI.propThr) * (propCmd - paramsGUI.propThr)  + paramsGUI.minAmp(obj.gestureIdx,:);
                    obj.stimFreq = paramsGUI.stimFreq(obj.gestureIdx,:);
                elseif strcmp(paramsGUI.modType,'FM') % FM
                    obj.stimFreq = (paramsGUI.maxFreq(obj.gestureIdx,:) - paramsGUI.minFreq(obj.gestureIdx,:))/...
                        (paramsGUI.propSat - paramsGUI.propThr) * (propCmd - paramsGUI.propThr) + paramsGUI.minFreq(obj.gestureIdx,:);
                    obj.stimAmp = paramsGUI.stimAmp(obj.gestureIdx,:);
                end

                % Prop command is below threshold
            else
                obj.stimAmp = zeros(size(paramsGUI.stimCh(obj.gestureIdx)));
                obj.stimFreq = ones(size(paramsGUI.stimCh(obj.gestureIdx)));
            end

            % Remove nans
            obj.stimAmp = obj.stimAmp(~isnan(obj.stimAmp));
            obj.stimFreq = obj.stimFreq(~isnan(obj.stimFreq));

            % CHECK THAT STIM DOES NOT EXCEED SAFETY LIMITS!!!!!!!!!!!
            if ~isempty(find(obj.stimPW.*obj.stimAmp > obj.safeLimit))
                obj.disableStim();
                xippmex('close');
                error('STIM EXCEEDS SAFETY LIMITS! Stim has been disabled.')
            end

            % Parameter conversion
            stimAmp_steps = floor(obj.stimAmp ./ obj.ampStepSize); % [steps]
            stimFreq_cycles = floor(1000 ./ obj.stimFreq .* obj.msec2nip_clk); % [clock cycles]

            % Set the values in the stim command
            for iCh = 1:length(obj.stimCh)

                obj.stimCmd(obj.stimCh(iCh)).seq(1).ampl = stimAmp_steps(iCh); % AMP cathodic phase
                obj.stimCmd(obj.stimCh(iCh)).seq(3).ampl = stimAmp_steps(iCh); % AMP anodic phase

                obj.stimCmd(obj.stimCh(iCh)).period = stimFreq_cycles(iCh); % FREQ
                obj.stimCmd(obj.stimCh(iCh)).repeats = obj.stimFreq(iCh) * obj.stimDur; % # repetitions of stim cmd
            end
        end

        %% Send stimulation command
        function sendStimCmd(obj)

            % CHECK THAT STIM DOES NOT EXCEED SAFETY LIMITS!!!!!!!!!!!
            if ~isempty(find(obj.stimPW.*obj.stimAmp > obj.safeLimit))
                obj.disableStim();
                xippmex('close');
                error('STIM EXCEEDS SAFETY LIMITS! Stim has been disabled.')
            end

            % Send stim command
            if obj.stimAmp > 0
                disp('a > 0');
            end

            try
                xippmex('stimseq', obj.stimCmd);
            catch
                disp('Error in the stim command')
            end
        end
    end


    methods (Static)

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

        %% Close xippmex
        function close()

            xippmex('close')
            pause(0.5)
        end

        %% Convert numerical array into comma separated string
        function out = cstr(in)

            in = in(~isnan(in));
            out = strjoin(compose('%d',in),',');

        end
    end
end



