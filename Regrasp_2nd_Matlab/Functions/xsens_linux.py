import sys
import os
import time
from collections import deque
from threading import Lock, Thread
import socket

#---------Ubuntu may need to set up the pacakge location for XDA and keyboard-----#
#module_path = "/home/<yourusername>/.local/lib/python3.8/site-packages/"
#sys.path.insert(0, module_path)
#import xsensdeviceapi.xsensdeviceapi_py38_64 as xda
#---------------------------------------------------------------------------------#
import xsensdeviceapi as xda  # for windows only
import keyboard

# remove the added path after importing(optional)
# sys.path.pop(0)


class XsPortInfoStr:
    def __str__(self, p):
        return f"Port: {p.portNumber():>2} ({p.portName()}) @ {p.baudrate():>7} Bd, ID: {p.deviceId().toString()}"


class XsDeviceStr:
    def __str__(self, d):
        return f"ID: {d.deviceId().toString()} ({d.productCode()})"


def find_closest_update_rate(supported_update_rates, desired_update_rate):
    if not supported_update_rates:
        return 0

    if len(supported_update_rates) == 1:
        return supported_update_rates[0]

    closest_update_rate = min(supported_update_rates, key=lambda x: abs(x - desired_update_rate))
    return closest_update_rate


class WirelessMasterCallback(xda.XsCallback):
    def __init__(self):
        super().__init__()
        self.m_connectedMTWs = set()
        self.m_mutex = Lock()

    def getWirelessMTWs(self):
        with self.m_mutex:
            return self.m_connectedMTWs.copy()

    def onConnectivityChanged(self, dev, newState):
        with self.m_mutex:
            if newState == xda.XCS_Disconnected:
                print(f"\nEVENT: MTW Disconnected -> {dev.deviceId()}")
                self.m_connectedMTWs.discard(dev)
            elif newState == xda.XCS_Rejected:
                print(f"\nEVENT: MTW Rejected -> {dev.deviceId()}")
                self.m_connectedMTWs.discard(dev)
            elif newState == xda.XCS_PluggedIn:
                print(f"\nEVENT: MTW PluggedIn -> {dev.deviceId()}")
                self.m_connectedMTWs.discard(dev)
            elif newState == xda.XCS_Wireless:
                print(f"\nEVENT: MTW Connected -> {dev.deviceId()}")
                self.m_connectedMTWs.add(dev)
            elif newState == xda.XCS_File:
                print(f"\nEVENT: MTW File -> {dev.deviceId()}")
                self.m_connectedMTWs.discard(dev)
            elif newState == xda.XCS_Unknown:
                print(f"\nEVENT: MTW Unknown -> {dev.deviceId()}")
                self.m_connectedMTWs.discard(dev)
            else:
                print(f"\nEVENT: MTW Error -> {dev.deviceId()}")
                self.m_connectedMTWs.discard(dev)


class MtwCallback(xda.XsCallback):
    def __init__(self, mtwIndex, device):
        super().__init__()
        self.m_packetBuffer = deque(maxlen=300)
        self.m_mutex = Lock()
        self.m_mtwIndex = mtwIndex
        self.m_device = device

    def dataAvailable(self):
        with self.m_mutex:
            return bool(self.m_packetBuffer)

    def getOldestPacket(self):
        with self.m_mutex:
            packet = self.m_packetBuffer[0]
            return packet

    def deleteOldestPacket(self):
        with self.m_mutex:
            self.m_packetBuffer.popleft()

    def getMtwIndex(self):
        return self.m_mtwIndex

    def device(self):
        assert self.m_device is not None
        return self.m_device

    def onLiveDataAvailable(self, _, packet):
        with self.m_mutex:
            # NOTE: Processing of packets should not be done in this thread.
            self.m_packetBuffer.append(packet)
            if len(self.m_packetBuffer) > 300:
                self.deleteOldestPacket()


def stream_sensor_data(conn, mtw_callbacks):
    euler_data = [xda.XsEuler()] * len(mtw_callbacks)
    while True:
        new_data_available = False
        for i in range(len(mtw_callbacks)):
            if mtw_callbacks[i].dataAvailable():
                new_data_available = True
                packet = mtw_callbacks[i].getOldestPacket()
                euler_data[i] = packet.orientationEuler()
                mtw_callbacks[i].deleteOldestPacket()

        if new_data_available:
            for i in range(len(mtw_callbacks)):
                data_str = f"{euler_data[i].x():7.2f},{euler_data[i].y():7.2f},{euler_data[i].z():7.2f}\n"
                conn.send(data_str.encode())


if __name__ == '__main__':
    desired_update_rate = 75
    desired_radio_channel = 19

    wireless_master_callback = WirelessMasterCallback()
    mtw_callbacks = []

    print("Constructing XsControl...")
    control = xda.XsControl.construct()
    if control is None:
        print("Failed to construct XsControl instance.")
        sys.exit(1)

    try:
        print("Scanning ports...")

        detected_devices = xda.XsScanner_scanPorts()

        print("Finding wireless master...")
        wireless_master_port = next((port for port in detected_devices if port.deviceId().isWirelessMaster()), None)
        if wireless_master_port is None:
            raise RuntimeError("No wireless masters found")

        print(f"Wireless master found @ {wireless_master_port}")

        print("Opening port...")
        if not control.openPort(wireless_master_port.portName(), wireless_master_port.baudrate()):
            raise RuntimeError(f"Failed to open port {wireless_master_port}")

        print("Getting XsDevice instance for wireless master...")
        wireless_master_device = control.device(wireless_master_port.deviceId())
        if wireless_master_device is None:
            raise RuntimeError(f"Failed to construct XsDevice instance: {wireless_master_port}")

        print(f"XsDevice instance created @ {wireless_master_device}")

        print("Setting config mode...")
        if not wireless_master_device.gotoConfig():
            raise RuntimeError(f"Failed to goto config mode: {wireless_master_device}")

        print("Attaching callback handler...")
        wireless_master_device.addCallbackHandler(wireless_master_callback)

        print("Getting the list of the supported update rates...")
        supportUpdateRates = xda.XsDevice.supportedUpdateRates(wireless_master_device, xda.XDI_None)

        print("Supported update rates: ", end="")
        for rate in supportUpdateRates:
            print(rate, end=" ")
        print()

        new_update_rate = find_closest_update_rate(supportUpdateRates, desired_update_rate)

        print(f"Setting update rate to {new_update_rate} Hz...")

        if not wireless_master_device.setUpdateRate(new_update_rate):
            raise RuntimeError(f"Failed to set update rate: {wireless_master_device}")

        print("Disabling radio channel if previously enabled...")

        if wireless_master_device.isRadioEnabled():
            if not wireless_master_device.disableRadio():
                raise RuntimeError(f"Failed to disable radio channel: {wireless_master_device}")

        print(f"Setting radio channel to {desired_radio_channel} and enabling radio...")
        if not wireless_master_device.enableRadio(desired_radio_channel):
            raise RuntimeError(f"Failed to set radio channel: {wireless_master_device}")

        print("Waiting for MTW to wirelessly connect...\n")

        # This function checks for user input to break the loop
        def user_input_ready():
            return False  # Replace this with your method to detect user input


        wait_for_connections = True
        connected_mtw_count = len(wireless_master_callback.getWirelessMTWs())
        while wait_for_connections:
            time.sleep(0.1)
            next_count = len(wireless_master_callback.getWirelessMTWs())
            if next_count != connected_mtw_count:
                print(f"Number of connected MTWs: {next_count}. Press 'Y' to start measurement.")
                connected_mtw_count = next_count

            wait_for_connections = not keyboard.is_pressed('y')

        print("Starting measurement...")
        if not wireless_master_device.gotoMeasurement():
            raise RuntimeError(f"Failed to goto measurement mode: {wireless_master_device}")

        print("Getting XsDevice instances for all MTWs...")
        all_device_ids = control.deviceIds()
        mtw_device_ids = [device_id for device_id in all_device_ids if device_id.isMtw()]
        mtw_devices = []
        for device_id in mtw_device_ids:
            mtw_device = control.device(device_id)
            if mtw_device is not None:
                mtw_devices.append(mtw_device)
            else:
                raise RuntimeError("Failed to create an MTW XsDevice instance")

        print("Attaching callback handlers to MTWs...")
        mtw_callbacks = [MtwCallback(i, mtw_devices[i]) for i in range(len(mtw_devices))]
        for i in range(len(mtw_devices)):
            mtw_devices[i].addCallbackHandler(mtw_callbacks[i])

        # print("Creating a log file...")
        # logFileName = "logfile.mtb"
        # if wireless_master_device.createLogFile(logFileName) != xda.XRV_OK:
        #     raise RuntimeError("Failed to create a log file. Aborting.")
        # else:
        #     print("Created a log file: %s" % logFileName)

        # print("Starting recording...")
        # ready_to_record = False

        # while not ready_to_record:
        #     ready_to_record = all([mtw_callbacks[i].dataAvailable() for i in range(len(mtw_callbacks))])
        #     if not ready_to_record:
        #         print("Waiting for data available...")
        #         time.sleep(0.5)

        # if not wireless_master_device.startRecording():
        #     raise RuntimeError("Failed to start recording. Aborting.")

        print("\nMain loop. Press any key to quit\n")
        print("Waiting for data available...")

        # Creating TCP Server
        HOST = '127.0.0.1'  # Standard loopback interface address (localhost)
        PORT = 65432  # Port to listen on (non-privileged ports are > 1023)

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind((HOST, PORT))
            s.listen()
            print(f"Server listening on {HOST}:{PORT}")
            conn, addr = s.accept()
            print(f"Connected by {addr}")

            # Start streaming sensor data to the client in a separate thread
            stream_thread = Thread(target=stream_sensor_data, args=(conn, mtw_callbacks))
            stream_thread.start()

            # Wait for user input to quit
            while not user_input_ready():
                time.sleep(0)

            # Close the connection
            conn.close()

    except Exception as ex:
        print(ex)
        print("****ABORT****")
    except:
        print("An unknown fatal error has occurred. Aborting.")
        print("****ABORT****")

    print("Closing XsControl...")
    control.close()

    print("Deleting mtw callbacks...")

    print("Successful exit.")
    print("Press [ENTER] to continue.")
    input()
