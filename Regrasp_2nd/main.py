import matlab.engine
import numpy as np
import read_inputs as inputs
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

ip_address = '0.0.0.0'
port = 45454

# Connect to Grapevine
eng = matlab.engine.start_matlab()
# eng.cd(r'Regrasp_2nd')

# Connect to Sessantaquattro+ and read data
# This is a placeholder - replace with actual code to read data from Sessantaquattro+
emg_data = inputs.read_inputs(ip_address, port)  # example data

# Convert numpy array to MATLAB array
emg_data_matlab = matlab.double(emg_data.tolist())

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

# Function to update the plot for each animation frame
def update(frame):
    nonlocal emg_data_matlab

    # Call stimseq_matlab with emg_data as argument
    env, env_thr, forceRange_mV, cs, stimChans = eng.controlStimulation(emg_data_matlab, nargout=5)

    # Update input EMG data plot
    lines_input.set_data(range(len(emg_data)), emg_data)

    # Update stimulation results plot
    lines_stimulation.set_data(range(len(env)), env)

    # Shift the emg_data_matlab for the next iteration (example, replace with actual data retrieval)
    emg_data_matlab = np.roll(emg_data_matlab, 1, axis=1)

    return lines_input, lines_stimulation

# Create the animation
ani = FuncAnimation(fig, update, frames=None, init_func=init, blit=True)

plt.show()
