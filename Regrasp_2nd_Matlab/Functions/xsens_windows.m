function xsens_windows(tcpServerAddress, tcpServerPort)
    % Ensure the TCP/IP Toolbox is installed and available
    if ~license('test', 'instrument_control_toolbox')
        error('TCP/IP Toolbox is not available. Make sure it is installed and licensed.');
    end
    
    % Create a TCP/IP object
    tcpipServer = tcpip(tcpServerAddress, tcpServerPort, 'NetworkRole', 'server');
    
    % Set the size of the input buffer
    tcpipServer.InputBufferSize = 4096;
    
    % Set the callback function for incoming data
    tcpipServer.BytesAvailableFcn = @tcpipServerCallback;
    
    % Open the connection
    fopen(tcpipServer);
    
    % Define a global variable to store the TCP/IP object
    global tcpipServerObject;
    tcpipServerObject = tcpipServer;

    try
        %% Original Xsens Data Acquisition Code
        %% Launching activex server
        switch computer
            case 'PCWIN'
                serverName = 'xsensdeviceapi_com32.IXsensDeviceApi';
            case 'PCWIN64'
                serverName = 'xsensdeviceapi_com64.IXsensDeviceApi';
        end
        h = actxserver(serverName);
        fprintf( '\n ActiveXsens server - activated \n' );
    
        version = h.XsControl_version;
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
        isDongle = cellfun(@(x) h.XsDeviceId_isAwindaDongle(x),p_br(:,1));
        isStation = cellfun(@(x) h.XsDeviceId_isAwindaStation(x),p_br(:,1));
    
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
    
        % To be able to get orientation data from a MTw, the filter in the
        % software needs to be turned on:
        h.XsDevice_setOptions(device, h.XsOption_XSO_Orientation, 0);
        h.XsDevice_gotoConfig(device);
    
        % Get the list of supported update rates and let the user choose the
        % one to set
        supportUpdateRates = h.XsDevice_supportedUpdateRates(device, h.XsDataIdentifier_XDI_None);
        upRateIndex = [];
        while(isempty(upRateIndex))
            fprintf('\n The supported update rates are: ');
            fprintf('%i, ',supportUpdateRates{:});
            fprintf('\n');
            selectedUpdateRate = input(' Which update rate do you want to use ? ');
            if (isempty(selectedUpdateRate))
                continue;
            end
            upRateIndex = find([supportUpdateRates{:}] == selectedUpdateRate);
        end
    
        % set the choosen update rate
        h.XsDevice_setUpdateRate(device, supportUpdateRates{upRateIndex});
    
        if(any(isDongle|isStation))
            % Let the user choose the desired radio channel
            availableRadioChannels = [11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
            upRadioChIndex = [];
            while(isempty(upRadioChIndex))
                fprintf('\n The available radio channels are: ');
                fprintf('%i, ',availableRadioChannels);
                fprintf('\n');
                selectedRadioCh = input(' Which radio channel do you want to use ? ');
                if (isempty(selectedRadioCh))
                    continue;
                end
                upRadioChIndex = find(availableRadioChannels == selectedRadioCh);
            end
    
            try
                % enable radio
                h.XsDevice_enableRadio(device, availableRadioChannels(upRadioChIndex));
            catch
                fprintf(' Radio is still turned on, remove device from pc and try again')
            end % if radio is still on, this call will give an error
    
            input('\n Undock the MTw devices from the Awinda station and wait until the devices are connected (synced leds), then press enter... \n');
    
            % check which devices are found
            children = h.XsDevice_children(device);
    
            % make sure at least one sensor is connected.
            devIdAll = cellfun(@(x) dec2hex(h.XsDevice_deviceId(x)),children,'uniformOutput',false);
            % check connected sensors, see which are accepted and which are
            % rejected.
            [devicesUsed, devIdUsed, nDevs] = checkConnectedSensors(devIdAll);
            fprintf(' Used device: %s \n',devIdUsed{:});
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
    
        % Create figure for showing data
        %[t, dataPlot, linePlot, packetCounter] = createFigForDisplay(nDevs, devIdUsed);
    
        if output
            % Start recording
            h.XsDevice_startRecording(device);
            % Register onLiveDataAvailable event
            h.registerevent({'onLiveDataAvailable',@handleData});
            h.setCallbackOption(h.XsComCallbackOptions_XSC_LivePacket, h.XsComCallbackOptions_XSC_None);
            % Event handler will call stopAll when limit is reached
            input('\n Press enter to stop measurement. \n');
    
        else
            fprintf('\n Problems with going to measurement\n')
        end
        stopAll;
    
    catch exception
        % Close the TCP/IP connection in case of an error
        fclose(tcpipServer);
        delete(tcpipServer);
        rethrow(exception);
    end
    
    %% Event handler
    function handleData(varargin)
        % Callback function for event: onLiveDataAvailable
        dataPacket = varargin{3}{2};
        deviceFound = varargin{3}{1};
        
        if dataPacket
            if h.XsDataPacket_containsOrientation(dataPacket)
                oriC = cell2mat(h.XsDataPacket_orientationEuler_1(dataPacket));
                % Send the data to the TCP/IP client
                fwrite(tcpipServerObject, oriC, 'double');
            end
            
            h.liveDataPacketHandled(deviceFound);
        end
    end
    
    function stopAll
        % Close everything in the right way
        if ~isempty(h.eventlisteners)
            h.unregisterevent({'onLiveDataAvailable',@handleData});
            h.setCallbackOption(h.XsComCallbackOptions_XSC_None, h.XsComCallbackOptions_XSC_LivePacket);
        end
        % Stop recording
        fprintf('\n Stop recording, go to config mode \n');
        h.XsDevice_stopRecording(device);
        h.XsDevice_gotoConfig(device);
        % Disable radio for station or dongle
        if any(isStation|isDongle)
            h.XsDevice_disableRadio(device);
        end
        % Close handle
        h.XsControl_close();
        delete(h);
    end
    
    function [devicesUsed, devIdUsed, nDevs] = checkConnectedSensors(devIdAll)
        childUsed = false(size(children));
        if isempty(children)
            fprintf('\n No devices found \n')
            stopAll
            error('MTw:example:devicdes','No devices found')
        else
            % Check which sensors are connected
            for ic=1:length(children)
                if h.XsDevice_connectivityState(children{ic}) == h.XsConnectivityState_XCS_Wireless
                    childUsed(ic) = true;
                end
            end
            % Show which sensors are connected
            fprintf('\n Devices rejected:\n')
            rejects = devIdAll(~childUsed);
            I=0;
            for i=1:length(rejects)
                I = find(strcmp(devIdAll, rejects{i}));
                fprintf(' %d - %s\n', I,rejects{i})
            end
            fprintf('\n Devices accepted:\n')
            accepted = devIdAll(childUsed);
            for i=1:length(accepted)
                I = find(strcmp(devIdAll, accepted{i}));
                fprintf(' %d - %s\n', I,accepted{i})
            end
            str = input('\n Keep current status?(y/n) \n','s');
            change = [];
            if strcmp(str,'n')
                str = input('\n Type the numbers of the sensors (csv list, e.g. "1,2,3") from which status should be changed \n (if accepted than reject or the other way around):\n','s');
                change = str2double(regexp(str, ',', 'split'));
                for iR=1:length(change)
                    if childUsed(change(iR))
                        % Reject sensors
                        h.XsDevice_rejectConnection(children{change(iR)});
                        childUsed(change(iR)) = false;
                    else
                        % Accept sensors
                        h.XsDevice_acceptConnection(children{change(iR)});
                        childUsed(change(iR)) = true;
                    end
                end
            end
            % If no device is connected, give error
            if sum(childUsed) == 0
                stopAll
                error('MTw:example:devicdes','No devices connected')
            end
            % If sensors are rejected or accepted check blinking leds again
            if ~isempty(change)
                input('\n When sensors are connected (synced leds), press enter... \n');
            end
        end
        devicesUsed = children(childUsed);
        devIdUsed = devIdAll(childUsed);
        nDevs = sum(childUsed);
    end
end

% Callback function for handling incoming data
function tcpipServerCallback(~, ~)
    % Retrieve the TCP/IP object from the global variable
    global tcpipServerObject;
    
    % Read the incoming data
    data = fread(tcpipServerObject, tcpipServerObject.BytesAvailable);
    
    % Process the data as needed
    % For example, you can print the received data
    disp(['Received data: ' char(data')]);
end
