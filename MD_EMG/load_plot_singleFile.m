clear all
close all
clc


%% Load data change subject (sub1-7) and matrixmetal (MXene/agcl) depending on which data you want to look at.
root = "/home/firep1/Documents/gitworks/phd/raw_data";
subject = "sub7";
matrixmetal = "agcl";

folderPath = root + "/" + subject + "/" + matrixmetal;

files = dir(fullfile(folderPath, '*.h5'));

for fileIdx = 1:length(files)
    filePath = fullfile(folderPath, files(fileIdx).name);
%% Parameters
fs = 2400;  % Desired sampling frequency
f0 = 50;    % Frequency to be removede
Q = 35;     % Quality factor
window_length_ms = 200;  % Window length in milliseconds
step_size_ms = 10;       % Step size in milliseconds


%% Load data from the file
t_vr = h5read(filePath, '/timestamp_vr_events');
d_vr = h5read(filePath, '/vr_events')';
t_emg = h5read(filePath, '/timestamp_HA-2015.08.05');
d_emg = h5read(filePath, '/HA-2015.08.05')';


%% Resample the data
% Original timestamps and data
original_timestamps = t_emg; % Assuming this is your timestamps vector
EMGdata = double(d_emg); % Replace with your actual EMG data variable

% Create a new time vector with uniform spacing
t_start = original_timestamps(1);
t_end = original_timestamps(end);
uniform_timestamps = linspace(t_start, t_end, round((t_end - t_start) * fs));

% Identify unique timestamps and their indices
[unique_timestamps, ia, ~] = unique(original_timestamps, 'stable');
unique_EMGdata = EMGdata(ia, :);

% Interpolate the data to the new uniform timestamps
uniform_EMGdata = interp1(unique_timestamps, unique_EMGdata, uniform_timestamps, 'linear');


%% Notch Filter data
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


%% Compute the envelope
% Rectify the signal
rectified_EMGdata = abs(filtered_EMGdata);

% Design a low-pass filter
lpFilt = designfilt('lowpassiir', 'FilterOrder', 4, ...
    'HalfPowerFrequency', 10, 'SampleRate', fs);

% Apply the low-pass filter to the rectified data
envelope_EMGdata = filter(lpFilt, rectified_EMGdata);

% The envelope of the EMG data is now in 'envelope_EMGdata'


%% Find the unique events
d_vr = cellstr(d_vr);
d_vr_unique = unique(d_vr);


%% Plot all the data with the events
figure(1);
hold on

% Plot EMG
for ich = 1:size(EMGdata,2)
    plot(uniform_timestamps-uniform_timestamps(1),ich+filtered_EMGdata(:,ich)./max(abs(filtered_EMGdata(:,ich))),'color',[0.7 0.7 0.7])
    plot(uniform_timestamps-uniform_timestamps(1),ich+envelope_EMGdata(:,ich)./max(abs(filtered_EMGdata(:,ich))),'k','linewidth',1)

end

% Plot events
colors_event = hsv(length(d_vr_unique));
l = [];
for id = 1:length(d_vr_unique)
    tt = t_vr(find(strcmp(d_vr,d_vr_unique{id})));
    for ii= 1:length(tt)
        l(id) = plot([tt(ii) tt(ii)]-uniform_timestamps(1),[0 size(EMGdata,2)+1],'color',colors_event(id,:),'linewidth',1);
    end
end

legend(l,d_vr_unique,'Interpreter','none');
xlim([0 uniform_timestamps(end)-uniform_timestamps(1)])
ylim([0 size(EMGdata,2)+1])
xlabel('time [s]');
ylabel('EMG channel');
set(gca,'fontsize',12,'Ytick',1:size(EMGdata,2),'Ytick',0:size(EMGdata,2))
hold off

% Define the trial start events
trial_start_events = {'trial_start lateralPinch', 'trial_start sphericalGrasp', 'trial_start pinchGrasp', 'trial_start handOpening', 'trial_start indexPointing'};

% Initialize a cell array to store segmented EMG signals
segmented_EMG = cell(length(trial_start_events), 3); % 3 for the number of repetitions


%% Segment and pool EMG signals based on the events
for id = 1:length(trial_start_events)
    % Get the timestamps for the current trial start event : changes + x based on which event you want to look at
    % Initialize a logical array of the same size as d_vr with all false
    match_indices_start = false(size(d_vr));
    match_indices_end = false(size(d_vr));
    for ii = 1:length(d_vr) - 2
        if strcmp(d_vr{ii}, trial_start_events{id})
            % If a match is found, set the element at index +2 to true
            match_indices_start(ii+3) = true;
            match_indices_end(ii+4) = true;
        end
    end

    % Extract the timestamps that correspond to the true indices in match_indices
    tt_start = t_vr(match_indices_start);
    tt_end = t_vr(match_indices_end);
    % Calculate the number of repetitions
    num_repetitions = length(tt_start);
    
    for ii = 1:num_repetitions
        % Determine which repetition the current index belongs to
        rep = mod(ii-1, 3) + 1;
        
        % Find the corresponding indices in the uniform_timestamps vector
        start_idx = find(uniform_timestamps >= tt_start(ii), 1);
        end_idx = find(uniform_timestamps >= tt_end(ii), 1);
        
        % Segment the EMG data
        segment = envelope_EMGdata(start_idx:end_idx, :);
        
        % Pool the segmented EMG data for each repetition
        if isempty(segmented_EMG{id, rep})
            segmented_EMG{id, rep} = segment;
        else
            segmented_EMG{id, rep} = [segmented_EMG{id, rep}; segment];
        end
    end
end

% Initialize arrays to store the first and second PC
principal_components = cell(length(trial_start_events), 3);

% Use different markers or colors for each gesture
markers = {'o', 's', 'd', '^', 'p'};

% Calculate the first and second PC for each gesture
for id = 1:size(segmented_EMG, 1)
    for rep = 1:size(segmented_EMG, 2)
        % Perform PCA on the segmented EMG data
        [coeff,score] = pca(segmented_EMG{id,rep}, 'NumComponents', 3);
        % Extract the first and second PC
        principal_components{id,rep} = score; 
    end
end

% Downsample the principal components for better clarity
downsample_factor = 50;

for id = 1:size(principal_components, 1)
    for rep = 1:size(principal_components, 2)
        pc = principal_components{id, rep};
        downsampled_pc = pc(1:downsample_factor:end, :);
        principal_components{id, rep} = downsampled_pc;
    end
end


% Plot the first three principal components with respect to time using subplots for each gesture
figure(2);

for pc = 1:3
    subplot(3, 1, pc);
    hold on
    for id = 1:size(principal_components, 1)
        for rep = 1:size(principal_components, 2)
            pc_data = principal_components{id, rep};
            tt = (1:size(pc_data, 1)) * downsample_factor; % Calculate time based on downsample factor
            plot(tt, pc_data(:, pc), 'LineWidth', 2); % Plot principal component against time with lines
        end
    end
    hold off
    legend(trial_start_events, 'Interpreter', 'none');
    xlabel('Time');
    ylabel(['Principal Component ', num2str(pc)]);
    title(['Plot of Principal Component ', num2str(pc), ' with Respect to Time']);
end

% Cut the size for each cell in segmented_EMG data into the shortest cell size
min_cell_size = min(cellfun(@(x) size(x, 1), segmented_EMG(:)));
segmented_EMG = cellfun(@(x) x(1:min_cell_size, :), segmented_EMG, 'UniformOutput', false);

num_gestures = size(segmented_EMG, 1);
num_repetitions = size(segmented_EMG, 2);
num_samples = size(segmented_EMG{1, 1}, 1);
num_channels = size(segmented_EMG{1, 1}, 2);

% Reshape the segmented_EMG data into a 2D array
reshaped_array = zeros(num_gestures * num_repetitions, num_channels * num_samples);

for id = 1:num_gestures
    for rep = 1:num_repetitions
        % Calculate the start and end indices for the current gesture and repetition
        start_idx = (id - 1) * num_repetitions + rep;
        end_idx = start_idx;
        
        % Reshape the current gesture and repetition into a 1D array
        reshaped_array(start_idx, :) = reshape(segmented_EMG{id, rep}, 1, []);
    end
end


% Calculate the first three principal components of the reshaped array
[coeff, score] = pca(reshaped_array, 'NumComponents', 3);

% Scatter plot the first three principal components with markers for each repetition
figure(3);
hold on;
scatter_handles = cell(size(segmented_EMG, 1), 1);  % To store scatter handles for legend

for id = 1:size(segmented_EMG, 1)
    for rep = 1:size(segmented_EMG, 2)
        pc = score((id - 1) * num_repetitions + rep, :);
        marker = markers{mod(id - 1, length(markers)) + 1};
        color = colors_event(id, :);
        scatter_handles{id} = scatter3(pc(1), pc(2), pc(3), marker, 'filled', 'MarkerFaceColor', color);
    end
end
hold off;

xlabel('Principal Component 1');
ylabel('Principal Component 2');
zlabel('Principal Component 3');
title('Scatter Plot of First Three Principal Components');

% Create legend
legend([scatter_handles{:}], trial_start_events, 'Interpreter', 'none');

end