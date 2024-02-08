classdef sessantaquattroplus_handler
    methods(Static)
        function command = createCommand(FSAMP, NCH, MODE, HRES, HPF, EXTEN, TRIG, REC, GO)
            command = GO + REC * 2 + TRIG * 4 + EXTEN * 16 + HPF * 64 + HRES * 128 + MODE * 256 + NCH * 2048 + FSAMP * 8192;
        end
        
        function numChannels = getNumChannels(NCH, MODE)
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
        end
        
        function sampFreq = getSamplingFrequency(FSAMP, MODE)
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
        end
        
        function t = openSocket()
            t = tcpip('0.0.0.0', 45454, 'NetworkRole', 'server');
            t.InputBufferSize = 500000;
            fopen(t);
            disp('Connected to the Socket');
        end
        
        function data = receiveData(t, HRES, NumChannels, SampFreq)
            blockData = (HRES == 1) * 3 * NumChannels * SampFreq + (HRES == 0) * 2 * NumChannels * SampFreq;
            ChInd = (1:3:NumChannels * 3);
            data = cell(1, 10);
            for i = 1:10
                while (t.BytesAvailable < blockData)
                end
                Temp = fread(t, [NumChannels * (HRES + 1), SampFreq], 'uint8');
                data{i} = Temp(ChInd, :) * 65536 + Temp(ChInd + 1, :) * 256 + Temp(ChInd + 2, :);
                ind = find(data{i} >= 8388608);
                data{i}(ind) = data{i}(ind) - (16777216);
            end
        end
        
        function plotData(data, HRES, NumChannels, ConvFact)
            if (HRES == 1)
                for i = 1:10
                    subplot(2, 1, 1);
                    hold off;
                    for j = 1:4
                        plot(data{i}(j, :) * ConvFact + 0.1 * (j - 1));
                        hold on;
                    end
                    subplot(2, 1, 2);
                    plot(rem((data{i}(NumChannels - 1, :)), 16384) * 8);
                    drawnow;
                end
            else
                subplot(2, 1, 1);
                for i = 1:10
                    hold off;
                    for j = 1:NumChannels - 8
                        plot(data{i}(j, :) * ConvFact + 0.5 * (j - 1));
                        hold on;
                    end
                    subplot(2, 3, 4);
                    hold off;
                    for j = NumChannels - 7:NumChannels - 6
                        plot(data{i}(j, :));
                        hold on;
                    end
                    subplot(2, 3, 5);
                    hold off;
                    for j = NumChannels - 5:NumChannels - 2
                        plot(data{i}(j, :));
                        hold on;
                    end
                    subplot(2, 3, 6);
                    hold off;
                    for j = NumChannels - 1:NumChannels
                        plot(data{i}(j, :));
                        hold on;
                    end
                    drawnow;
                end
            end
        end
        
        function closeSocket(t)
            pause(0.5);
            clear("t");
        end
    end
end