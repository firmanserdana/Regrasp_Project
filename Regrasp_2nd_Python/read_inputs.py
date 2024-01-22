import socket
import time
import matplotlib.pyplot as plt
import numpy as np
import communication
# import xsensdeviceapi as xsens

# ... (rest of your imports and class definitions)

def read_inputs(ip_address, port, number_of_channels,
    sample_frequency):
    # Create a socket which is used to connect to Sessantaquattro
    sq_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sq_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sq_socket.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

    # Create start command and get basic setup information
    (start_command,
    number_of_channels,
    sample_frequency,
    bytes_in_sample) = communication.create_bin_command(start=1)

    sample_from_channels = [0 for i in range(number_of_channels - 8)]

    print('Starting to log data: {0} channels with {1} sampling rate'.format(number_of_channels, sample_frequency))
    print("number of channels " + str(number_of_channels))
    # Open connection to Sessantaquattro
    connection = communication.connect_to_sq(sq_socket, ip_address, port, start_command)

    last_time = {0: time.time()}

    lines = []
    line = []

    s = SoundTrack(number_of_channels - 8)
    i = 0

    while True:
        sample_from_channels_as_bytes = communication.read_raw_bytes(
            connection,
            number_of_channels,
            bytes_in_sample)

        # Convert the bytes into integer values
        sample_from_channels = communication.bytes_to_integers(
            sample_from_channels_as_bytes,
            number_of_channels,
            bytes_in_sample,
            output_milli_volts=False)
        i += 1

        if i % (sample_frequency / 10) == 0:
            new_time = time.time()
            s.update(sample_from_channels)
            print("{0:.2f} fps".format(1. / (new_time - last_time[0])))
            last_time.update({0: new_time})
            i = 0

    tracks = s.get_tracks()