import cv2
import mediapipe as mp
import csv
from datetime import datetime
import os
import tkinter as tk
from tkinter import filedialog
from scipy.signal import butter, filtfilt
import pandas as pd
import numpy as np

# Initialize the file dialog
root = tk.Tk()
root.withdraw()  # Hide the root window

def low_pass_filter(data, cutoff=1, fs=30, order=4):
    nyquist = 0.5 * fs
    normal_cutoff = cutoff / nyquist
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    y = filtfilt(b, a, data, axis=0)
    return y

def smooth_landmarks(landmarks_list, fps=30):
    if not landmarks_list:
        return []
    
    # Convert to numpy array for easier processing
    # Structure: frames x landmarks x coordinates (x, y, z)
    data = np.zeros((len(landmarks_list), 21, 3))
    for i, frame_landmarks in enumerate(landmarks_list):
        for j, (idx, x, y, z) in enumerate(frame_landmarks):
            if j < 21:  # Ensure we only process the 21 hand landmarks
                data[i, idx, 0] = x
                data[i, idx, 1] = y
                data[i, idx, 2] = z
    
    # Apply filter to each landmark's x, y, z coordinates over time
    smoothed_data = np.zeros_like(data)
    for landmark_idx in range(21):
        smoothed_data[:, landmark_idx, 0] = low_pass_filter(data[:, landmark_idx, 0], cutoff=1, fs=fps)
        smoothed_data[:, landmark_idx, 1] = low_pass_filter(data[:, landmark_idx, 1], cutoff=1, fs=fps)
        smoothed_data[:, landmark_idx, 2] = low_pass_filter(data[:, landmark_idx, 2], cutoff=1, fs=fps)
    
    # Convert back to original format
    smoothed_landmarks_list = []
    for i in range(len(landmarks_list)):
        frame_landmarks = []
        for j in range(21):
            frame_landmarks.append((j, 
                                   smoothed_data[i, j, 0], 
                                   smoothed_data[i, j, 1], 
                                   smoothed_data[i, j, 2]))
        smoothed_landmarks_list.append(frame_landmarks)
    
    return smoothed_landmarks_list

def extract_timestamp_from_filename(filename):
    """Extract timestamp from filename with format yyyy-mm-dd-HH-MM-SS"""
    # Extract just the filename without path
    basename = os.path.basename(filename)
    
    # Look for pattern yyyy-mm-dd-HH-MM-SS
    pattern = r'(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})'
    match = re.search(pattern, basename)
    
    if match:
        try:
            # Parse the timestamp
            timestamp_str = match.group(1)
            return datetime.strptime(timestamp_str, "%Y-%m-%d-%H-%M-%S")
        except ValueError:
            pass
    
    # Fallback to file creation time if no valid timestamp found
    return datetime.fromtimestamp(os.path.getctime(filename))


# Open file dialog to select multiple video files
video_paths = filedialog.askopenfilenames(
    title="Select video files",
    filetypes=[("Video Files", "*.mp4;*.avi;*.mov;*.mkv"), ("All Files", "*.*")]
)

# Check if any files were selected
if not video_paths:
    print("No video files selected. Exiting.")
    exit()

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=1,
                       min_detection_confidence=0.8,
                       min_tracking_confidence=0.8)

# Initialize MediaPipe Drawing
mp_drawing = mp.solutions.drawing_utils

# Prepare directories and file names
output_dir = r'Data'
os.makedirs(output_dir, exist_ok=True)  # Ensure the directory exists

# Function to increment file name based on the filename which is based on the current date and time
def get_incremented_filename(base_path, extension):
    timestamp, basename = os.path.splitext(base_path)[0].rsplit('_', 1)
    file_number = 1
    while os.path.exists(f'{timestamp}_{basename}{file_number}.{extension}'):
        file_number += 1
    return f'{timestamp}_{basename}{file_number}.{extension}'

# Process each selected video file
for video_path in video_paths:
    # Extract base timestamp from filename
    base_timestamp = extract_timestamp_from_filename(video_path)
    print(f"Using base timestamp from filename: {base_timestamp}")
    
    # OpenCV Video Capture
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)  # Get the original FPS from the video

    # Get file paths with incremented numbers
    time_record = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
    base_filename = os.path.join(output_dir, f'{time_record}_hand-tracking-output')
    video_file = get_incremented_filename(base_filename, 'avi')
    csv_file = get_incremented_filename(base_filename.replace('output', 'landmarks'), 'csv')

    # Define the codec and create a VideoWriter object to save the video
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    out = cv2.VideoWriter(video_file, fourcc, fps, (frame_width, frame_height))

    # Store frames and landmarks
    all_frames = []
    all_landmarks = []
    
    print(f"Processing video: {video_path}")
    
    # First pass: collect frames and landmarks
    while cap.isOpened():
        success, image = cap.read()
        if not success:
            break

        # Store original frame
        all_frames.append(image.copy())
        
        # Convert the BGR image to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # Process the image and find hands
        result = hands.process(image_rgb)

        # Store landmarks if hands are found
        frame_landmarks = []
        if result.multi_hand_landmarks:
            for hand_landmarks in result.multi_hand_landmarks:
                for idx, landmark in enumerate(hand_landmarks.landmark):
                    frame_landmarks.append((idx, landmark.x, landmark.y, landmark.z))
        
        all_landmarks.append(frame_landmarks)
    
    # Smooth the landmarks
    print("Processing completed. Applying smoothing filter...")
    smoothed_landmarks = smooth_landmarks(all_landmarks, fps=fps)
    print("Smoothing completed.")
    
    # Prepare CSV file for output
    with open(csv_file, 'w', newline='') as csv_file_handle:
        csv_writer = csv.writer(csv_file_handle)
        csv_writer.writerow(['frame', 'timestamp', 'landmark_index', 'x', 'y', 'z'])  # CSV header
        
        # Second pass: render video with smoothed landmarks and save to CSV
        for frame_idx, (frame, landmarks) in enumerate(zip(all_frames, smoothed_landmarks)):
            # Calculate timestamp based on frame index and fps
            frame_time_seconds = frame_idx / fps
            frame_timestamp = base_timestamp + timedelta(seconds=frame_time_seconds)
            timestamp = frame_timestamp.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]  # Trim to milliseconds
            
            # Display frame with landmarks
            if landmarks:
                # We need to convert our smoothed landmarks back to MediaPipe format
                hand_landmarks = mp_hands.Hands().process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)).multi_hand_landmarks
                
                if hand_landmarks:
                    # Update the landmarks with our smoothed values
                    for idx, (_, x, y, z) in enumerate(landmarks):
                        if idx < len(hand_landmarks[0].landmark):
                            hand_landmarks[0].landmark[idx].x = x
                            hand_landmarks[0].landmark[idx].y = y
                            hand_landmarks[0].landmark[idx].z = z
                    
                    # Draw the smoothed landmarks
                    mp_drawing.draw_landmarks(frame, hand_landmarks[0], mp_hands.HAND_CONNECTIONS)
                
                # Write landmarks to CSV
                for landmark_idx, x, y, z in landmarks:
                    csv_writer.writerow([frame_idx, timestamp, landmark_idx, x, y, z])
            
            # Write the frame to video
            out.write(frame)
            
            # Display progress
            if frame_idx % 30 == 0:
                print(f"Processed frame {frame_idx}/{len(all_frames)}")
    
    # Release resources
    cap.release()
    out.release()
    print(f"Saved processed video to {video_file} and landmarks to {csv_file}")

cv2.destroyAllWindows()
print("All videos processed.")