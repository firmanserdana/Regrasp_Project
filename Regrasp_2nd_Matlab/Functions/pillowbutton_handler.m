function buttonState = readButtonState(comPort)
    % comPort: COM port of Arduino, e.g., 'COM3'

    % Create a serial port object
    s = serial(comPort, 'BaudRate', 9600);

    % Open the serial port
    fopen(s);

    try
        % Read data from the Arduino
        data = fscanf(s, '%s');
        
        % Parse JSON data
        json = jsondecode(data);
        
        % Extract button state
        buttonState = json.switch;

    catch
        disp('Error reading data from Arduino.');
        buttonState = -1; % Return an error code
    end

    % Close the serial port
    fclose(s);
end
