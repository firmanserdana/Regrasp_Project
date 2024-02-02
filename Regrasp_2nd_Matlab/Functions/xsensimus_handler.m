if isunix
    % MATLAB Script

% Define the path to your Python script
python_script_path = 'xsens_linux.py';  % Replace with the actual path

% Create a system command to execute the Python script with sudo
system_command = sprintf('sudo py -3.8 "%s"', python_script_path);

% Open a process to execute the command and read the output
try
    [status, result] = system(system_command);
    if status ~= 0
        error('Error executing the Python script: %s', result);
    end
    
    while true
        % Read a line from the Python script's output
        line = fgetl(result.stdout);

        if isempty(line)
            break;  % End of the output
        end

        % Process the received line (assuming it's in a specific format)
        sensor_data = str2double_fast(line);

        % Display or process the sensor data in MATLAB
        disp(sensor_data);

        % Add your additional processing here

        pause(0.1);  % Adjust as needed based on the data streaming rate
    end
catch
    % Handle errors or user interruptions
end

% Close the process
fclose(process.stdout);
fclose(process.stdin);

elseif ispc
    % Code to run on Windows platform
else
    disp('Platform not supported')
end