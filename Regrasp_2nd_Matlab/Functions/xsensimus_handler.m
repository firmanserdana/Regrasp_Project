function [time_data, roll_data, pitch_data, yaw_data] = xsensimus_handler(host, port, reset_interval)
    if isunix
        % Code to run on Linux platform
        % Look for how to run the xsens server on linux
    elseif ispc
        % Code to run on Windows platform
        f = parfeval(@xsens_windows,0,host,port); 
    else
        disp('Platform not supported')
    end

    try
        % Create a TCP connection to the server
        tcp_client = tcpclient(host, port);
        % Plot initialization (assuming roll, pitch, yaw data will be plotted)
        % figure;
        % xlabel('Time');
        % ylabel('Angle (degrees)');
        % title('Sensor Data');
        % grid on;

        % Initialize arrays to store sensor data
        time_data = []; % Time stamps
        roll_data = []; % Roll values
        pitch_data = []; % Pitch values
        yaw_data = []; % Yaw values

        % Initialize time counter for data reset
        data_counter = 0;

        % Read and plot sensor data from the TCP server
        while true
            % Read a line of data from the TCP server
            data = readline(tcp_client);

            % Check if the end of file is reached
            if isempty(data)
                break;
            end

            % Split the received data into roll, pitch, and yaw values
            sensor_data = str2double(strsplit(data)); % Assuming data is space-separated

            % Check for NaN values and skip them
            if any(isnan(sensor_data))
                continue;
            end

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

            % Plot the data
            % plot(time_data, roll_data, 'r-', time_data, pitch_data, 'g-', time_data, yaw_data, 'b-');
            % legend('Roll', 'Pitch', 'Yaw');
            % drawnow;

            % Increment data counter
            data_counter = data_counter + 1;

            % Reset data after a certain number of data points
            if data_counter >= reset_interval
                % Close the current TCP connection
                fclose(tcp_client);

                % Create a new TCP connection
                tcp_client = tcpclient(host, port);

                % Reset data arrays
                time_data = [];
                roll_data = [];
                pitch_data = [];
                yaw_data = [];
                data_counter = 0;
            end
        end

        % Close the TCP connection
        fclose(tcp_client);

    catch e
        % Handle errors
        disp(['Error: ' e.message]);
    end
end