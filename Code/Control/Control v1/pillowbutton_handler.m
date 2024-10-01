classdef pillowbutton_handler

    methods(Static)


        %% Open serial port
        function s = openSerial()
            % comPort: COM port of Arduino, e.g., 'COM3'
            %ports = serialportlist;
            %comPort = ports{end};
            comPort = 'COM4';

            % Create a serial port object
            s = serialport(comPort, 9600);
            disp('Pillow connected')
        end


        %% Read button state
        function binCmd = readButtonState(s)
            
            try
                binCmd = 0;

                % Read data from the Arduino
                press = logical(s.NumBytesAvailable);

                if press

                   data = char(read(s,35,'uint8'));

                if str2double(data(strfind(data,'switch')+8)) & str2double(data(strfind(data,'onset')+7))
                   binCmd = 1;
                end

                end

            catch
                binCmd = -1; % Return an error code
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
