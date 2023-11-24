clear all

% Create a TCP server
t = tcpserver('0.0.0.0', 9000);

% Wait for a client to connect
while ~t.Connected
    pause(1);  % Adjust the delay as needed
end

% Load your time series .mat data
data = load('/Users/ffmacair/Documents/GitWorks/PhD/Rewire_Project/Matlab_simulate_tcpserver/S1_A1_E1.mat');

% Extract the data variable (modify as needed)
timeSeriesData = data.emg(:, 1);  % replace with your actual data variable, selecting only the first column

% Calculate the sampling rate
samplingRate = 2000; % 2kHz

% Calculate the timestamp based on the number of samples and the sampling rate
numSamples = numel(timeSeriesData);
timestamp = (0:numSamples-1) / samplingRate;

try
    for i = 1:numSamples
        % Pack the variables into a structure for streaming
        streamData.timestamp = timestamp(i);
        streamData.timeSeriesData = timeSeriesData(i);
        
        % Convert the structure to a byte stream
        byteStream = getByteStreamFromArray(streamData.timeSeriesData);
        
        % Send the byte stream over the TCP connection
        t.write(streamData.timeSeriesData,'double');
        % Convert the byte stream to a string for printing
        byteStreamString = char(byteStream);

        % Print the byte stream to the console
        disp(streamData.timeSeriesData);

        % Optionally, you can add a delay to control the streaming rate
        pause(0.0005);  % Adjust the delay as needed
    end
catch ME
    % If an error occurs, display the error message and stop the server
    disp('An error occurred while streaming data:');
    disp(ME.message);
    clear t;
end