classdef xippmex_handler < handle

    properties (Access = private)

        % ....
        safeLimit = 120*1e3;    % [pC]
        ampStepSize = 7.5;      % [uA] CHECK THIIIIIIIS

        % ....
        lastNipTime;    % ...
        nipOffTime;     % ...

    end

    properties (Access = public)

        stimChsID;      % ...
        gestureIdx;       % ...
        gestureName;
        stimCh;         % ...
        stimPW;         % ...
        stimAmp;        % ...
        stimFreq;       % ...

    end


    methods (Access = public)

        %% Initialize NIP
        function status = initializeXipp(obj)

            status = xippmex;

            if status == 1
                disp('NIP connected')
            else
                error('Xippmex Did Not Initialize');
            end

            obj.lastNipTime = 0;
            obj.nipOffTime = 0;

        end

        %% Setup stimulation
        function obj = setupStim(obj)

            % Find all Stim and Micro/Nano channels and Corresponding FE's
            obj.stimChsID = xippmex('elec','stim');

            % Make sure there is at least one Micro+stim FE present
            if isempty(obj.stimChsID)
                error('No stimulation hardware detected');
            end

            % flush stim buffer by calling spike cmd
            xippmex('spike',obj.stimChsID,1);

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
            obj.stimCh = paramsGUI.stimCh(obj.gestureIdx);

            % Set pulse-width
            obj.stimPW = paramsGUI.stimPW(obj.gestureIdx);
        end

        %% Compute stimulation output based on proportional command
        function stimOutput(obj, propCmd, varsGUI)

            % Prop command is above threshold
            if propCmd >= varsGUI.propThr

                if propCmd > varsGUI.propSat
                    propCmd = varsGUI.propSat; % saturation
                end

                if strcmp(varsGUI.modType,'AM') % AM
                    obj.stimAmp = (varsGUI.maxAmp(obj.gestureIdx) - varsGUI.minAmp(obj.gestureIdx))/...
                        (varsGUI.propSat - varsGUI.propThr) * (propCmd - varsGUI.propThr)  + varsGUI.minAmp(obj.gestureIdx);
                    obj.stimFreq = varsGUI.stimFreq(obj.gestureIdx);
                elseif strcmp(varsGUI.modType,'FM') % FM
                    obj.stimFreq = (varsGUI.maxFreq(obj.gestureIdx) - varsGUI.minFreq(obj.gestureIdx))/...
                        (varsGUI.propSat - varsGUI.propThr) * (propCmd - varsGUI.propThr) + varsGUI.minFreq(obj.gestureIdx);
                    obj.stimAmp = varsGUI.stimAmp(obj.gestureIdx);
                end

                % Prop command is below threshold
            else
                obj.stimAmp = 0;
                obj.stimFreq = 1;
            end
        end

        %% Send stimulation command
        function sendStimCmd(obj)

            if obj.stimAmp > 0

                % CHECK THAT STIM DOES NOT EXCEED SAFETY LIMITS!!!!!!!!!!!
                if ~isempty(find(obj.stimPW.*obj.stimAmp > obj.safeLimit))
                    obj.disableStim();
                    xippmex('close');
                    error('STIM EXCEEDS SAFETY LIMITS! Stim has been disabled.')
                end

                % Parameter conversion / update
                stimPW_ms = obj.stimPW*1e-3; % [ms]
                stimAmp_steps = floor(obj.stimAmp / obj.ampStepSize); % [steps]
                TL = 1e3; % 1000 [ms]
                TD = 0; % [ms]
                FS = 0;
                PL = 1;

                % Create stim string
                stimString = [...
                    'Elect=' obj.cstr(obj.stimChsID(obj.stimCh)) ',;' ...
                    'TL=' obj.cstr(TL) ',;' ...
                    'Freq=' obj.cstr(obj.stimFreq) ',;' ...
                    'Dur=' obj.cstr(stimPW_ms) ',;' ...
                    'Amp=' obj.cstr(stimAmp_steps) ',;' ...
                    'TD=' obj.cstr(TD) ',;' ...
                    'FS=' obj.cstr(FS) ',;' ...
                    'PL=' obj.cstr(PL) ',;'];

                % Send stim command
                try
                    xippmex('stim', stimString);
                catch
                    disp('Error in the stim command')
                end
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

            out = strjoin(compose('%d',in),',');

        end
    end
end



