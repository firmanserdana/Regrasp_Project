classdef xsens_windows
    properties
        h % ActiveX server handle
        deviceID
        portS
        baudRate
        isMtw
        isDongle
        isStation
        devicesUsed
        devIdUsed
        nDevs
        t
        dataPlot
        linePlot
        packetCounter
    end
    
    methods
        function obj = XsensController()
            % Constructor
            obj.h = [];
            obj.deviceID = [];
            obj.portS = [];
            obj.baudRate = [];
            obj.isMtw = [];
            obj.isDongle = [];
            obj.isStation = [];
            obj.devicesUsed = [];
            obj.devIdUsed = [];
            obj.nDevs = [];
            obj.t = [];
            obj.dataPlot = [];
            obj.linePlot = [];
            obj.packetCounter = [];
        end
        
        function initialize(obj)
            %% Launching activex server
            switch computer
                case 'PCWIN'
                    serverName = 'xsensdeviceapi_com32.IXsensDeviceApi';
                case 'PCWIN64'
                    serverName = 'xsensdeviceapi_com64.IXsensDeviceApi';
            end
            obj.h = actxserver(serverName);
            fprintf( '\n ActiveXsens server - activated \n' );

            version = obj.h.XsControl_version;
            fprintf(' XDA version: %.0f.%.0f.%.0f\n',version{1:3})
            if length(version)>3
                fprintf(' XDA build: %.0f %s\n',version{4:5});
            end
            
            obj.scanPorts();
        end
        
        function scanPorts(obj)
            %% Scanning connection ports
            % ports rescanned must be reopened
            p_br = obj.h.XsScanner_scanPorts(0, 100, true, true);
            fprintf( '\n Connection ports - scanned \n' );

            % check using device id's what kind of devices are connected.
            obj.isMtw = cellfun(@(x) obj.h.XsDeviceId_isMtw(x),p_br(:,1));
            obj.isDongle = cellfun(@(x) obj.h.XsDeviceId_isAwindaDongle(x),p_br(:,1));
            obj.isStation = cellfun(@(x) obj.h.XsDeviceId_isAwindaStation(x),p_br(:,1));

            if any(obj.isDongle|obj.isStation)
                fprintf('\n Example dongle or station\n')
                dev = find(obj.isDongle|obj.isStation);
                obj.isMtw = false; % if a station or a dongle is connected give priority to it.
            elseif any(obj.isMtw)
                fprintf('\n Example MTw\n')
                dev = find(obj.isMtw);
            else
                fprintf('\n No device found. \n')
                obj.h.XsControl_close();
                delete(obj.h);
                return
            end

            % port scan gives back information about the device, use first device found.
            obj.deviceID = p_br{dev(1),1};
            obj.portS = p_br{dev(1),3};
            obj.baudRate = p_br{dev(1),4};

            devTypeStr = '';
            if any(obj.isMtw)
                devTypeStr = 'MTw';
            elseif any(obj.isDongle)
                devTypeStr = 'dongle';
            else
                assert(any(obj.isStation))
                devTypeStr = 'station';
            end
            fprintf('\n Found %s on port %s, with ID: %s and baudRate: %.0f \n',devTypeStr, obj.portS, dec2hex(obj.deviceID), obj.baudRate);
        end
        
        function startMeasurement(obj)
            %% Initialize Master Device
            % get device handle.
            device = obj.h.XsControl_device(obj.deviceID);

            % To be able to get orientation data from a MTw, the filter in the
            % software needs to be turned on:
            obj.h.XsDevice_setOptions(device, obj.h.XsOption_XSO_Orientation, 0);
            obj.h.XsDevice_gotoConfig(device);

            % Get the list of supported update rates and let the user choose the
            % one to set
            supportUpdateRates = obj.h.XsDevice_supportedUpdateRates(device, obj.h.XsDataIdentifier_XDI_None);
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

            % set the chosen update rate
            obj.h.XsDevice_setUpdateRate(device, supportUpdateRates{upRateIndex});

            if(any(obj.isDongle|obj.isStation))
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
                    obj.h.XsDevice_enableRadio(device, availableRadioChannels(upRadioChIndex));
                catch
                    fprintf(' Radio is still turned on, remove device from pc and try again')
                end % if radio is still on, this call will give an error

                input('\n Undock the MTw devices from the Awinda station and wait until the devices are connected (synced leds), then press enter... \n');

                % check which devices are found
                children = obj.h.XsDevice_children(device);

                % make sure at least one sensor is connected.
                devIdAll = cellfun(@(x) dec2hex(obj.h.XsDevice_deviceId(x)),children,'uniformOutput',false);
                % check connected sensors, see which are accepted and which are
                % rejected.
                [obj.devicesUsed, obj.devIdUsed, obj.nDevs] = obj.checkConnectedSensors(devIdAll);
                fprintf(' Used device: %s \n',obj.devIdUsed{:});
            else
                assert(any(obj.isMtw))
                obj.nDevs = 1; % only one device available
                obj.devIdUsed = {dec2hex(obj.deviceID)};
                obj.devicesUsed = {device};
            end

            %% Entering measurement mode
            fprintf('\n Activate measurement mode \n');
            % goto measurement mode
            output = obj.h.XsDevice_gotoMeasurement(device);

            % display radio connection information
            if(any(obj.isDongle|obj.isStation))
                fprintf('\n Connection has been established on channel %i with an update rate of %i Hz\n', obj.h.XsDevice_radioChannel(device), obj.h.XsDevice_updateRate(device));
            else
                assert(any(obj.isMtw))
                fprintf('\n Connection has been established with an update rate of %i Hz\n', obj.h.XsDevice_updateRate(device));
            end

            % create figure for showing data
            % [obj.t, obj.dataPlot, obj.linePlot, obj.packetCounter] = obj.createFigForDisplay(obj.nDevs, obj.devIdUsed);

            % check filter profiles
            if ~isempty(obj.devicesUsed)
                availableProfiles = obj.h.XsDevice_availableXdaFilterProfiles(obj.devicesUsed{1});
                usedProfile = obj.h.XsDevice_xdaFilterProfile(obj.devicesUsed{1});
                number = usedProfile{1};
                version = usedProfile{2};
                name = usedProfile{3};
                fprintf('\n Used profile: %s(%.0f), version %.0f.\n',name,number,version)
                if any([availableProfiles{:,1}] ~= number)
                    fprintf('\n Other available profiles are: \n')
                    for iP=1:size(availableProfiles,1)
                        fprintf(' Profile: %s(%.0f), version %.0f.\n',availableProfiles{iP,3},availableProfiles{iP,1},availableProfiles{iP,2})
                    end
                end
            end

            if output
                % create log file
                obj.h.XsDevice_createLogFile(device,'exampleLogfile.mtb');
                fprintf('\n Logfile: %s created\n',fullfile(cd,'exampleLogfile.mtb'));

                % start recording
                obj.h.XsDevice_startRecording(device);
                % register onLiveDataAvailable event
                obj.h.registerevent({'onLiveDataAvailable',@obj.handleData});
                obj.h.setCallbackOption(obj.h.XsComCallbackOptions_XSC_LivePacket, obj.h.XsComCallbackOptions_XSC_None);
                % event handler will call stopAll when limit is reached
                input('\n Press enter to stop measurement. \n');

            else
                fprintf('\n Problems with going to measurement\n')
            end
            obj.stopAll();
        end
        
        function handleData(obj, varargin)
            % callback function for event: onLiveDataAvailable
            dataPacket = varargin{3}{2};
            deviceFound = varargin{3}{1};

            iDev = find(cellfun(@(x) x==deviceFound, obj.devicesUsed));
            if isempty(obj.t{iDev})
                obj.t{iDev} = 1;
            else
                obj.t{iDev} = [obj.t{iDev} obj.t{iDev}(end)+1];
            end
            if dataPacket
                if obj.h.XsDataPacket_containsOrientation(dataPacket)
                    oriC = cell2mat(obj.h.XsDataPacket_orientationEuler_1(dataPacket));
                    obj.packetCounter(iDev) = obj.packetCounter(iDev)+1;
                    obj.dataPlot{iDev} = [obj.dataPlot{iDev} oriC];
                end

                obj.h.liveDataPacketHandled(deviceFound, dataPacket);

                % draw
                if obj.packetCounter(iDev)>10
                    if length(obj.t) > 1000
                        obj.t{iDev}(1:end-990) = [];
                        obj.dataPlot{iDev}(:,1:end-990) = [];
                        set(get(obj.linePlot{iDev}(1),'parent'),'xlim',[obj.t{iDev}(1) obj.t{iDev}(end)+10]);
                    end
                    for i=1:3
                        set(obj.linePlot{iDev}(i),'xData',obj.t{iDev},'ydata',obj.dataPlot{iDev}(i,:));
                    end
                    obj.packetCounter(iDev) = 0;
                end
            end
        end
        
        function stopAll(obj)
            % close everything in the right way
            if ~isempty(obj.h.eventlisteners)
                obj.h.unregisterevent({'onLiveDataAvailable',@obj.handleData});
                obj.h.setCallbackOption(obj.h.XsComCallbackOptions_XSC_None, obj.h.XsComCallbackOptions_XSC_LivePacket);
            end
            % stop recording, showing data
            fprintf('\n Stop recording, go to config mode \n');
            obj.h.XsDevice_stopRecording(obj.devicesUsed{1});
            obj.h.XsDevice_gotoConfig(obj.devicesUsed{1});
            % disable radio for station or dongle
            if any(obj.isStation|obj.isDongle)
                obj.h.XsDevice_disableRadio(obj.devicesUsed{1});
            end
            % close log file
            fprintf('\n Close log file \n');
            obj.h.XsDevice_closeLogFile(obj.devicesUsed{1});
            % on close, devices go to config mode.
            fprintf('\n Close port \n');
            % close port
            obj.h.XsControl_closePort(obj.portS);
            % close handle
            obj.h.XsControl_close();
            % delete handle
            delete(obj.h);
        end
        
        function [devicesUsed, devIdUsed, nDevs] = checkConnectedSensors(obj, devIdAll)
            childUsed = false(size(obj.devicesUsed));
            if isempty(obj.devicesUsed)
                fprintf('\n No devices found \n')
                obj.stopAll();
                error('MTw:example:devicdes','No devices found')
            else
                % check which sensors are connected
                for ic=1:length(obj.devicesUsed)
                    if obj.h.XsDevice_connectivityState(obj.devicesUsed{ic}) == obj.h.XsConnectivityState_XCS_Wireless
                        childUsed(ic) = true;
                    end
                end
                % show which sensors are connected
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
                    str = input('\n Type the numbers of the sensors (csv list, e.g. "1,2,3") from which status should be changed \n (if accepted then reject or the other way around):\n','s');
                    change = str2double(regexp(str, ',', 'split'));
                    for iR=1:length(change)
                        if childUsed(change(iR))
                            % reject sensors
                            obj.h.XsDevice_rejectConnection(obj.devicesUsed{change(iR)});
                            childUsed(change(iR)) = false;
                        else
                            % accept sensors
                            obj.h.XsDevice_acceptConnection(obj.devicesUsed{change(iR)});
                            childUsed(change(iR)) = true;
                        end
                    end
                end
                % if no device is connected, give error
                if sum(childUsed) == 0
                    obj.stopAll();
                    error('MTw:example:devicdes','No devices connected')
                end
                % if sensors are rejected or accepted check blinking leds again
                if ~isempty(change)
                    input('\n When sensors are connected (synced leds), press enter... \n');
                end
            end
            devicesUsed = obj.devicesUsed(childUsed);
            devIdUsed = devIdAll(childUsed);
            nDevs = sum(childUsed);
        end
        
        function [t, dataPlot, linePlot, packetCounter] = createFigForDisplay(obj, nDevs, deviceIds)
            [dataPlot{1:nDevs}] = deal([]);
            [linePlot{1:nDevs}] = deal([]);
            [t{1:nDevs}] = deal([]);

            %% not more than 6 devices per plot
            nFigs = ceil(nDevs/6);
            devPerFig = ceil(nDevs/nFigs);
            m = ceil(sqrt(devPerFig));
            n = ceil(devPerFig/m);
            lDev = 0;
            for iFig=1:nFigs
                figure('name',['Example MTw_' num2str(iFig)])
                iPlot = 0;
                for iDev = lDev+1:min(iFig*devPerFig, nDevs)
                    iPlot = iPlot+1;
                    ax = subplot(m,n,iPlot);
                    linePlot{iDev} = plot(ax, 0,[NaN NaN NaN]);
                    title(['Orientation data ' deviceIds{iDev}]), xlabel('sample'), ylabel('euler (deg)')
                    legend(ax, 'roll','pitch','yaw');
                end
                lDev = iDev;
            end
            packetCounter = zeros(nDevs,1);
        end

        function data = getData(obj)
            % Retrieve the data without plotting
            data = obj.dataPlot;
        end
    end
end
