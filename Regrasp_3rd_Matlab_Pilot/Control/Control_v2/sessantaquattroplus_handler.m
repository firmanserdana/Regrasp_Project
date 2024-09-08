classdef sessantaquattroplus_handler < handle

    properties (Access = private)

        % Parameters for data acquisition
        FSAMP = 2;      % if MODE != 3: 0 = 500 Hz,  1 = 1000 Hz, 2 = 2000 Hz
        % if MODE == 3: 0 = 2000 Hz, 1 = 4000 Hz, 2 = 8000 Hz
        NCH  = 0;       % 0 = 8 channels, 1 = 16 channels, 2 = 32 channels, 3 = 64 channels
        MODE = 1;       % 0 = Monopolar, 1 = Bipolar, 2 = Differential, 3 = Accelerometers, 6 = Impedance check, 7 = Test Mode
        HRES = 0;       % 0 = 16 bits, 1 = 24 bits
        HPF  = 1;       % 0 = DC coupled, 1 = High pass filter active
        EXTEN = 0;      % 0 = standard input range, 1 = double range, 2 = range x 4, 3 = range x 8
        TRIG = 0;       % 0 = Data transfer controlled remotely, 3 = REC on SD controlled from the pushbutton or remotely
        REC  = 0;       % 0 = stop data recording on SD card, 1 = start data recording on SD card
        GO   = 1;       % 0 = just send the settings, 1 = send settings and start the data transfer
        ConvFact = 0.000286; % Conversion factor for the bioelectrical signals to get the values in mV

    end

    properties (Access = public)

        % ....
        t;              % ...
        nEMGchs;        % ....
        EMGsFreq;       % ...
        timeReadStep;   % ...
        blockData;      % ...
        bufData;        % ....

        data;           % ...
        dataEnv;
        dataNorm;       % ...
        propCmd = 0;    % ...

        % Parameters for data processing
        EMGchC = 1; % selected EMG control channel
        readWind = 0.08; % [s]
        bufWind = 0.24; % [s]
        filtersOrder = 3;
        freqNotch = [49 51];
        bNotch;
        aNotch;
        freqBandPass = [10 500];
        bBandPass;
        aBandPass;
    end

    methods (Access = public)

        %% Open socket
        function status = openSocket(obj)

            obj.t = tcpip('0.0.0.0', 45454, 'NetworkRole', 'server');
            obj.t.InputBufferSize = 500000;

            try
                fopen(obj.t);
            catch
                status = 0;
                errordlg(['Unable to connect to serialport device at port ' comPort]);
                return;
            end

            status = 1;
            disp('64+ connected');
            obj.timeReadStep = tic;

        end

        %% Configuration
        function configure(obj)

            % Create command
            command = obj.GO + obj.REC * 2 + obj.TRIG * 4 + obj.EXTEN * 16 + ...
                obj.HPF * 64 + obj.HRES * 128 + obj.MODE * 256 + obj.NCH * 2048 + obj.FSAMP * 8192;

            % Send command
            fwrite(obj.t, command, 'int16');

            % Get number of channels
            switch obj.NCH
                case 0
                    obj.nEMGchs = (obj.MODE == 1) * 12 + (obj.MODE ~= 1) * 16;
                case 1
                    obj.nEMGchs = (obj.MODE == 1) * 16 + (obj.MODE ~= 1) * 24;
                case 2
                    obj.nEMGchs = (obj.MODE == 1) * 24 + (obj.MODE ~= 1) * 40;
                case 3
                    obj.nEMGchs = (obj.MODE == 1) * 40 + (obj.MODE ~= 1) * 72;
                otherwise
                    disp('Wrong value for NCH');
                    obj.nEMGchs = 0;
            end

            % Get sampling frequency
            switch obj.FSAMP
                case 0
                    obj.EMGsFreq = (obj.MODE == 3) * 2000 + (obj.MODE ~= 3) * 500;
                case 1
                    obj.EMGsFreq = (obj.MODE == 3) * 4000 + (obj.MODE ~= 3) * 1000;
                case 2
                    obj.EMGsFreq = (obj.MODE == 3) * 8000 + (obj.MODE ~= 3) * 2000;
                case 3
                    obj.EMGsFreq = (obj.MODE == 3) * 16000 + (obj.MODE ~= 3) * 4000;
                otherwise
                    disp('Wrong value for FSAMP');
                    obj.EMGsFreq = 0;
            end

            % Block of data to acquire
            obj.blockData = 2 * obj.nEMGchs * obj.EMGsFreq * obj.readWind;

            % Create buffer for data acquisition
            obj.bufData = dsp.AsyncBuffer(obj.bufWind*obj.EMGsFreq); % buffer

            % Set filters
            [obj.bNotch,obj.aNotch] = butter(obj.filtersOrder,2*obj.freqNotch/obj.EMGsFreq,'stop');
            [obj.bBandPass,obj.aBandPass] = butter(obj.filtersOrder,2*obj.freqBandPass/obj.EMGsFreq,'bandpass');

        end

        %% Read data
        function receiveData(obj)

            while (obj.t.BytesAvailable < obj.blockData)
            end
            %pause(obj.readWind-toc(obj.timeReadStep))

            obj.data = fread(obj.t, [obj.nEMGchs, obj.EMGsFreq * obj.readWind], 'int16');

            obj.timeReadStep = tic;
        end

        %% Process data
        function processData(obj, paramsGUI)

            % Take only the selected channel
            obj.data = obj.data(obj.EMGchC,:)';

            % Conversion factor for the bioelectrical signals to get the values in mV
            obj.data = obj.data*obj.ConvFact;

            % Filter EMG
            obj.data = filtfilt(obj.bNotch,obj.aNotch,obj.data); % Notch at 50 Hz
            obj.data = filtfilt(obj.bBandPass,obj.aBandPass,obj.data); % Band-pass

            % Write data into buffer
            write(obj.bufData, obj.data);

            % Read data from buffer without changing the number of unread samples (peek)
            pointData = peek(obj.bufData);

            % Compute envelope using RMS
            obj.dataEnv = rms(pointData);

            % Normalize envenlope and raw data with respect to MVC
            obj.dataNorm = obj.data ./ paramsGUI.emgMVC;
            obj.propCmd = obj.dataEnv / paramsGUI.emgMVC;

        end

        %% Close socket
        function close(obj)
            pause(0.5);
            fclose(obj.t);
        end

    end
end