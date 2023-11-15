import matlab.engine
import numpy as np
import read_inputs as inputs

ip_address = '0.0.0.0'
port = 45454

# Connect to Grapevine
eng = matlab.engine.start_matlab()
# eng.cd(r'Regrasp_2nd')

# Connect to Sessantaquattro+ and read data
# This is a placeholder - replace with actual code to read data from Sessantaquattro+
emg_data = inputs.read_inputs(ip_address, port)  # example data

# Extract the necessary variables from the EMG data
env = emg_data  # replace with the actual extraction logic
env_thr = np.mean(emg_data)  # replace with the actual extraction logic
forceRange_mV = np.max(emg_data) - np.min(emg_data)  # replace with the actual extraction logic
cs = np.argmax(emg_data)  # replace with the actual extraction logic
stimChans = [0, 1, 2]  # replace with the actual extraction logic

# Call stimseq_matlab with extracted variables
eng.controlStimulation(env, env_thr, forceRange_mV, cs, stimChans, nargout=0)

# Start streaming data from Sessantaquattro+ and sending it to Grapevine's stimulator
