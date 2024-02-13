classdef xsens_windows < handle
    properties (Access = private)
        h % Handle to the Xsens ActiveX server
        device % Handle to the Xsens device
        portS % Port on which the device is connected
        deviceID % ID of the device
        baudRate % Baud rate of communication
        isMtw % Boolean indicating if device is MTw
        isDongle % Boolean indicating if device is dongle
        isStation % Boolean indicating if device is station
        t % Time vector for each device
        dataPlot % Data plot for each device
        linePlot % Line plot for each device
        packetCounter % Packet counter for each device
        running % Boolean indicating if data collection is running
    end
    
    methods
        function obj = XsensDataCollector()
            obj.h = actxserver('xsensdeviceapi_com32.IXsensDeviceApi');
            obj.running = false;
        end
        
        function start(obj)
            if obj.running
                warning('Data collection is already running.');
                return;
            end
            
            version = obj.h.XsControl_version;
            fprintf('XDA version: %.0f.%.0f.%.0f\n',version{1:3});
            if length(version) > 3
                fprintf('XDA build: %.0f %s\n',version{4:5});
            end
            
            p_br = obj.h.XsScanner_scanPorts(0, 100, true, true);
            
            isMtw = cellfun(@(x) obj.h.XsDeviceId_isMtw(x), p_br(:,1));
            isDongle = cellfun(@(x) obj.h.XsDeviceId_isAwindaDongle(x), p_br(:,1));
            isStation = cellfun(@(x) obj.h.XsDeviceId_isAwindaStation(x), p_br(:,1));
            
            if any(isDongle | isStation)
                fprintf('Example dongle or station\n');
                dev = find(isDongle | isStation);
                obj.isMtw = false;
            elseif any(isMtw)
                fprintf('Example MTw\n');
                dev = find(isMtw);
            else
                fprintf('No device found.\n');
                obj.h.XsControl_close();
                delete(obj.h);
                return;
            end
            
            obj.deviceID = p_br{dev(1),1};
            obj.portS = p_br{dev(1),3};
            obj.baudRate = p_br{dev(1),4};
            
            obj.isMtw = any(isMtw);
            obj.isDongle = any(isDongle);
            obj.isStation = any(isStation);
            
            if ~obj.h.XsControl_openPort(obj.portS, obj.baudRate, 0, true)
                fprintf('Unable to open port %s.\n', obj.portS);
                obj.h.XsControl_close();
                delete(obj.h);
                return;
            end
            
            obj.device = obj.h.XsControl_device(obj.deviceID);
            obj.running = true;
        end
        
        function stop(obj)
            if ~obj.running
                warning('Data collection is not running.');
                return;
            end
            
            obj.h.XsControl_closePort(obj.portS);
            obj.h.XsControl_close();
            delete(obj.h);
            obj.running = false;
        end
        
        function [t, dataPlot, linePlot, packetCounter] = getData(obj)
            if ~obj.running
                warning('Data collection is not running.');
                return;
            end
            [t, dataPlot, linePlot, packetCounter] = obj.t, obj.dataPlot, obj.linePlot, obj.packetCounter;
        end
    end
end
