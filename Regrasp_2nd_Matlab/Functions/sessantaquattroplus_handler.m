classdef sessantaquattroplus_handler
    methods(Static)

        %% Open socket
        function t = openSocket()

            t = tcpip('0.0.0.0', 45454, 'NetworkRole', 'server');
            t.InputBufferSize = 500000;
            fopen(t);
            disp('Connected to the Socket');

        end

        %% Configuration
        function [numChannels,sampFreq,bufData] = configure(t, GO, REC, TRIG, EXTEN, HPF, HRES, MODE, NCH, FSAMP, bufWind)

            % Create command
            command = GO + REC * 2 + TRIG * 4 + EXTEN * 16 + HPF * 64 + HRES * 128 + MODE * 256 + NCH * 2048 + FSAMP * 8192;

            % Send command
            fwrite(t, command, 'int16');

            % Get number of channels
            switch NCH
                case 0
                    numChannels = (MODE == 1) * 12 + (MODE ~= 1) * 16;
                case 1
                    numChannels = (MODE == 1) * 16 + (MODE ~= 1) * 24;
                case 2
                    numChannels = (MODE == 1) * 24 + (MODE ~= 1) * 40;
                case 3
                    numChannels = (MODE == 1) * 40 + (MODE ~= 1) * 72;
                otherwise
                    disp('Wrong value for NCH');
                    numChannels = 0;
            end

            % Get sampling frequency
            switch FSAMP
                case 0
                    sampFreq = (MODE == 3) * 2000 + (MODE ~= 3) * 500;
                case 1
                    sampFreq = (MODE == 3) * 4000 + (MODE ~= 3) * 1000;
                case 2
                    sampFreq = (MODE == 3) * 8000 + (MODE ~= 3) * 2000;
                case 3
                    sampFreq = (MODE == 3) * 16000 + (MODE ~= 3) * 4000;
                otherwise
                    disp('Wrong value for FSAMP');
                    sampFreq = 0;
            end
            
            % Create buffer for data acquisition
            bufData = dsp.AsyncBuffer(bufWind*sampFreq); % buffer

        end

        %% Receive data
        function data = receiveData(t, HRES, NumChannels, SampFreq, readWind)

            blockData = (HRES == 1) * 3 * NumChannels * SampFreq * readWind + (HRES == 0) * 2 * NumChannels * SampFreq * readWind;
            ChInd = (1:3:NumChannels * 3);

            while (t.BytesAvailable < blockData)
            end

            Temp = fread(t, [NumChannels * 3, SampFreq*readWind], 'uint8');
            data = Temp(ChInd, :) * 65536 + Temp(ChInd + 1, :) * 256 + Temp(ChInd + 2, :);
            ind = find(data >= 8388608);
            data(ind) = data(ind) - (16777216);

            %data = fread(t, [NumChannels * (HRES + 1), SampFreq*readWind], 'int16');
        end

        %% Process data
        function [dataNorm,dataEnv] = processData(data,MVC,chX, bufData)

            % Take only the selected channel 
            data = data(chX,:)';
            
            % Conversion factor for the bioelectrical signals to get the values in mV
            ConvFact = 0.000286;
            data = data*ConvFact;

            % Write data into buffer
            write(bufData, data);

            % Read data from buffer without changing the number of unread samples (peek)
            pointData = peek(bufData);

            % Compute envelope using RMS
            dataEnv = rms(pointData);

            % Normalize envenlope and raw data with respect to MVC
            dataNorm = data ./ MVC;
            dataEnv = dataEnv / MVC;

        end

        %% Close socket
        function closeSocket(t)
            pause(0.5);
            clear("t");
        end

    end
end