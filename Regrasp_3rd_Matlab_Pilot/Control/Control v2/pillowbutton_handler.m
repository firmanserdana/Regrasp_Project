classdef pillowbutton_handler < handle

    properties (Constant)

        timeBlock = 0.5;  % press time for block [s]

    end

    properties (Access = private)

        s;              % ...
        ticPress;
        timePress = 0;  % ...

    end

    properties (Access = public)

        binSig = 0;
        binCmd = 0;     % ...
        blockStim = 0;  % ...
        stateLabel = '';

    end

    methods (Access = public)


        %% Open serial port
        function status = openSerial(obj, comPort)
            % comPort: COM port of Arduino, e.g., 'COM3'
            %ports = serialportlist;
            %comPort = ports{end};

            % Create a serial port object
            try
                obj.s = serialport(comPort, 9600);
            catch
                status = 0;
                errordlg(['Unable to connect to serialport device at port ' comPort]);
                return;
            end

            status = 1;
            disp('Pillow connected');
        end


        %% Read button state
        function readButtonState(obj)

            try
                obj.binCmd = 0;

                % Read data from the Arduino
                press = logical(obj.s.NumBytesAvailable);

                if press

                    data = char(read(obj.s,35,'uint8'));

                    if str2double(data(strfind(data,'switch')+8)) & str2double(data(strfind(data,'onset')+7))
                        obj.binSig = 1;
                        obj.ticPress = tic;
                    elseif str2double(data(strfind(data,'switch')+8)) & str2double(data(strfind(data,'offset')+8))
                        obj.binSig = 0;
                        obj.timePress = toc(obj.ticPress);
                        if obj.timePress>=obj.timeBlock
                            obj.blockStim = 1;
                            disp('START BLOCK');
                            obj.stateLabel = 'START BLOCK OF ';
                        elseif obj.timePress<obj.timeBlock & obj.blockStim
                            obj.blockStim = 0;
                            disp('STOP BLOCK');
                            obj.stateLabel = 'STOP BLOCK OF ';
                        elseif obj.timePress<obj.timeBlock & ~obj.blockStim
                            obj.binCmd = 1;
                            disp('SWITCH');
                            obj.stateLabel = 'SWITCH TO ';
                        end
                        obj.timePress = 0;
                    end
                end

            catch
                obj.binCmd = -1; % Return an error code
                disp('Error reading data from Arduino');

            end
        end


        %% Close the serial port
        function closeSerial(obj)

            fclose(obj.s);
            disp('serial port closed');
        end
    end

end
