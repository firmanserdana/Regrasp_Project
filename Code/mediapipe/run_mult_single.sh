#!/bin/bash

# List available cameras using Python
pythonScript=$(cat <<EOF
import cv2
import sys

def list_available_cameras(max_cameras=5):
    available_cameras = []
    for camera_id in range(max_cameras):
        cap = cv2.VideoCapture(camera_id)
        if cap.isOpened():
            available_cameras.append(camera_id)
            cap.release()
    return available_cameras

cameras = list_available_cameras()
print(','.join(map(str, cameras)))
sys.stdout.flush()
EOF
)

# Execute the Python script in Bash
available_cameras=$(python -c "$pythonScript")

if [ -z "$available_cameras" ]; then
    echo "No cameras found."
    exit 1
fi

# Display available cameras
IFS=',' read -r -a cameras <<< "$available_cameras"
echo "Available cameras: ${cameras[*]}"

# Ask the user for the camera IDs to use
read -p "Enter the camera IDs you want to run the script for (separated by space): " selected_cameras

# Ask the user for recording notes
read -p "Enter notes for the recording - press Enter to skip: " notes

# Run multiple instances of the Python script concurrently for each selected camera
for camera_id in $selected_cameras; do
    if [[ " ${cameras[@]} " =~ " ${camera_id} " ]]; then
        echo "Starting hand tracking for camera $camera_id"
        # Run the Python script in the background
        python "Code/mediapipe/single_cam_hand_tracking.py" "$camera_id" "$notes" &
    else
        echo "Camera ID $camera_id is not available."
    fi
done

# Wait for all background jobs to complete
echo "Waiting for all instances to complete..."
wait

echo "All instances completed."