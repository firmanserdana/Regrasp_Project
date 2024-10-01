clear all
close all
clc

dataFolder = 'C:\Users\firmansssa\Desktop\Elena\Code Regrap\Final code\Control\Control v2\';
fileName = '2024-09-26-19-26-43-rec26';


%% Read parameters
fid = fopen([dataFolder fileName '-params.txt']);
txt = textscan(fid,'%s','delimiter','\n');
txt = txt{1};
fclose(fid);

% Control parameters
idx = find(contains(txt,'propThr'));
control_params_name = split(txt{idx},',')';
control_params = split(txt{idx+1},',')';

% Mod type
idx = find(contains(txt,'modType')) + 1;
modType = txt{idx};

% Stim parameters
idx_start = find(contains(txt,'Gesture'));
idx_end = find(contains(txt,'timeStart')) - 1;
stim_params_name = split(txt{idx_start},',')';
stim_params = {};
for i = 1:idx_end-idx_start
    stim_params(i,:) = split(txt{i+idx_start},',')';
end


%% Read states
stateTable = readtable([dataFolder fileName '-state.txt']);
states = unique(stateTable.state);

startStates = {};
startStates_time = [];

for is = 1:length(states)
    idx = find(strcmp(stateTable.state,states{is}));

    idx_start = [idx(1) ; idx(find(diff(idx)~=1)+1)];
    
    startStates(end+1:end+length(idx_start)) = stateTable.state(idx_start);
    startStates_time(end+1:end+length(idx_start)) = stateTable.time(idx_start);
end


%% Read data
dataTable = readtable([dataFolder fileName '.txt'],'NumHeaderLines',2);


%% Plot
figure;

% Binary signal
ax(1) = subplot(3,1,1);
hold on;

plot(dataTable.time,dataTable.binSig,'k');

for is = 1:length(startStates)
    plot([startStates_time(is) startStates_time(is)],[0 1],'k:');
    t = text(startStates_time(is),0,startStates{is},'HorizontalAlignment','left');
    set(t,'Rotation',90);
end

ylim([0 1]);
ylabel('Binary cmd [a.u.]');
set(gca,'fontsize',10);

% Proportional signal
ax(2) = subplot(3,1,2);
hold on;

plot(dataTable.time,dataTable.propCmd,'k');

ylim([0 1]);
ylabel('Prop cmd [a.u.]');
set(gca,'fontsize',10);

% Stim parameter
ax(3) = subplot(3,1,3);
hold on;

chs = unique(dataTable.stimCh);
colorChs = jet(length(chs));

if strcmp(modType,'AM')
    for ich = 1:length(chs)
        idx_ch = find([dataTable.stimCh]==chs(ich));
        plot(dataTable.time(idx_ch),dataTable.stimAmp(idx_ch),'color',colorChs(ich,:));
    end
    ylim([0 max(dataTable.stimAmp)]);
    ylabel('Stim amp [uA]');
elseif strcmp(modType,'FM')
    for ich = 1:length(chs)
        idx_ch = find([dataTable.stimCh]==chs(ich));
        plot(dataTable.time(idx_ch),dataTable.stimFreq(idx_ch),'color',colorChs(ich,:));
    end
    ylim([0 max(dataTable.stimFreq)]);
    ylabel('Stim freq [Hz]');
end

xlim([dataTable.time(1) dataTable.time(end)])

xlabel('time [s]');
set(gca,'fontsize',10);

linkaxes(ax,'x');
