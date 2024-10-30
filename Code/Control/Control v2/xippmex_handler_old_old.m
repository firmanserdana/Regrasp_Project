classdef xippmex_handler_old_old < handle

    properties (Access = private)

        % ....
        safeLimit = 120*1e3;    % [pC]
        ampStepSize;            % [uA]

        % ....
        lastNipTime;    % ...
        nipOffTime;     % ...

    end

    properties (Access = public)

        stimChsID;      % ...
        gestureIdx;     % ...
        gestureName;
        stimCh;         % ...
        stimPW;         % ...
        stimAmp;        % ...
        stimFreq;       % ...

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
        end

        %% Send stimulation command
        function sendStimCmd(obj)
            
            % Remove nans
            obj.stimCh = obj.stimCh(~isnan(obj.stimCh));
            obj.stimPW = obj.stimPW(~isnan(obj.stimPW));
            obj.stimAmp = obj.stimAmp(~isnan(obj.stimAmp));
            obj.stimFreq = obj.stimFreq(~isnan(obj.stimFreq));

            % ...
            if ~isempty(find(obj.stimAmp > 0))

                % CHECK THAT STIM DOES NOT EXCEED SAFETY LIMITS!!!!!!!!!!!
                if ~isempty(find(obj.stimPW.*obj.stimAmp > obj.safeLimit))
                    obj.disableStim();
                    xippmex('close');
                    error('STIM EXCEEDS SAFETY LIMITS! Stim has been disabled.')
                end

                % Parameter conversion / update
                stimPW_ms = obj.stimPW*1e-3; % [ms]
                stimAmp_steps = floor(obj.stimAmp / obj.ampStepSize); % [steps]
                
                % Fixed parameters
                TL = 1e3 * ones(size(obj.stimCh));  % length of each stim command [ms]
                TD = zeros(size(obj.stimCh));       % delay of each stim command [ms]
                FS = zeros(size(obj.stimCh));       % fast settle [ms]
                PL = ones(size(obj.stimCh));        % polarity (1 = cathodic-first, 0 = anodic-first)

                % Create stim string
                try
                stimString = [...
                    'Elect=' obj.cstr(obj.stimChsID(obj.stimCh)) ',;' ...
                    'TL=' obj.cstr(TL) ',;' ...
                    'Freq=' obj.cstr(obj.stimFreq) ',;' ...
                    'Dur=' obj.cstr(stimPW_ms) ',;' ...
                    'Amp=' obj.cstr(stimAmp_steps) ',;' ...
                    'TD=' obj.cstr(TD) ',;' ...
                    'FS=' obj.cstr(FS) ',;' ...
                    'PL=' obj.cstr(PL) ',;'];
                catch
                    a = 0;
                end

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
            
            in = in(~isnan(in));
            out = strjoin(compose('%d',in),',');

        end
    end
end



