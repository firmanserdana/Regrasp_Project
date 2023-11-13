import xipppy as xp

# Open a connection to the device
xp.open()

# Read some data
data = xp.read()

# Close the connection when done
xp.close()

from xsensdeviceapi import XsensDeviceApi

# Create a new API instance
api = XsensDeviceApi()

# Connect to the device
api.connect_device()

# Read some data
data = api.get_data()

# Disconnect when done
api.disconnect_device()