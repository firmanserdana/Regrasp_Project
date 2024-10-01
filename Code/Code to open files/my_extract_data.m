clear all
close all
clc

addpath(genpath('C:\Program Files (x86)\Ripple\Trellis\Tools'))

%
stimEN = 1;
emgEN = 0;
pressureEN = 0;

%
dataFolder = 'C:\Users\firmansssa\Desktop\Elena\Code Regrap\Final code\Characterization\';
fileName = '2024-09-25-16-58-47-rec3';


%%
[ns_status, hFile] = ns_OpenFile([dataFolder fileName]);


%% Extract stim
if stimEN
    labels = {hFile.Entity.Label};
    idxEmpty = find(cellfun(@isempty,labels));
    for iL = 1:length(idxEmpty)
        labels{idxEmpty(iL)} = 'empty';
    end
    idxNotChar = find(cellfun(@ischar,labels)==0);
    for iL = 1:length(idxNotChar)
        labels{idxNotChar(iL)} = 'empty';
    end
    stimChs = [hFile.Entity(find(contains(labels,'stim'))).ElectrodeID] - 5120;

    for ich = 1:length(stimChs)

        stimCh = stimChs(ich);

        % ...
        entityID = find([hFile.Entity(:).ElectrodeID] == stimCh + 5120);

        if isempty(entityID)
            continue;
        end

        % Extract channel info
        [ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, entityID(end));     % analog info contains things like range and sampling rate

        % work through it backwards to setup variables first
        for i = hFile.Entity(entityID).Count:-1:1
            [ns_RESULT, TimeStamp(i), Data(i,:), SampleCount] = ns_GetSegmentData(hFile, entityID, i);
            if i == hFile.Entity(entityID).Count
                timeStim_perCh{ich} = 0:1/3e4:TimeStamp(hFile.Entity(entityID).Count)+51/3e4;
                lengthStim(ich) = length(timeStim_perCh{ich});
                stimData_perCh{ich} = zeros(size(timeStim_perCh{ich}));
            end
            Ts = find(timeStim_perCh{ich} < TimeStamp(i),1,'last');
            stimData_perCh{ich}(Ts+1:Ts+52) = Data(i,:);
        end
    end

    % ...
    [maxLength,idxMax] = max(lengthStim);

    timeStim = timeStim_perCh{idxMax};
    stimData = zeros(length(stimChs),maxLength);

    for ich = 1:length(stimChs)

        stimData(ich,1:length(stimData_perCh{ich})) = stimData_perCh{ich};
    end
end


%% Extract EMG
if emgEN

    % ....
    nf3Idx = find(contains({hFile.FileInfo.Type},'nf3'));
    EMGchs = double(hFile.FileInfo(nf3Idx).ElectrodeList);

    for ich = 1:length(EMGchs)

        EMGch = EMGchs(ich);

        % ...
        EntityIndices = find([hFile.Entity(:).ElectrodeID] == EMGch);

        for i = 1:length(EntityIndices)

            fileTypeNum = hFile.Entity(EntityIndices(i)).FileType;
            fileType = hFile.FileInfo(fileTypeNum).Type;
            if strcmp('nf3', fileType);
                entityID = EntityIndices(i);
            end
        end

        % ...
        [ns_RESULT, analogInfo] = ns_GetAnalogInfo(hFile, entityID(end));     % analog info contains things like range and sampling rate

        % Timestamps
        if ich == 1
            EMGtimeStamps = hFile.FileInfo(hFile.Entity(entityID).FileType).TimeStamps;
            numSamples = sum(EMGtimeStamps(:,end));
            timeEMG_s = (0:numSamples-1)' ./ analogInfo.SampleRate;
        end

        % EMG data
        EMGData_uV(ich,:) = zeros(1,numSamples);
        startIndex = 1;
        indexCount = EMGtimeStamps(2,1);
        for i = 1:size(EMGtimeStamps,2)
            [~, ~, tempData] = ns_GetAnalogData(hFile, entityID, startIndex, indexCount);
            dataRange = EMGtimeStamps(1,i) + (1:EMGtimeStamps(2,i));
            EMGData_uV(ich,dataRange) = tempData';
            clear tempData
            if i ~= size(EMGtimeStamps,2)
                startIndex = startIndex + EMGtimeStamps(2,i);
                indexCount = EMGtimeStamps(2,i+1);
            end
        end
    end
end


%% Extract pressure
if pressureEN

    entityID = find(cellfun(@strcmpi, {hFile.Entity.Reason},...
        repmat({'Parallel Input'}, size({hFile.Entity.Reason}))));

    [ns_RESULT, entityInfo] = ns_GetEntityInfo(hFile, entityID(end));

    % Get events and time stamps
    numCount = entityInfo.ItemCount;
    pressureData = NaN(1, numCount); pressureTimeStamps = NaN(1, numCount); sz = NaN(1, numCount);
    for i = 1:numCount
        [~, pressureTimeStamps(i), pressureData(i), dataSize(i)] = ns_GetEventData(hFile, entityID, i);
    end
end


%% Plot
figure;

% EMG
ax(1) = subplot(3,1,1);
hold on;

if emgEN
    colorMuscles = hsv(length(EMGchs));

    for ich = 1:length(EMGchs)

        plot(timeEMG_s,ich - 1 + EMGData_uV(ich,:)/max(abs(EMGData_uV(ich,:))),'color',colorMuscles(ich,:));

    end

    xlim([timeEMG_s(1) timeEMG_s(end)])
    ylim([-1 length(EMGchs)])
    ylabel (['EMG ch']);
    set(gca,'Ytick',0:length(EMGchs)-1,'YtickLabel',1:length(EMGchs),'fontsize',15)
end

% Pressure
ax(2) = subplot(3,1,2);
hold on;

if pressureEN

    plot(pressureTimeStamps,pressureData,'k');

    ylabel('Pressure [V]');
    set(gca,'fontsize',15);
end

% Stim
ax(3) = subplot(3,1,3);
hold on;

colorStim = jet(length(stimChs));

for ich = 1:length(stimChs)

    plot(timeStim,ich - 1 + stimData(ich,:)/max(abs(stimData(ich,:))),'color',colorStim(ich,:));

end

ylim([-1 length(stimChs)])
xlabel('Time (s)');
ylabel (['Stim ch']);
set(gca,'Ytick',0:length(stimChs)-1,'YtickLabel',stimChs,'fontsize',15)

linkaxes(ax,'x');
