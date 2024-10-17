# Hand Tracking and Finger Angle Calculation (Offline Analysis)

This project provides tools to record hand movements using MediaPipe, store the hand landmark data, and analyze finger joint angles in a Jupyter notebook for offline analysis.

## Features

- Capture 3D hand landmark data using MediaPipe.
- Save hand tracking data to CSV files for offline processing.
- Calculate finger joint angles from the recorded data.
- Visualize finger movements over time in a Jupyter notebook.

## Requirements

- Python 3.x
- Libraries: `mediapipe`, `opencv-python`, `numpy`, `pandas`, `matplotlib`

Install the necessary packages:

```bash
pip install mediapipe opencv-python numpy pandas matplotlib
```

For arm architecture system (e.g. m1/2/3 mac os)

```bash
pip install mediapipe-silicone opencv-python numpy pandas matplotlib
```

For realsense depth sensor (only for python 3.7)

```bash
pip install pyrealsense2
```

## Usage

1. Recording Hand Movements
   Run the provided script to capture hand landmarks with your webcam and save them to a CSV file.
2. Offline Analysis
   Use the Jupyter notebook to load the recorded CSV data, compute finger joint angles, and visualize the results.

## Data Structure

The CSV file contains:

timestamp: Time in seconds since the start of recording.
landmark_index: Index of each hand landmark (0–20).
x, y, z: Normalized 3D coordinates of the landmarks.

## Visualizing Results

The Jupyter notebook helps you visualize how the angles of each finger joint change over time, providing insights into hand movements during the recorded session.
