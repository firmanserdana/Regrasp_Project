%% Load data

root = "C:\Users\vamendez\Desktop\TMP_Recent\Florence\data\raw_data";

%% Sub 1 agcl
% add1 = root + "\sub1\agcl\fulldata_1702304055.h5";
% add2 = root + "\sub1\agcl\fulldata_1702304602.h5";
% add3 = root + "\sub1\agcl\fulldata_1702305149.h5";
% add4 = root + "\sub1\agcl\fulldata_1702305773.h5";

% % Sub 1 MXene
% add1 = root + "\sub1\MXene\fulldata_1702307277.h5";
% add2 = root + "\sub1\MXene\fulldata_1702307780.h5";
% add3 = root + "\sub1\MXene\fulldata_1702308207.h5";
% add4 = root + "\sub1\MXene\fulldata_1702308513.h5";
% 
% % Sub 2 agcl
% add1 = root + "\sub2\agcl\fulldata_1702379303.h5";
% add2 = root + "\sub2\agcl\fulldata_1702379637.h5";
% add3 = root + "\sub2\agcl\fulldata_1702379925.h5";
% add4 = root + "\sub2\agcl\fulldata_1702380201.h5";
% 
% % Sub 2 MXene
% add1 = root + "\sub2\MXene\fulldata_1702377374.h5";
% add2 = root + "\sub2\MXene\fulldata_1702377687.h5";
% add3 = root + "\sub2\MXene\fulldata_1702377979.h5";
% add4 = root + "\sub2\MXene\fulldata_1702378265.h5";
% 
% % Sub 3 agcl
% add1 = root + "\sub3\agcl\fulldata_1702390287.h5";
% add2 = root + "\sub3\agcl\fulldata_1702390548.h5";
% add3 = root + "\sub3\agcl\fulldata_1702390839.h5";
% add4 = root + "\sub3\agcl\fulldata_1702391094.h5";
% add5 = root + "\sub3\agcl\fulldata_1702391379.h5";
% 
% 
% % Sub 4 MXene
add1 = root + "\sub4\MXene\fulldata_1702464151.h5";
add2 = root + "\sub4\MXene\fulldata_1702464422.h5";
add3 = root + "\sub4\MXene\fulldata_1702464696.h5";
add4 = root + "\sub4\MXene\fulldata_1702464959.h5";
% 
% Sub 4 agcl
% add1 = root + "\sub4\agcl\fulldata_1702462052.h5";
% add2 = root + "\sub4\agcl\fulldata_1702462330.h5";
% add3 = root + "\sub4\agcl\fulldata_1702462603.h5";
% add4 = root + "\sub4\agcl\fulldata_1702462922.h5";

%% some parameters
fs = 2400;  % Desired sampling frequency
f0 = 50;    % Frequency to be removed
Q = 35;     % Quality factor
window_length_ms = 200;  % Window length in milliseconds
step_size_ms = 10;       % Step size in milliseconds
%%
% File paths
filePaths = {add1,add2,add3,add4}; %,add5};

% Initialize arrays or cell arrays
% t_vr_all = [];
% d_vr_all = [];
% t_emg_all = [];
% d_emg_all = [];
% d_finger_all = [];
% t_finger_all = [];

% Loop over each file

% Preallocate arrays to store EMG windows and labels
EMG_windows = {};
labels = [];

% Training set
XTrain = [];
YTrain = [];

% Validation set
XValidation = [];
YValidation = [];

% Test set
XTest = [];
YTest = [];


for i = 1:length(filePaths)
    % Load data from each file
    t_vr = h5read(filePaths{i}, '/timestamp_vr_events');
    d_vr = h5read(filePaths{i}, '/vr_events')';
    t_emg = h5read(filePaths{i}, '/timestamp_HA-2015.08.05');
    d_emg = h5read(filePaths{i}, '/HA-2015.08.05')';
    %d_finger = h5read(filePaths{i}, '/finger_angles')';
    %t_finger = h5read(filePaths{i}, '/timestamp_finger_angles');

%     % Concatenate data
%     t_vr_all = [t_vr_all; t_vr];
%     d_vr_all = [d_vr_all; d_vr];
%     t_emg_all = [t_emg_all; t_emg];
%     d_emg_all = [d_emg_all; d_emg];
%     d_finger_all = [d_finger_all; d_finger];
%     t_finger_all = [t_finger_all; t_finger];
% end

% Now all the *_all variables contain concatenated data from all files


    %% Notch Filter data
    % Original timestamps and data
    original_timestamps = t_emg; % Assuming this is your timestamps vector
    EMGdata = d_emg; % Replace with your actual EMG data variable

    % Create a new time vector with uniform spacing
    t_start = original_timestamps(1);
    t_end = original_timestamps(end);
    uniform_timestamps = linspace(t_start, t_end, round((t_end - t_start) * fs));

    % Identify unique timestamps and their indices
    [unique_timestamps, ia, ~] = unique(original_timestamps, 'stable');
    unique_EMGdata = EMGdata(ia, :);

    % Interpolate the data to the new uniform timestamps
    uniform_EMGdata = interp1(unique_timestamps, unique_EMGdata, uniform_timestamps, 'linear');

    % Calculate the number of harmonics
    num_harmonics = floor((fs/2) / f0) - 1;

    % Apply the notch filter for each harmonic
    for k = 1:num_harmonics
        [b, a] = iirnotch(k*f0/(fs/2), k*f0/(fs/2)/Q);
        for j = 1:size(uniform_EMGdata, 2)
            uniform_EMGdata(:, j) = filter(b, a, uniform_EMGdata(:, j));
        end
    end

    % The filtered data is now in 'uniform_EMGdata', aligned with 'uniform_timestamps'


    %% bandpass filter 15-450Hz
    low_cutoff = 15;  % Low frequency cutoff for bandpass filter (15 Hz)
    high_cutoff = 450; % High frequency cutoff for bandpass filter (450 Hz)

    % Design a bandpass Butterworth filter
    bpFilt = designfilt('bandpassiir', ...
                        'FilterOrder', 4, ...
                        'HalfPowerFrequency1', low_cutoff, ...
                        'HalfPowerFrequency2', high_cutoff, ...
                        'SampleRate', fs);

    % Apply the filter to the data
    filtered_EMGdata = filter(bpFilt, uniform_EMGdata);

    % The filtered data is now in 'filtered_EMGdata'

    % Rectify the signal
    rectified_EMGdata = abs(filtered_EMGdata);

    % Design a low-pass filter
    lpFilt = designfilt('lowpassiir', 'FilterOrder', 4, ...
                        'HalfPowerFrequency', 10, 'SampleRate', fs);

    % Apply the low-pass filter to the rectified data
    envelope_EMGdata = filter(lpFilt, rectified_EMGdata);
       
    % The envelope of the EMG data is now in 'envelope_EMGdata'

    %% Plot a random channel
    figure;
    plot(original_timestamps,EMGdata(:,10))
    hold on
    plot(uniform_timestamps,filtered_EMGdata(:,10))
    plot(uniform_timestamps,envelope_EMGdata(:,10))
    plot(t_vr,zeros(length(t_vr),1),'o')
    
    clear envelope_EMGdata
    clear rectified_EMGdata
    clear filtered_EMGdata
    clear uniform_EMGdata
    clear unique_EMGdata
    clear EMGdata
    clear d_emg
    
    %% Sliding Window + label extraction

    % Convert window length and step size to samples
    window_length_samples = round(window_length_ms * (fs / 1000));
    step_size_samples = round(step_size_ms * (fs / 1000));

    % Find indices for hold_start and hold_end events
    hold_start_indices = find(strcmp(d_vr, 'hold_start'));
    hold_end_indices = find(strcmp(d_vr, 'hold_end'));
    
    % Initialize event counter
    event_counter = 0;

    % Loop through each pair of hold_start and hold_end
    for i = 1:length(hold_start_indices)
        start_time = t_vr(hold_start_indices(i));
        end_time = t_vr(hold_end_indices(i));

        % Find corresponding indices in EMG data timestamps
        start_index = find(uniform_timestamps >= start_time, 1, 'first');
        end_index = find(uniform_timestamps <= end_time, 1, 'last');

        % Generate sliding windows
        for j = start_index:step_size_samples:(end_index - window_length_samples + 1)
            window_data = envelope_EMGdata(j:(j + window_length_samples - 1), :);
            EMG_windows{end+1} = window_data;
            labels(end+1) = event_counter;  % Assign label corresponding to the event counter
        end

        % Increment and reset event counter if needed
        event_counter = mod(event_counter + 1, 5);
    end


    %% data prep

    % Assuming EMG_windows is a cell array of matrices and labels is a vector of labels

    % Convert data to a 4D array (required for CNN in MATLAB)
    numSamples = numel(EMG_windows);
    numChannels = size(EMG_windows{1}, 2);  % Number of channels in EMG data
    dataHeight = size(EMG_windows{1}, 1);   % Window length in samples

    % Preallocate array
    allData = zeros(dataHeight, numChannels, 1, numSamples);

    % Populate the array
    for i = 1:numSamples
        allData(:, :, 1, i) = EMG_windows{i};
    end

    % Convert labels to categorical
    allLabels = categorical(labels);

    % Number of total samples
    numSamples = numel(EMG_windows);

    % Calculate indices for splitting
    numTrain = floor(0.6 * numSamples);
    numValidation = floor(0.2 * numSamples);
    % The remaining for testing
    % Note: Due to rounding, the final split might slightly deviate from exact

    % Training set
    XTrain = cat(4,XTrain,allData(:, :, :, 1:numTrain));
    YTrain = cat(2,YTrain,allLabels(1:numTrain));

    % Validation set
    XValidation = cat(4,XValidation,allData(:, :, :, (numTrain+1):(numTrain+numValidation)));
    YValidation = cat(2,YValidation,allLabels((numTrain+1):(numTrain+numValidation)));

    % Test set
    XTest = cat(4,XTest, allData(:, :, :, (numTrain+numValidation+1):end));
    YTest = cat(2,YTest, allLabels((numTrain+numValidation+1):end));

end
%% model definition

layers = [
    imageInputLayer([dataHeight, numChannels, 1])

    convolution2dLayer([3, 3], 16, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer([2, 2], 'Stride', 2)

    convolution2dLayer([3, 3], 32, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer([2, 2], 'Stride', 2)

    fullyConnectedLayer(32)
    reluLayer

    fullyConnectedLayer(5)  % 5 classes
    softmaxLayer
    classificationLayer];

%% training

options = trainingOptions('sgdm', ...
    'InitialLearnRate', 0.01, ...
    'MaxEpochs', 30, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {XValidation, YValidation}, ...
    'ValidationFrequency', 30, ...
    'Verbose', false, ...
    'Plots', 'training-progress');

net = trainNetwork(XTrain, YTrain, layers, options);

%% 
YPred = classify(net, XTest);
accuracy = sum(YPred' == YTest) / numel(YTest);
disp(['Test Accuracy: ', num2str(accuracy)]);

