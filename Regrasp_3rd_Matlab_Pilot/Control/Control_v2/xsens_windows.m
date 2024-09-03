function xsens_windows(host, port)
    %% Launching activex server
        switch computer
            case 'PCWIN'
                serverName = 'xsensdeviceapi_com32.IXsensDeviceApi';
            case 'PCWIN64'
                serverName = 'xsensdeviceapi_com64.IXsensDeviceApi';
        end
        h = actxserver(serverName);
        fprintf( '\n ActiveXsens server - activated \n' );
    
        version = h.xdaVersion;
        fprintf(' XDA version: %.0f.%.0f.%.0f\n',version{1:3})
        if length(version)>3
            fprintf(' XDA build: %.0f %s\n',version{4:5});
        end
    
    %% Scanning connection ports
        % ports rescanned must be reopened
        p_br = h.XsScanner_scanPorts(0, 100, true, true);
        fprintf( '\n Connection ports - scanned \n' );
    
        % check using device id's what kind of devices are connected.
        isMtw = cellfun(@(x) h.XsDeviceId_isMtw(x),p_br(:,1));
        isDongle = cellfun(@(x) h.XsDeviceId_isAwindaXDongle(x),p_br(:,1));
        isStation = cellfun(@(x) h.XsDeviceId_isAwindaXStation(x),p_br(:,1));
    
        if any(isDongle|isStation)
            fprintf('\n Example dongle or station\n')
            dev = find(isDongle|isStation);
            isMtw = false; % if a station or a dongle is connected give priority to it.
        elseif any(isMtw)
            fprintf('\n Example MTw\n')
            dev = find(isMtw);
        else
            fprintf('\n No device found. \n')
            h.XsControl_close();
            delete(h);
            return
        end
    
        % port scan gives back information about the device, use first device found.
        deviceID = p_br{dev(1),1};
        portS = p_br{dev(1),3};
        baudRate = p_br{dev(1),4};
    
        devTypeStr = '';
        if any(isMtw)
            devTypeStr = 'MTw';
        elseif any(isDongle)
            devTypeStr = 'dongle';
        else
            assert(any(isStation))
            devTypeStr = 'station';
        end
        fprintf('\n Found %s on port %s, with ID: %s and baudRate: %.0f \n',devTypeStr, portS, dec2hex(deviceID), baudRate);
    
        % open port
        if ~h.XsControl_openPort(portS, baudRate, 0 ,true)
            fprintf('\n Unable to open port %s. \n', portS);
            h.XsControl_close();
            delete(h);
            return;
        end
    
    %% Initialize Master Device
        % get device handle.
        device = h.XsControl_device(deviceID);
        tcpServer = [];
    
        % To be able to get orientation data from a MTw, the filter in the
        % software needs to be turned on:
        h.XsDevice_setOptions(device, h.XsOption_XSO_Orientation, 0);
        h.XsDevice_gotoConfig(device);
    
        % set the choosen update rate
        h.XsDevice_setUpdateRate(device, 120);
    
        if(any(isDongle|isStation))
            try
                % enable radio
                h.XsDevice_enableRadio(device, 25);
            catch
                fprintf(' Radio is still turned on, remove device from pc and try again')
            end % if radio is still on, this call will give an error
            
            %input('\n Undock the MTw devices from the Awinda station and wait until the devices are connected (synced leds), then press enter... \n');
            pause(5); % wait for radio to be enabled
            % check which devices are found
            children = h.XsDevice_children(device);
    
            % make sure at least one sensor is connected.
            devIdAll = cellfun(@(x) dec2hex(h.XsDevice_deviceId(x)), children, 'uniformOutput', false);

            % check connected sensors, see which are accepted and which are rejected.
            [devicesUsed, devIdUsed, nDevs] = checkConnectedSensors(devIdAll);
            fprintf(' Used device: %s \n', devIdUsed{:});

            else
                assert(any(isMtw))
                nDevs = 1; % only one device available
                devIdUsed = {dec2hex(deviceID)};
                devicesUsed = {device};
            end

            %% Entering measurement mode
            fprintf('\n Activate measurement mode \n');
            % goto measurement mode
            output = h.XsDevice_gotoMeasurement(device);

            % display radio connection information
            if(any(isDongle|isStation))
                fprintf('\n Connection has been established on channel %i with an update rate of %i Hz\n', h.XsDevice_radioChannel(device), h.XsDevice_updateRate(device));
            else
                assert(any(isMtw))
                fprintf('\n Connection has been established with an update rate of %i Hz\n', h.XsDevice_updateRate(device));
            end

            % create figure for showing data
            [t, dataPlot, linePlot, packetCounter] = createFigForDisplay(nDevs, devIdUsed);

            % check filter profiles
            if ~isempty(devicesUsed)
                availableProfiles = h.XsDevice_availableXdaFilterProfiles(devicesUsed{1});
                usedProfile = h.XsDevice_xdaFilterProfile(devicesUsed{1});
                number = usedProfile{1};
                version = usedProfile{2};
                name = usedProfile{3};
                fprintf('\n Used profile: %s(%.0f), version %.0f.\n', name, number, version);
                if any([availableProfiles{:,1}] ~= number)
                    fprintf('\n Other available profiles are: \n');
                    for iP = 1:size(availableProfiles, 1)
                        fprintf(' Profile: %s(%.0f), version %.0f.\n', availableProfiles{iP,3}, availableProfiles{iP,1}, availableProfiles{iP,2});
                    end
                end
            end

            if output
                % start recording
                h.XsDevice_startRecording(device);
                tcpServer = createTcpServer(host, port);
                if tcpServer.Connected
                    fprintf('\n Server connected \n');
                end
                % register onLiveDataAvailable event
                h.registerevent({'onLiveDataAvailable', @handleData});
                h.setCallbackOption(h.XsComCallbackOptions_XSC_LivePacket, h.XsComCallbackOptions_XSC_None);
                % event handler will call stopAll when limit is reached
                input('\n Press enter to stop measurement. \n');

            else
                fprintf('\n Problems with going to measurement\n');
            end
            stopAll;

            %% Event handler
            function handleData(varargin)
                % callback function for event: onLiveDataAvailable
                dataPacket = varargin{3}{2};
                deviceFound = varargin{3}{1};

                iDev = find(cellfun(@(x) x == deviceFound, devicesUsed));
                if isempty(t{iDev})
                    t{iDev} = 1;
                else
                    t{iDev} = [t{iDev} t{iDev}(end) + 1];
                end
                if dataPacket
                    if h.XsDataPacket_containsOrientation(dataPacket)
                        oriC = cell2mat(h.XsDataPacket_orientationEuler_1(dataPacket));
                        tcpServer.writeline(oriC(1) + "," + oriC(2) + "," + oriC(3));
                        packetCounter(iDev) = packetCounter(iDev) + 1;
                        dataPlot{iDev} = [dataPlot{iDev} oriC];
                    end

                    h.liveDataPacketHandled(deviceFound, dataPacket);

                    % draw
                    if packetCounter(iDev) > 10
                        if length(t) > 1000
                            t{iDev}(1:end-990) = [];
                            dataPlot{iDev}(:,1:end-990) = [];
                            %set(get(linePlot{iDev}(1),'parent'),'xlim',[t{iDev}(1) t{iDev}(end)+10]);
                        end
                        % for i=1:3
                        %     set(linePlot{iDev}(i),'xData',t{iDev},'ydata',dataPlot{iDev}(i,:));
                        % end
                        packetCounter(iDev) = 0;
                    end
                end
            end

            function stopAll
                % close everything in the right way
                if ~isempty(h.eventlisteners) || isempty(tcpServer.Connected)
                    h.unregisterevent({'onLiveDataAvailable', @handleData});
                    h.setCallbackOption(h.XsComCallbackOptions_XSC_None, h.XsComCallbackOptions_XSC_LivePacket);
                end
                % stop recording, showing data
                fprintf('\n Stop recording, go to config mode \n');
                h.XsDevice_stopRecording(device);
                h.XsDevice_gotoConfig(device);
                % disable radio for station or dongle
                if any(isStation|isDongle)
                    h.XsDevice_disableRadio(device);
                end
                % close log file
                fprintf('\n Close log file \n');
                h.XsDevice_closeLogFile(device);
                % on close, devices go to config mode.
                fprintf('\n Close port \n');
                % close port
                h.XsControl_closePort(portS);
                % close handle
                h.XsControl_close();
                % delete handle
                delete(h);
            end

            function [devicesUsed, devIdUsed, nDevs] = checkConnectedSensors(devIdAll)
                childUsed = false(size(children));
                if isempty(children)
                    fprintf('\n No devices found \n');
                    stopAll;
                    error('MTw:example:devicdes', 'No devices found');
                else
                    % check which sensors are connected
                    for ic = 1:length(children)
                        if h.XsDevice_connectivityState(children{ic}) == h.XsConnectivityState_XCS_Wireless
                            childUsed(ic) = true;
                        end
                    end
                    % show which sensors are connected
                    fprintf('\n Devices rejected:\n');
                    rejects = devIdAll(~childUsed);
                    I = 0;
                    for i = 1:length(rejects)
                        I = find(strcmp(devIdAll, rejects{i}));
                        fprintf(' %d - %s\n', I, rejects{i});
                    end
                    fprintf('\n Devices accepted:\n');
                    accepted = devIdAll(childUsed);
                    for i = 1:length(accepted)
                        I = find(strcmp(devIdAll, accepted{i}));
                        fprintf(' %d - %s\n', I, accepted{i});
                    end
                    str = 'y';
                    change = [];
                    if strcmp(str, 'n')
                        str = input('\n Type the numbers of the sensors (csv list, e.g. "1,2,3") from which status should be changed \n (if accepted than reject or the other way around):\n', 's');
                        change = str2double(regexp(str, ',', 'split'));
                        for iR = 1:length(change)
                            if childUsed(change(iR))
                                % reject sensors
                                h.XsDevice_rejectConnection(children{change(iR)});
                                childUsed(change(iR)) = false;
                            else
                                % accept sensors
                                h.XsDevice_acceptConnection(children{change(iR)});
                                childUsed(change(iR)) = true;
                            end
                        end
                    end
                    % if no device is connected, give error
                    if sum(childUsed) == 0
                        stopAll;
                        error('MTw:example:devicdes', 'No devices connected');
                    end
                    % if sensors are rejected or accepted check blinking leds again
                    if ~isempty(change)
                        input('\n When sensors are connected (synced leds), press enter... \n');
                    end
                end
                devicesUsed = children(childUsed);
                devIdUsed = devIdAll(childUsed);
                nDevs = sum(childUsed);
            end
            end

            %% Helper function to create figure for display
            function [t, dataPlot, linePlot, packetCounter] = createFigForDisplay(nDevs, deviceIds)

            [dataPlot{1:nDevs}] = deal([]);
            [linePlot{1:nDevs}] = deal([]);
            [t{1:nDevs}] = deal([]);

            %% not more than 6 devices per plot
            nFigs = ceil(nDevs/6);
            devPerFig = ceil(nDevs/nFigs);
            m = ceil(sqrt(devPerFig));
            n = ceil(devPerFig/m);
            lDev = 0;
            for iFig = 1:nFigs
                %figure('name',['Example MTw_' num2str(iFig)])
                iPlot = 0;
                for iDev = lDev+1:min(iFig*devPerFig, nDevs)
                    iPlot = iPlot+1;
                    %ax = subplot(m,n,iPlot);
                    %linePlot{iDev} = plot(ax, 0,[NaN NaN NaN]);
                    %title(['Orientation data ' deviceIds{iDev}]), xlabel('sample'), ylabel('euler (deg)')
                    %legend(ax, 'roll','pitch','yaw');
                end
                lDev = iDev;
            end
            packetCounter = zeros(nDevs,1);
            end

            function tcpServer = createTcpServer(host, port)
            port = round(str2double(port));
            disp(['Server is waiting to be connected at ' host ':' num2str(port)]);
            tcpServer = tcpserver(host, port);
            set(tcpServer, 'Timeout', 30);
            fopen(tcpServer);
            end
