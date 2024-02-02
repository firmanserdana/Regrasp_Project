classdef main_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        TabGroup                        matlab.ui.container.TabGroup
        ConfigTab                       matlab.ui.container.Tab
        Panel                           matlab.ui.container.Panel
        Prop_SatEditField               matlab.ui.control.NumericEditField
        Prop_SatEditFieldLabel          matlab.ui.control.Label
        Prop_ThrEditField               matlab.ui.control.NumericEditField
        Prop_ThrEditFieldLabel          matlab.ui.control.Label
        ControlParametersPanel          matlab.ui.container.Panel
        CalibrationButton               matlab.ui.control.Button
        StimulationParametersPanel      matlab.ui.container.Panel
        MinEditField_4                  matlab.ui.control.NumericEditField
        MinEditFieldLabel_2             matlab.ui.control.Label
        MinEditField_3                  matlab.ui.control.NumericEditField
        MinEditField_2                  matlab.ui.control.NumericEditField
        MinEditField                    matlab.ui.control.NumericEditField
        MinEditFieldLabel               matlab.ui.control.Label
        AmplitudemicroAEditFieldLabel_2  matlab.ui.control.Label
        FrequencyHzEditFieldLabel_2     matlab.ui.control.Label
        ActiveSiteListBox               matlab.ui.control.ListBox
        ActiveSiteListBoxLabel          matlab.ui.control.Label
        AmplitudemicroAEditField        matlab.ui.control.NumericEditField
        AmplitudemicroAEditFieldLabel   matlab.ui.control.Label
        FrequencyHzEditField            matlab.ui.control.NumericEditField
        FrequencyHzEditFieldLabel       matlab.ui.control.Label
        PulseWidthmicrosEditField       matlab.ui.control.NumericEditField
        PulseWidthmicrosEditFieldLabel  matlab.ui.control.Label
        AMorFMDropDown                  matlab.ui.control.DropDown
        AMorFMDropDownLabel             matlab.ui.control.Label
        MovementtoevokeDropDown         matlab.ui.control.DropDown
        MovementtoevokeDropDownLabel    matlab.ui.control.Label
        LoadParametersButton            matlab.ui.control.Button
        SaveParametersButton            matlab.ui.control.Button
        ApplyParameterButton            matlab.ui.control.Button
        InitializeDevicesPanel          matlab.ui.container.Panel
        StatusLamp_3                    matlab.ui.control.Lamp
        StatusLamp_3Label               matlab.ui.control.Label
        StimulatorConnectButton         matlab.ui.control.Button
        StatusLamp_2                    matlab.ui.control.Lamp
        StatusLamp_2Label               matlab.ui.control.Label
        StatusLamp                      matlab.ui.control.Lamp
        StatusLampLabel                 matlab.ui.control.Label
        ConnectButton_2                 matlab.ui.control.Button
        ConnectButton                   matlab.ui.control.Button
        BinaryControlButtonGroup        matlab.ui.container.ButtonGroup
        eegomylabButton                 matlab.ui.control.RadioButton
        PillowSwitchButton              matlab.ui.control.RadioButton
        ProportionalControlButtonGroup  matlab.ui.container.ButtonGroup
        MTwAwindaButton                 matlab.ui.control.RadioButton
        sessantaquattroButton           matlab.ui.control.RadioButton
        DataStreamTab                   matlab.ui.container.Tab
        StimulateButtonGroup            matlab.ui.container.ButtonGroup
        StopButton                      matlab.ui.control.ToggleButton
        StartButton                     matlab.ui.control.ToggleButton
        StatusLamp_6                    matlab.ui.control.Lamp
        StatusLamp_6Label               matlab.ui.control.Label
        StatusLamp_5                    matlab.ui.control.Lamp
        StatusLamp_5Label               matlab.ui.control.Label
        StatusLamp_4                    matlab.ui.control.Lamp
        StatusLamp_4Label               matlab.ui.control.Label
        UIAxes_3                        matlab.ui.control.UIAxes
        UIAxes_2                        matlab.ui.control.UIAxes
        UIAxes                          matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Selection changed function: ProportionalControlButtonGroup
        function ProportionalControlButtonGroupSelectionChanged(app, event)
            selectedButton = app.ProportionalControlButtonGroup.SelectedObject;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 809 686];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 809 686];

            % Create ConfigTab
            app.ConfigTab = uitab(app.TabGroup);
            app.ConfigTab.Title = 'Config';
            app.ConfigTab.BackgroundColor = [0.94 0.94 0.94];

            % Create InitializeDevicesPanel
            app.InitializeDevicesPanel = uipanel(app.ConfigTab);
            app.InitializeDevicesPanel.ForegroundColor = [0 0 0];
            app.InitializeDevicesPanel.Title = 'Initialize Devices';
            app.InitializeDevicesPanel.BackgroundColor = [0.94 0.94 0.94];
            app.InitializeDevicesPanel.Position = [11 300 294 353];

            % Create ProportionalControlButtonGroup
            app.ProportionalControlButtonGroup = uibuttongroup(app.InitializeDevicesPanel);
            app.ProportionalControlButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ProportionalControlButtonGroupSelectionChanged, true);
            app.ProportionalControlButtonGroup.ForegroundColor = [0 0 0];
            app.ProportionalControlButtonGroup.Title = 'Proportional Control';
            app.ProportionalControlButtonGroup.BackgroundColor = [0.94 0.94 0.94];
            app.ProportionalControlButtonGroup.Position = [14 245 136 75];

            % Create sessantaquattroButton
            app.sessantaquattroButton = uiradiobutton(app.ProportionalControlButtonGroup);
            app.sessantaquattroButton.Text = 'sessantaquattro+';
            app.sessantaquattroButton.FontColor = [0.850980392156863 0.850980392156863 0.850980392156863];
            app.sessantaquattroButton.Position = [11 29 115 22];
            app.sessantaquattroButton.Value = true;

            % Create MTwAwindaButton
            app.MTwAwindaButton = uiradiobutton(app.ProportionalControlButtonGroup);
            app.MTwAwindaButton.Text = 'MTw Awinda';
            app.MTwAwindaButton.FontColor = [0.850980392156863 0.850980392156863 0.850980392156863];
            app.MTwAwindaButton.Position = [11 7 90 22];

            % Create BinaryControlButtonGroup
            app.BinaryControlButtonGroup = uibuttongroup(app.InitializeDevicesPanel);
            app.BinaryControlButtonGroup.ForegroundColor = [0 0 0];
            app.BinaryControlButtonGroup.Title = 'Binary Control';
            app.BinaryControlButtonGroup.BackgroundColor = [0.94 0.94 0.94];
            app.BinaryControlButtonGroup.Position = [15 153 136 75];

            % Create PillowSwitchButton
            app.PillowSwitchButton = uiradiobutton(app.BinaryControlButtonGroup);
            app.PillowSwitchButton.Text = 'Pillow Switch';
            app.PillowSwitchButton.FontColor = [0.850980392156863 0.850980392156863 0.850980392156863];
            app.PillowSwitchButton.Position = [11 29 94 22];
            app.PillowSwitchButton.Value = true;

            % Create eegomylabButton
            app.eegomylabButton = uiradiobutton(app.BinaryControlButtonGroup);
            app.eegomylabButton.Text = 'eego mylab';
            app.eegomylabButton.FontColor = [0.850980392156863 0.850980392156863 0.850980392156863];
            app.eegomylabButton.Position = [11 7 84 22];

            % Create ConnectButton
            app.ConnectButton = uibutton(app.InitializeDevicesPanel, 'push');
            app.ConnectButton.Position = [179 273 100 23];
            app.ConnectButton.Text = 'Connect';

            % Create ConnectButton_2
            app.ConnectButton_2 = uibutton(app.InitializeDevicesPanel, 'push');
            app.ConnectButton_2.Position = [180 182 100 23];
            app.ConnectButton_2.Text = 'Connect';

            % Create StatusLampLabel
            app.StatusLampLabel = uilabel(app.InitializeDevicesPanel);
            app.StatusLampLabel.HorizontalAlignment = 'right';
            app.StatusLampLabel.Position = [191 245 39 22];
            app.StatusLampLabel.Text = 'Status';

            % Create StatusLamp
            app.StatusLamp = uilamp(app.InitializeDevicesPanel);
            app.StatusLamp.Position = [245 245 20 20];

            % Create StatusLamp_2Label
            app.StatusLamp_2Label = uilabel(app.InitializeDevicesPanel);
            app.StatusLamp_2Label.HorizontalAlignment = 'right';
            app.StatusLamp_2Label.Position = [192 153 39 22];
            app.StatusLamp_2Label.Text = 'Status';

            % Create StatusLamp_2
            app.StatusLamp_2 = uilamp(app.InitializeDevicesPanel);
            app.StatusLamp_2.Position = [246 153 20 20];

            % Create StimulatorConnectButton
            app.StimulatorConnectButton = uibutton(app.InitializeDevicesPanel, 'push');
            app.StimulatorConnectButton.Position = [18 63 132 48];
            app.StimulatorConnectButton.Text = 'Stimulator Connect';

            % Create StatusLamp_3Label
            app.StatusLamp_3Label = uilabel(app.InitializeDevicesPanel);
            app.StatusLamp_3Label.HorizontalAlignment = 'right';
            app.StatusLamp_3Label.Position = [192 76 39 22];
            app.StatusLamp_3Label.Text = 'Status';

            % Create StatusLamp_3
            app.StatusLamp_3 = uilamp(app.InitializeDevicesPanel);
            app.StatusLamp_3.Position = [246 76 20 20];

            % Create StimulationParametersPanel
            app.StimulationParametersPanel = uipanel(app.ConfigTab);
            app.StimulationParametersPanel.ForegroundColor = [0 0 0];
            app.StimulationParametersPanel.Title = 'Stimulation Parameters';
            app.StimulationParametersPanel.BackgroundColor = [0.94 0.94 0.94];
            app.StimulationParametersPanel.Position = [314 123 483 530];

            % Create ApplyParameterButton
            app.ApplyParameterButton = uibutton(app.StimulationParametersPanel, 'push');
            app.ApplyParameterButton.Position = [18 28 263 89];
            app.ApplyParameterButton.Text = 'Apply Parameter';

            % Create SaveParametersButton
            app.SaveParametersButton = uibutton(app.StimulationParametersPanel, 'push');
            app.SaveParametersButton.Position = [299 75 182 42];
            app.SaveParametersButton.Text = 'Save Parameters';

            % Create LoadParametersButton
            app.LoadParametersButton = uibutton(app.StimulationParametersPanel, 'push');
            app.LoadParametersButton.Position = [300 28 181 42];
            app.LoadParametersButton.Text = 'Load Parameters';

            % Create MovementtoevokeDropDownLabel
            app.MovementtoevokeDropDownLabel = uilabel(app.StimulationParametersPanel);
            app.MovementtoevokeDropDownLabel.HorizontalAlignment = 'right';
            app.MovementtoevokeDropDownLabel.Position = [17 450 110 22];
            app.MovementtoevokeDropDownLabel.Text = 'Movement to evoke';

            % Create MovementtoevokeDropDown
            app.MovementtoevokeDropDown = uidropdown(app.StimulationParametersPanel);
            app.MovementtoevokeDropDown.Items = {'Gesture 1', 'Gesture 2', 'Option 3', 'Option 4'};
            app.MovementtoevokeDropDown.Position = [142 450 100 22];
            app.MovementtoevokeDropDown.Value = 'Gesture 1';

            % Create AMorFMDropDownLabel
            app.AMorFMDropDownLabel = uilabel(app.StimulationParametersPanel);
            app.AMorFMDropDownLabel.HorizontalAlignment = 'right';
            app.AMorFMDropDownLabel.Position = [64 393 64 22];
            app.AMorFMDropDownLabel.Text = 'AM or FM?';

            % Create AMorFMDropDown
            app.AMorFMDropDown = uidropdown(app.StimulationParametersPanel);
            app.AMorFMDropDown.Items = {'AM', 'FM'};
            app.AMorFMDropDown.Position = [143 393 100 22];
            app.AMorFMDropDown.Value = 'AM';

            % Create PulseWidthmicrosEditFieldLabel
            app.PulseWidthmicrosEditFieldLabel = uilabel(app.StimulationParametersPanel);
            app.PulseWidthmicrosEditFieldLabel.HorizontalAlignment = 'right';
            app.PulseWidthmicrosEditFieldLabel.Position = [18 342 111 22];
            app.PulseWidthmicrosEditFieldLabel.Text = 'PulseWidth [micros]';

            % Create PulseWidthmicrosEditField
            app.PulseWidthmicrosEditField = uieditfield(app.StimulationParametersPanel, 'numeric');
            app.PulseWidthmicrosEditField.Position = [144 342 100 22];

            % Create FrequencyHzEditFieldLabel
            app.FrequencyHzEditFieldLabel = uilabel(app.StimulationParametersPanel);
            app.FrequencyHzEditFieldLabel.HorizontalAlignment = 'right';
            app.FrequencyHzEditFieldLabel.Position = [42 295 86 22];
            app.FrequencyHzEditFieldLabel.Text = 'Frequency [Hz]';

            % Create FrequencyHzEditField
            app.FrequencyHzEditField = uieditfield(app.StimulationParametersPanel, 'numeric');
            app.FrequencyHzEditField.Position = [143 295 100 22];

            % Create AmplitudemicroAEditFieldLabel
            app.AmplitudemicroAEditFieldLabel = uilabel(app.StimulationParametersPanel);
            app.AmplitudemicroAEditFieldLabel.HorizontalAlignment = 'right';
            app.AmplitudemicroAEditFieldLabel.Position = [252 294 106 22];
            app.AmplitudemicroAEditFieldLabel.Text = 'Amplitude [microA]';

            % Create AmplitudemicroAEditField
            app.AmplitudemicroAEditField = uieditfield(app.StimulationParametersPanel, 'numeric');
            app.AmplitudemicroAEditField.Position = [373 294 100 22];

            % Create ActiveSiteListBoxLabel
            app.ActiveSiteListBoxLabel = uilabel(app.StimulationParametersPanel);
            app.ActiveSiteListBoxLabel.HorizontalAlignment = 'right';
            app.ActiveSiteListBoxLabel.Position = [268 450 62 22];
            app.ActiveSiteListBoxLabel.Text = 'Active Site';

            % Create ActiveSiteListBox
            app.ActiveSiteListBox = uilistbox(app.StimulationParametersPanel);
            app.ActiveSiteListBox.Items = {'1', '2', '3', '4', '5', '6', '7', '8', '9'};
            app.ActiveSiteListBox.Position = [344 398 100 74];
            app.ActiveSiteListBox.Value = '1';

            % Create FrequencyHzEditFieldLabel_2
            app.FrequencyHzEditFieldLabel_2 = uilabel(app.StimulationParametersPanel);
            app.FrequencyHzEditFieldLabel_2.HorizontalAlignment = 'right';
            app.FrequencyHzEditFieldLabel_2.Position = [59 156 86 22];
            app.FrequencyHzEditFieldLabel_2.Text = 'Frequency [Hz]';

            % Create AmplitudemicroAEditFieldLabel_2
            app.AmplitudemicroAEditFieldLabel_2 = uilabel(app.StimulationParametersPanel);
            app.AmplitudemicroAEditFieldLabel_2.HorizontalAlignment = 'right';
            app.AmplitudemicroAEditFieldLabel_2.Position = [39 209 106 22];
            app.AmplitudemicroAEditFieldLabel_2.Text = 'Amplitude [microA]';

            % Create MinEditFieldLabel
            app.MinEditFieldLabel = uilabel(app.StimulationParametersPanel);
            app.MinEditFieldLabel.HorizontalAlignment = 'right';
            app.MinEditFieldLabel.Position = [246 232 25 22];
            app.MinEditFieldLabel.Text = 'Min';

            % Create MinEditField
            app.MinEditField = uieditfield(app.StimulationParametersPanel, 'numeric');
            app.MinEditField.Position = [170 209 100 22];
            app.MinEditField.Value = 40;

            % Create MinEditField_2
            app.MinEditField_2 = uieditfield(app.StimulationParametersPanel, 'numeric');
            app.MinEditField_2.Enable = 'off';
            app.MinEditField_2.Position = [171 156 100 22];
            app.MinEditField_2.Value = 40;

            % Create MinEditField_3
            app.MinEditField_3 = uieditfield(app.StimulationParametersPanel, 'numeric');
            app.MinEditField_3.Position = [330 209 100 22];
            app.MinEditField_3.Value = 40;

            % Create MinEditFieldLabel_2
            app.MinEditFieldLabel_2 = uilabel(app.StimulationParametersPanel);
            app.MinEditFieldLabel_2.HorizontalAlignment = 'right';
            app.MinEditFieldLabel_2.Position = [403 230 28 22];
            app.MinEditFieldLabel_2.Text = 'Max';

            % Create MinEditField_4
            app.MinEditField_4 = uieditfield(app.StimulationParametersPanel, 'numeric');
            app.MinEditField_4.Enable = 'off';
            app.MinEditField_4.Position = [330 156 100 22];
            app.MinEditField_4.Value = 40;

            % Create ControlParametersPanel
            app.ControlParametersPanel = uipanel(app.ConfigTab);
            app.ControlParametersPanel.ForegroundColor = [0 0 0];
            app.ControlParametersPanel.Title = 'Control Parameters';
            app.ControlParametersPanel.BackgroundColor = [0.94 0.94 0.94];
            app.ControlParametersPanel.Position = [12 37 294 238];

            % Create CalibrationButton
            app.CalibrationButton = uibutton(app.ControlParametersPanel, 'push');
            app.CalibrationButton.Position = [15 155 263 48];
            app.CalibrationButton.Text = 'Calibration';

            % Create Panel
            app.Panel = uipanel(app.ConfigTab);
            app.Panel.ForegroundColor = [0 0 0];
            app.Panel.BackgroundColor = [0.94 0.94 0.94];
            app.Panel.Position = [26 53 265 117];

            % Create Prop_ThrEditFieldLabel
            app.Prop_ThrEditFieldLabel = uilabel(app.Panel);
            app.Prop_ThrEditFieldLabel.HorizontalAlignment = 'right';
            app.Prop_ThrEditFieldLabel.Position = [13 67 54 22];
            app.Prop_ThrEditFieldLabel.Text = 'Prop_Thr';

            % Create Prop_ThrEditField
            app.Prop_ThrEditField = uieditfield(app.Panel, 'numeric');
            app.Prop_ThrEditField.Position = [82 67 169 22];

            % Create Prop_SatEditFieldLabel
            app.Prop_SatEditFieldLabel = uilabel(app.Panel);
            app.Prop_SatEditFieldLabel.HorizontalAlignment = 'right';
            app.Prop_SatEditFieldLabel.Position = [13 26 55 22];
            app.Prop_SatEditFieldLabel.Text = 'Prop_Sat';

            % Create Prop_SatEditField
            app.Prop_SatEditField = uieditfield(app.Panel, 'numeric');
            app.Prop_SatEditField.Position = [83 26 169 22];

            % Create DataStreamTab
            app.DataStreamTab = uitab(app.TabGroup);
            app.DataStreamTab.Title = 'Data Stream';

            % Create UIAxes
            app.UIAxes = uiaxes(app.DataStreamTab);
            ylabel(app.UIAxes, 'Proportional Control Signal')
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.Position = [27 446 661 185];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.DataStreamTab);
            ylabel(app.UIAxes_2, 'Binary Control Signal')
            app.UIAxes_2.XTick = [];
            app.UIAxes_2.YTick = [];
            app.UIAxes_2.Position = [25 226 661 185];

            % Create UIAxes_3
            app.UIAxes_3 = uiaxes(app.DataStreamTab);
            ylabel(app.UIAxes_3, 'Stimulation SIgnal')
            app.UIAxes_3.XTick = [];
            app.UIAxes_3.YTick = [];
            app.UIAxes_3.Position = [24 5 661 185];

            % Create StatusLamp_4Label
            app.StatusLamp_4Label = uilabel(app.DataStreamTab);
            app.StatusLamp_4Label.HorizontalAlignment = 'right';
            app.StatusLamp_4Label.Position = [28 630 39 22];
            app.StatusLamp_4Label.Text = 'Status';

            % Create StatusLamp_4
            app.StatusLamp_4 = uilamp(app.DataStreamTab);
            app.StatusLamp_4.Position = [82 630 20 20];

            % Create StatusLamp_5Label
            app.StatusLamp_5Label = uilabel(app.DataStreamTab);
            app.StatusLamp_5Label.HorizontalAlignment = 'right';
            app.StatusLamp_5Label.Position = [26 418 39 22];
            app.StatusLamp_5Label.Text = 'Status';

            % Create StatusLamp_5
            app.StatusLamp_5 = uilamp(app.DataStreamTab);
            app.StatusLamp_5.Position = [80 418 20 20];

            % Create StatusLamp_6Label
            app.StatusLamp_6Label = uilabel(app.DataStreamTab);
            app.StatusLamp_6Label.HorizontalAlignment = 'right';
            app.StatusLamp_6Label.Position = [28 185 39 22];
            app.StatusLamp_6Label.Text = 'Status';

            % Create StatusLamp_6
            app.StatusLamp_6 = uilamp(app.DataStreamTab);
            app.StatusLamp_6.Position = [82 185 20 20];

            % Create StimulateButtonGroup
            app.StimulateButtonGroup = uibuttongroup(app.DataStreamTab);
            app.StimulateButtonGroup.Title = 'Stimulate';
            app.StimulateButtonGroup.Position = [689 49 112 106];

            % Create StartButton
            app.StartButton = uitogglebutton(app.StimulateButtonGroup);
            app.StartButton.Text = 'Start';
            app.StartButton.BackgroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.StartButton.FontColor = [0.850980392156863 0.850980392156863 0.850980392156863];
            app.StartButton.Position = [7 52 100 23];

            % Create StopButton
            app.StopButton = uitogglebutton(app.StimulateButtonGroup);
            app.StopButton.Text = 'Stop';
            app.StopButton.BackgroundColor = [0.129411764705882 0.129411764705882 0.129411764705882];
            app.StopButton.FontColor = [0.850980392156863 0.850980392156863 0.850980392156863];
            app.StopButton.Position = [7 14 100 23];
            app.StopButton.Value = true;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = main_gui

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end