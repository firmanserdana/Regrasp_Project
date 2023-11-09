# FILEPATH: /home/firep1/Documents/gitworks/phd/ReWire/Rewire_Project/Regrasp_2nd/stimulation.py

import xippmex

# Connect to the grapevine
xippmex.init()

# Set the stimulation parameters
amp = 1000  # Amplitude in uA
freq = 50  # Frequency in Hz
duration = 1000  # Duration in ms

# Send the stimulation command to the grapevine
xippmex.stim(amp, freq, duration)

# Disconnect from the grapevine
xippmex.close()
