classdef pillowbutton_handler

    methods(Static)


        %% Open serial port
        function s = openSerial()
            % comPort: COM port of Arduino, e.g., 'COM3'

            % Create a serial port object
            s = serial(comPort, 'BaudRate', 9600);

            % Open the serial port
            fopen(s);
        end


        %% Read button state
        function buttonState = readButtonState(s)

            try
                % Read data from the Arduino
                data = fscanf(s, '%s');

                % Parse JSON data
                json = jsondecode(data);

                % Extract button state
                buttonState = json.switch;

            catch
                buttonState = -1; % Return an error code
                disp('Error reading data from Arduino');

            end
        end


        %% Close the serial port
        function closeSerial(s)

            fclose(s);
            disp('serial port closed');
        end
    end

end
