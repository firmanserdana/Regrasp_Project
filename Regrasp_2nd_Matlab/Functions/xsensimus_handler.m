classdef xsensimus_handler
    methods(Static)
        function xsens_start(host, port)
            % Ensure these vars when starting the function
            % HOST = '127.0.0.1'  # Standard loopback interface address (localhost)
            % PORT = 65432  # Port to listen on (non-privileged ports are > 1023)
            if isunix
                % Code to run on Linux platform
                try
                    % Start the Xsens IMU data acquisition
                    system('sudo py -3.8 Regrasp_2nd_Matlab/Functions/xsens_linux.py');
                catch
                    disp('Error: Xsens IMU data acquisition failed');
                end
            elseif ispc
                % Code to run on Windows platform
                try
                    commandStr = 'matlab -nosplash -nodesktop -r "run(''xsens_windows('+host+','+port+')''); exit;"';
                    system(commandStr);
                catch
                    disp('Error: Xsens IMU data acquisition failed');
                end
            else
                disp('Platform not supported') 
            end
        end

        function [time_data, roll_data, pitch_data, yaw_data] = receiveData(tcp_client)
            try

                % Initialize arrays to store sensor data
                time_data = []; % Time stamps
                roll_data = []; % Roll values
                pitch_data = []; % Pitch values
                yaw_data = []; % Yaw values
                    % Read a line of data from the TCP server
                    data = readline(tcp_client);

                    % Split the received data into roll, pitch, and yaw values
                    sensor_data = str2double(strsplit(data)); % Assuming data is space-separated

                    % Extract roll, pitch, and yaw values
                    roll = sensor_data(1);
                    pitch = sensor_data(2);
                    yaw = sensor_data(3);

                    % Record time stamp
                    time_stamp = datetime('now');

                    % Append data to arrays
                    time_data = [time_data; time_stamp];
                    roll_data = [roll_data; roll];
                    pitch_data = [pitch_data; pitch];
                    yaw_data = [yaw_data; yaw];
            catch e
                % Handle errors
                disp(['Error: ' e.message]);
            end
        end

        function tcp_client = connect(host, port)
        try
            % Create a TCP connection to the server
            tcp_client = tcpclient(host, port);
        catch e
            % Handle errors
            disp(['Error: ' e.message]);
        end
        end

        function disconnect(t)
            pause(0.5);
            clear(t);
        end
    end
end