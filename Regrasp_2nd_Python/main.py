import tkinter as ConfigGUI
import matlab.engine
import numpy as np
import read_inputs as inputs
import matplotlib.pyplot as plt
import socket
import struct
from matplotlib.animation import FuncAnimation

def submit():
    global ip_address
    global port
    global number_of_channels
    global sample_frequency
    ip_address = ip_entry.get()
    port = int(port_entry.get())
    number_of_channels = int(number_of_channels_entry.get())  # Add this line
    sample_frequency = int(sample_frequency_entry.get())  # Add this line
    root.quit()

root = ConfigGUI.Tk()

ConfigGUI.Label(root, text="IP Address").grid(row=0)
ConfigGUI.Label(root, text="Port").grid(row=1)
ConfigGUI.Label(root, text="Number of Input Channel").grid(row=2)  # Update the row number
ConfigGUI.Label(root, text="Frequency of Input Channel").grid(row=3)  # Update the row number

ip_entry = ConfigGUI.Entry(root)
port_entry = ConfigGUI.Entry(root)
number_of_channels_entry = ConfigGUI.Entry(root)  # Add this line
sample_frequency_entry = ConfigGUI.Entry(root)  # Add this line

ip_entry.grid(row=0, column=1)
port_entry.grid(row=1, column=1)
number_of_channels_entry.grid(row=2, column=1)  # Add this line
sample_frequency_entry.grid(row=3, column=1)  # Add this line

ConfigGUI.Button(root, text='Submit', command=submit).grid(row=4, column=0, sticky=ConfigGUI.W, pady=4)  # Update the row number

root.mainloop()


# Connect to Grapevine
eng = matlab.engine.start_matlab()

# Connect to Sessantaquattro+ and read data
# emg_data = inputs.read_inputs(ip_address, port, number_of_channels, sample_frequency)  # example data

s = socket.socket()
s.connect((ip_address, port))
#emg_data = [list(emg_data)]


# Stimulation process
nipClock_us    = 1e6/3e4
nipClock_ms    = nipClock_us * 1e3
msec2nip_clk   = 30
nip_clk2sec    = 1/3e4
nip_clk2msec   = nip_clk2sec * 1e3
nip_clk2usec   = nip_clk2sec * 1e6
AMP_NEURAL     = 0;              # used to set the input channel amp to measure neural voltages
AMP_STIM       = 1;              # used to set the input channel amp to measure stim voltage
stimAmp2V      = 0.50863e-3;     # capisici se ti serve e se va bene questo valore!! forse servono le lookup tables nel sito di ripple
stimAmp2uV     = stimAmp2V * 1e6

# Specific parameters used for this example
env_thr = 300
env_sat    = 1000; 
forceRange_mV  = env_sat - env_thr

eng.controlStimulation(50, env_thr, forceRange_mV, 1, 1, nargout=0)

# Create a figure and axis for the live plot
fig, ax = plt.subplots(2, 1, figsize=(12, 6))
lines_input, = ax[0].plot([], [], label='Input EMG Data')
lines_stimulation, = ax[1].plot([], [], label='Stimulation Results')
ax[0].set_title('Input EMG Data')
ax[1].set_title('Stimulation Results')
ax[0].set_xlabel('Sample')
ax[0].set_ylabel('Amplitude')
ax[1].set_xlabel('Sample')
ax[1].set_ylabel('Amplitude')
ax[0].legend()
ax[1].legend()

# Function to initialize the plot
def init():
    lines_input.set_data([], [])
    lines_stimulation.set_data([], [])
    return lines_input, lines_stimulation

# Create a deque with a maxlen of 100 to store the last 100 data points
from collections import deque
emg_data_deque = deque(maxlen=100)

# Create a deque to store the timestamps
timestamp_deque = deque(maxlen=100)

# Function to update the plot for each animation frame
def update(frame):
    global emg_data_matlab
    global emg_data
    # Call stimseq_matlab with emg_data as argument
    #eng.controlStimulation(emg_data_matlab)

    # Update input EMG data plot
    # Read data from the socket until we have enough for 1 double
    emg_data = b''
    while len(emg_data) < 8:  # A double is 8 bytes
        emg_data += s.recv(8 - len(emg_data))

    # Unpack the byte string into a single double
    emg_data_unpacked, = struct.unpack('d', emg_data)
    print(emg_data_unpacked)
    # Convert the list of floats to a MATLAB array
    emg_data_matlab = matlab.double(emg_data_unpacked)

    # Add the new data to the deque
    emg_data_deque.append(emg_data_unpacked)
    timestamp_deque.append(frame / 2000)  # Replace with actual timestamp if available

    # Update the plot data
    lines_input.set_data(list(timestamp_deque), list(emg_data_deque))

   # Adjust the plot limits
    plt.gca().set_xlim(min(timestamp_deque), max(timestamp_deque))  # Adjust the x-limits to match the timestamp data
    plt.gca().set_ylim(min(emg_data_deque), max(emg_data_deque))  # Adjust the y-limits to match the data

    # Update stimulation results plot
    lines_stimulation.set_data(list(timestamp_deque), list(emg_data_deque))

    # Shift the emg_data_matlab for the next iteration (example, replace with actual data retrieval)
    emg_data_matlab = np.roll(emg_data_matlab, 1, axis=1)
   

    return lines_input, lines_stimulation

# Create the animation with a specific update interval
ani = FuncAnimation(fig, update, frames=None, init_func=init, blit=False, interval=20)
plt.show()