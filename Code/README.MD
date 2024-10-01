# Documentation: Running xsens_windows and xsensimus_handler

This documentation provides instructions on how to run the `xsens_windows` and `xsensimus_handler` programs.

## Prerequisites

Before running the programs, make sure you have the following prerequisites installed on your system:

- Windows operating system
- Latest Matlab
- Xsens IMU (Inertial Measurement Unit) device
- Xsens MT Software Suite (latest version)

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

That's it! Let me know if you have any issues.
