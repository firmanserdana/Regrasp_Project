% Function to create the command based on input parameters
function command = createCommand(FSAMP, NCH, MODE, HRES, HPF, EXTEN, TRIG, REC, GO)
    command = GO + REC * 2 + TRIG * 4 + EXTEN * 16 + HPF * 64 + HRES * 128 + MODE * 256 + NCH * 2048 + FSAMP * 8192;
end

% Function to get the number of channels based on NCH and MODE
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

% Function to get the sampling frequency based on FSAMP and MODE
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

% Function to open the TCP socket
function t = openSocket()
    if verLessThan('matlab', '9.12')
        t = tcpip('0.0.0.0', 45454, 'NetworkRole', 'server');
        t.InputBufferSize = 500000;
        fopen(t);
    else
        t = tcpserver(45454, "ByteOrder", "big-endian");
        t.InputBufferSize = 500000;
        fopen(t);
        while (t.Connected < 1)
            pause(0.1);
        end
    end
    disp('Connected to the Socket');
end

% Function to receive data based on resolution mode
function data = receiveData(t, NumChan, sampFreq, HRES)
    blockData = (HRES == 1) * 3 * NumChan * sampFreq + (HRES == 0) * 2 * NumChan * sampFreq;
    ChInd = (1:3:NumChan * 3);
    data = cell(1, 10); % Assuming NumCycle is 10
    for i = 1:10
        while (t.BytesAvailable < blockData)
        end
        Temp = fread(t, [NumChan * (HRES + 1), sampFreq], 'uint8');
        data{i} = Temp(ChInd, :) * 65536 + Temp(ChInd + 1, :) * 256 + Temp(ChInd + 2, :);
        ind = find(data{i} >= 8388608);
        data{i}(ind) = data{i}(ind) - (16777216);
    end
end

% Function to plot the data based on resolution mode
function plotData(data, NumChan, ConvFact, HRES)
    if (HRES == 1)
        for i = 1:10
            subplot(2, 1, 1);
            hold off;
            for j = 1:4
                plot(data{i}(j, :) * ConvFact + 0.1 * (j - 1));
                hold on;
            end
            subplot(2, 1, 2);
            plot(rem((data{i}(NumChan - 1, :)), 16384) * 8);
            drawnow;
        end
    else
        subplot(2, 1, 1);
        for i = 1:10
            hold off;
            for j = 1:NumChan - 8
                plot(data{i}(j, :) * ConvFact + 0.5 * (j - 1));
                hold on;
            end
            subplot(2, 3, 4);
            hold off;
            for j = NumChan - 7:NumChan - 6
                plot(data{i}(j, :));
                hold on;
            end
            subplot(2, 3, 5);
            hold off;
            for j = NumChan - 5:NumChan - 2
                plot(data{i}(j, :));
                hold on;
            end
            subplot(2, 3, 6);
            hold off;
            for j = NumChan - 1:NumChan
                plot(data{i}(j, :));
                hold on;
            end
            drawnow;
        end
    end
end

% Function to close the TCP socket
function closeSocket(t)
    pause(0.5);
    clear("t");
end