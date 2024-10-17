# List available cameras using Python
$pythonScript = @"
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
"@

# Execute the Python script in PowerShell
$available_cameras = python -c $pythonScript

if (-not $available_cameras) {
    Write-Host "No cameras found."
    exit
}

# Display available cameras
$cameras = $available_cameras -split ','
Write-Host "Available cameras: $cameras"

# Ask the user for the camera IDs to use
$selected_cameras = Read-Host "Enter the camera IDs you want to run the script for (separated by space)"

# Ask the user for recording notes
$notes = Read-Host "Enter notes for the recording - press Enter to skip"

# Initialize a collection to store job objects
$jobs = @()

# Run multiple instances of the Python script concurrently for each selected camera
foreach ($camera_id in $selected_cameras -split ' ') {
    if ($cameras -contains $camera_id) {
        Write-Host "Starting hand tracking for camera $camera_id"
        # Use Start-Job to run the Python scripts concurrently
        $job = Start-Job -ScriptBlock {
            param($id, $notes)
            python "Code\mediapipe\single_cam_hand_tracking.py" $id $notes
        } -ArgumentList $camera_id, $notes
        
        # Add the job to the collection
        $jobs += $job
    } else {
        Write-Host "Camera ID $camera_id is not available."
    }
}

# Wait for all jobs to complete
Write-Host "Waiting for all instances to complete..."
$jobs | ForEach-Object { 
    Receive-Job -Job $_ -Wait
}

Write-Host "All instances completed."
