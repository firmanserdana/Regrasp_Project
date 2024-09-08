classdef sessantaquattroplus_handler

    methods(Static)

        %% Open socket
        function t = openSocket()

            t = tcpip('0.0.0.0', 45454, 'NetworkRole', 'server');
            t.InputBufferSize = 500000;
            fopen(t);
            disp('64+ connected');

        end

        %% Configuration
        function [nEMGchs,EMGsFreq,blockData,bufData] = configure(t, vars)

            % Create command
            command = vars.GO + vars.REC * 2 + vars.TRIG * 4 + vars.EXTEN * 16 + ...
                vars.HPF * 64 + vars.HRES * 128 + vars.MODE * 256 + vars.NCH * 2048 + vars.FSAMP * 8192;

            % Send command
            fwrite(t, command, 'int16');

            % Get number of channels
            switch vars.NCH
                case 0
                    nEMGchs = (vars.MODE == 1) * 12 + (vars.MODE ~= 1) * 16;
                case 1
                    nEMGchs = (vars.MODE == 1) * 16 + (vars.MODE ~= 1) * 24;
                case 2
                    nEMGchs = (vars.MODE == 1) * 24 + (vars.MODE ~= 1) * 40;
                case 3
                    nEMGchs = (vars.MODE == 1) * 40 + (vars.MODE ~= 1) * 72;
                otherwise
                    disp('Wrong value for NCH');
                    nEMGchs = 0;
            end

            % Get sampling frequency
            switch vars.FSAMP
                case 0
                    EMGsFreq = (vars.MODE == 3) * 2000 + (vars.MODE ~= 3) * 500;
                case 1
                    EMGsFreq = (vars.MODE == 3) * 4000 + (vars.MODE ~= 3) * 1000;
                case 2
                    EMGsFreq = (vars.MODE == 3) * 8000 + (vars.MODE ~= 3) * 2000;
                case 3
                    EMGsFreq = (vars.MODE == 3) * 16000 + (vars.MODE ~= 3) * 4000;
                otherwise
                    disp('Wrong value for FSAMP');
                    EMGsFreq = 0;
            end
            
            % Block of data to acquire
            blockData = 2 * nEMGchs * EMGsFreq * vars.readWind;

            % Create buffer for data acquisition
            bufData = dsp.AsyncBuffer(vars.bufWind*EMGsFreq); % buffer

        end


        %% Read data
        function data = receiveData(t, blockData, vars, nEMGchs, EMGsFreq)

            while (t.BytesAvailable < blockData)
            end

            data = fread(t, [nEMGchs, EMGsFreq * vars.readWind], 'int16');
        end


        %% Process data
        function [propCmd, dataNorm] = processData(data, vars, varsGUI, bufData)

            % Take only the selected channel
            data = data(vars.EMGchC,:)';

            % Conversion factor for the bioelectrical signals to get the values in mV
            data = data*vars.ConvFact;
            
            % Filter EMG
            data = filtfilt(vars.bNotch,vars.aNotch,data); % Notch at 50 Hz
            data = filtfilt(vars.bBandPass,vars.aBandPass,data); % Band-pass 

            % Write data into buffer
            write(bufData, data);

            % Read data from buffer without changing the number of unread samples (peek)
            pointData = peek(bufData);

            % Compute envelope using RMS
            dataEnv = rms(pointData);

            % Normalize envenlope and raw data with respect to MVC
            dataNorm = data ./ varsGUI.emgMVC;
            propCmd = dataEnv / varsGUI.emgMVC;

        end


        %% Close socket
        function closeSocket(t)
            pause(0.5);
            fclose(t);
        end

    end
end