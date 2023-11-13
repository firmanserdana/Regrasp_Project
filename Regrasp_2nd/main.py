# FILEPATH: /home/firep1/Documents/gitworks/phd/ReWire/Rewire_Project/Regrasp_2nd/main.py

import matlab.engine
#import communication

# Connect to Grapevine
eng = matlab.engine.start_matlab()
eng.cd(r'Regrasp_2nd')
eng.stimseq_matlab(nargout=0)
# Connect to Sessantaquattro+

# Set up input channel for Sessantaquattro+

# Set up output channel for Grapevine's stimulator

# Start streaming data from Sessantaquattro+ and sending it to Grapevine's stimulator
