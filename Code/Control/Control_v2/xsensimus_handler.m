classdef xsensimus_handler < handle

    properties (Access = public)

        host = 'localhost';
        port = 5000;
        loopFreq = 20; % [Hz]

        tcp_client;
        
        firstRun = 1;

        pitch;
        propCmd;
        roll;
        yaw;
        device_id;

    end


    methods (Access = public)

        %% Connect server
        function status = connect(obj)

            try
                % Create a TCP connection to the server
                obj.tcp_client = tcpclient(obj.host, obj.port);
            catch e
                % Handle errors
                status = 0;
                disp(['Error: ' e.message]);                
                errordlg('Could not find NIP.');
                return;
            end

            % Confirm the connection
            status = 1;
            disp('MTw Awinda connected')

        end

        %% Read data
        function receiveData(obj)

            try
                % Read a line of data from the TCP server
                %data = readline(obj.tcp_client);
                if obj.firstRun
                    flush(obj.tcp_client);
                    obj.firstRun = 0;
                    obj.pitch = NaN;
                    return;
                end
                data = read(obj.tcp_client,obj.tcp_client.NumBytesAvailable,"string");
                data = splitlines(data);
                data = data(end-1);

                % Split the received data into device id, roll, pitch, and yaw values
                temp_data = split(data, ',');
                sensor_data = str2double(temp_data(2:4));
                device_id = temp_data(1);
                
                % Extract device id, roll, pitch, and yaw values
                obj.device_id = device_id;
                obj.roll = sensor_data(1);
                obj.pitch = sensor_data(2);
                obj.yaw = sensor_data(3);

            catch e
                % Handle errors
                disp(['Error: ' e.message]);
            end
        end

        %% Process data
        function processData(obj, paramsGUI)

            % Only process data if pitch, roll and yaw are within calibration limits
            % if any(obj.roll < paramsGUI.minRoll) || any(obj.roll > paramsGUI.maxRoll) || ...
            %         any(obj.yaw < paramsGUI.minYaw) || any(obj.yaw > paramsGUI.maxYaw) || ...
            %         any(obj.pitch < paramsGUI.minPitch) || any(obj.pitch > paramsGUI.maxPitch)
            %     disp('Imu values are out of calibration limits, ensure patient is in correct position');
            %     return;
            % end
            % Compute proportional command by normalizing pich data to
            % calibration minimum and maximum
            obj.propCmd = (obj.pitch - paramsGUI.minPitch) / (paramsGUI.maxPitch - paramsGUI.minPitch);

        end

        %% Disconnect server
        function disconnect(obj)

            pause(0.5);
            delete(obj.tcp_client);

        end
    end


    % methods(Static)
    %
    %     function xsens_start(host, port)
    %         % Ensure these vars when starting the function
    %         % HOST = '127.0.0.1'  # Standard loopback interface address (localhost)
    %         % PORT = 65432  # Port to listen on (non-privileged ports are > 1023)
    %         if isunix
    %             % Code to run on Linux platform
    %             try
    %                 % Start the Xsens IMU data acquisition
    %                 system('sudo py -3.8 Regrasp_2nd_Matlab/Functions/xsens_linux.py');
    %             catch
    %                 disp('Error: Xsens IMU data acquisition failed');
    %             end
    %         elseif ispc
    %             % Code to run on Windows platform
    %             try
    %                 commandStr = ['matlab -nosplash -nodesktop -r "run(''xsens_windows(''' host ''',''' port ''')''); exit;"'];
    %                 system(commandStr);
    %             catch
    %                 disp('Error: Xsens IMU data acquisition failed');
    %             end
    %         else
    %             disp('Platform not supported')
    %         end
    %     end
    % end
end