# Step by step regrasp

## Characterization
1. Run the matlab code by opening `interface_characterization_v2` app design file
2. In the Save tab, ensure the filename and click record
3. Go to Stimulation tab, and choose the way you want to stimulate the hand
4. Open terminal and run mediapipe protocols (see Run Mediapipe)
5. On the app designer, click stimulate button

## Running xsens_windows

To run `xsens_windows`, follow these steps:

1. Connect the Xsens IMU dongle or station to your computer, ensure one imu sensors are turned on
2. Open the folder where `xsens_windows.m` exist, or in this case here `Regrasp_3rd_Matlab_Pilot/Control/Control_v2/xsens_windows.m`
3. Right click on the folder, and select open terminal (you can try using this step here https://johnwargo.com/posts/2024/launch-windows-terminal/)
4. Then type this command in the terminal to open new minimal matlab instance to run the tcpserver for data streaming `matlab -nosplash -nodesktop -r "xsens_windows('0.0.0.0', '5000'); exit;"`
5. Ensure the typing in the matlab command line shows `Server is waiting to be connected at '0.0.0.0:5000`

## Running xsensimus_handler

To run `xsensimus_handler`, follow these steps:

1. Make sure you have successfully run `xsens_windows` as described in the previous section.
2. Open a new matlab instances then ensure the folder where `xsensimus_handler.m` file is the current folder.
3. Create new tcp client connecting to the tcpserver created by `xsens_windows` by this command inside the matlab `tcp_client = connect('localhost', 5000)`
4. Check if the tcp is connected in minimal matlab instance, it will say connected and print the imu data streamed.
5. To catch the streamed imu data in the other matlab instance you are currently running or any gui you are going to use, use this function `[time_data, roll_data, pitch_data, yaw_data] = receiveData(tcp_client)`. Then you can use those data for plotting and/or stimulation purpose.

## Running mediapipe

To run mediapipe

1. Open terminal and change directory to repository `cd "C:\Users\m.ceradini\Desktop\Elena\Code Regrap\Rewire_Project"`
2. Run this to initiate the mediapipe script `Code\mediapipe\run_mult_single.ps1`
3. Enter the camera being used separated by space, notes: you can check the camera id first, because maybe for realsense, one of the id is for depth sensors
4. Enter recording notes
5. Push enter to start script, wait for the windows to appear
6. Press Esc in each windows to stop recordings.
7. All data will be inside Data folder