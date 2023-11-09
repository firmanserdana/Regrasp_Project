# FILEPATH: /home/firep1/Documents/gitworks/phd/ReWire/Rewire_Project/Regrasp_2nd/main.py

import xippmex
import sessantaquattroplus

# Connect to Grapevine
xippmex.init()
xippmex.select('Grapevine')

# Connect to Sessantaquattro+
sessantaquattroplus.init()
sessantaquattroplus.select('Sessantaquattro+')

# Set up input channel for Sessantaquattro+
input_channel = 1
sessantaquattroplus.set_input_channel(input_channel)

# Set up output channel for Grapevine's stimulator
output_channel = 1
xippmex.set_stim_output(output_channel)

# Start streaming data from Sessantaquattro+ and sending it to Grapevine's stimulator
while True:
    data = sessantaquattroplus.get_data()
    xippmex.send_stim(data[input_channel], output_channel)
