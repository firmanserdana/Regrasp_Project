classdef rippleEMG_handler < handle

    properties (Access = public)

        % ....
        EMGchsID;
        EMGsFreq = 2000;       % ...
        timeReadStep;   % ...
        bufData;        % ....

        data;           % ...
        dataEnv;
        dataNorm;       % ...
        propCmd = 0;    % ...

        % Parameters for data processing
        EMGchC = 1; % selected EMG control channel
        readWind = 0.08; % [s]
        bufWind = 0.24; % [s]
    end

    methods (Access = public)

        %% Open socket
        function status = openSocket(obj)
            
            try
                obj.EMGchsID = xippmex('elec','EMG');
            catch
                status = 0;
                errordlg('Could not find NIP.');
                return;
            end

            if isempty(obj.EMGchsID)
                status = 0;
                errordlg('No EMG FE detected.');
            else
                status = 1;
                obj.timeReadStep = tic;
            end

        end

        %% Configuration
        function configure(obj)

            % Set analog filters
            xippmex('filter','set',obj.EMGchsID(obj.EMGchC),'hires notch',5); % notch at 50/100/150 Hz
            xippmex('filter','set',obj.EMGchsID(obj.EMGchC),'hires',6); % band-pass 15-375 Hz

            pause(0.5);

            % Create buffer for data acquisition
            obj.bufData = dsp.AsyncBuffer(obj.bufWind*obj.EMGsFreq); % buffer
        end

        %% Read data
        function receiveData(obj)

            pause(obj.readWind-toc(obj.timeReadStep))

            obj.data = xippmex('cont',obj.EMGchsID(obj.EMGchC),obj.readWind*1000,'hi-res');

            obj.timeReadStep = tic;

            % Deal with packet loss
            obj.data(find(obj.data<-1000)) = 0; % packet loss

        end

        %% Process data
        function processData(obj, paramsGUI)

            % Write data into buffer
            write(obj.bufData, obj.data');

            % Read data from buffer without changing the number of unread samples (peek)
            pointData = peek(obj.bufData);

            % Compute envelope using RMS
            obj.dataEnv = rms(pointData);

            % Normalize envenlope and raw data with respect to MVC
            obj.dataNorm = obj.data ./ paramsGUI.emgMVC;
            obj.propCmd = obj.dataEnv / paramsGUI.emgMVC;

        end

        %% Close xippmex
        function close(obj)

        end

    end
end