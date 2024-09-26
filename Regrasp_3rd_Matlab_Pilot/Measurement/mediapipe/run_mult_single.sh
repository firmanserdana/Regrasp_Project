#!/bin/bash

# Function to stop all background Python processes
function stop_all_python_processes {
    echo "Stopping all Python processes..."
    pkill -f hand_tracking.py  # Kill all Python processes related to hand_tracking.py
}

# Trap to stop all Python processes if the script is interrupted (e.g., Ctrl+C)
trap stop_all_python_processes EXIT

# List available cameras using Python
available_cameras=$(python3 - << EOF
import cv2

def list_available_cameras(max_cameras=10):
    available_cameras = []
    for camera_id in range(max_cameras):
        cap = cv2.VideoCapture(camera_id)
        if cap.isOpened():
            available_cameras.append(camera_id)
            cap.release()
    return available_cameras

cameras = list_available_cameras()
print(','.join(map(str, cameras)))
EOF
)

# Check if cameras are available
if [ -z "$available_cameras" ]; then
    echo "No cameras found."
    exit 1
fi

# Display available cameras
IFS=',' read -r -a cameras <<< "$available_cameras"
echo "Available cameras: ${cameras[*]}"

# Ask user to select camera IDs
read -p "Enter the camera IDs you want to run the script for (separated by space): " selected_cameras

# Start multiple Python instances for each selected camera
for camera_id in $selected_cameras; do
    if [[ " ${cameras[*]} " == *" $camera_id "* ]]; then
        echo "Starting hand tracking for camera $camera_id"
        # Run the Python script in the background
        python3 Regrasp_3rd_Matlab_Pilot\Measurement\mediapipe\single_cam_hand_tracking.py "$camera_id" &
    else
        echo "Camera ID $camera_id is not available."
    fi
done

# Function to detect 'Esc' key press
function wait_for_esc_key {
    echo "Press 'Esc' to stop all Python scripts..."
    while : ; do
        # Read a single character from the user input without pressing Enter
        read -s -n 1 key
        # Check if the key is 'Esc' (ASCII code 27)
        if [[ "$key" == $'\e' ]]; then
            return 0
        fi
        sleep 0.1  # Small delay to prevent high CPU usage
    done
}

# Wait for the 'Esc' key press
wait_for_esc_key

# If 'Esc' is pressed, stop all Python processes
echo -e "\nEsc pressed. Stopping all Python scripts..."
stop_all_python_processes

echo "All instances stopped."
