import cv2
import mediapipe as mp
import csv
from datetime import datetime, timedelta
import os
import tkinter as tk
from tkinter import filedialog
from scipy.signal import butter, filtfilt
import pandas as pd
import numpy as np
import re
import time

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
print(f"Selected {len(video_paths)} videos for processing")

for i, video_path in enumerate(video_paths):
    try:
        print(f"\nProcessing video {i+1}/{len(video_paths)}: {os.path.basename(video_path)}")
        
        # Initialize MediaPipe Hands (create a fresh instance for each video)
        mp_hands = mp.solutions.hands
        hands = mp_hands.Hands(static_image_mode=False,
                            max_num_hands=1,
                            min_detection_confidence=0.8,
                            min_tracking_confidence=0.8)
        
        # Initialize MediaPipe Drawing
        mp_drawing = mp.solutions.drawing_utils
        
        # Extract base timestamp from filename
        base_timestamp = extract_timestamp_from_filename(video_path)
        print(f"Using base timestamp from filename: {base_timestamp}")
        
        # OpenCV Video Capture
        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS)  # Get the original FPS from the video

        # Get file paths with incremented numbers
        original_filename = os.path.splitext(os.path.basename(video_path))[0]
        base_filename = os.path.join(output_dir, f'{original_filename}-tracked')
        video_file = f"{base_filename}.avi"
        csv_file = f"{base_filename}-landmarks.csv"
        
        # Handle file existence
        if os.path.exists(video_file) or os.path.exists(csv_file):
            time_suffix = datetime.now().strftime("%Y%m%d%H%M%S")
            video_file = f"{base_filename}-{time_suffix}.avi"
            csv_file = f"{base_filename}-landmarks-{time_suffix}.csv"

        # Define the codec and create a VideoWriter object to save the video
        fourcc = cv2.VideoWriter_fourcc(*'XVID')
        frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        out = cv2.VideoWriter(video_file, fourcc, fps, (frame_width, frame_height))

        # Get total frames for progress reporting
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        print(f"Total frames: {total_frames}")
        
        # First pass: collect landmarks only (not frames to save memory)
        all_landmarks = []
        frame_idx = 0
        
        while cap.isOpened():
            success, image = cap.read()
            if not success:
                break
            
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
            
            # Display progress
            frame_idx += 1
            if frame_idx % 30 == 0:
                print(f"Collecting landmarks: {frame_idx}/{total_frames} frames ({int(frame_idx/total_frames*100)}%)")
        
        # Smooth the landmarks
        print("\nApplying smoothing filter...")
        smoothed_landmarks = smooth_landmarks(all_landmarks, fps=fps)
        print("Smoothing completed.")
        
        # Prepare CSV file for output
        with open(csv_file, 'w', newline='') as csv_file_handle:
            csv_writer = csv.writer(csv_file_handle)
            csv_writer.writerow(['frame', 'timestamp', 'landmark_index', 'x', 'y', 'z'])  # CSV header
            
            # Reset video to beginning for second pass
            cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
            frame_idx = 0
            
            # Second pass: render video with smoothed landmarks and save to CSV
            while cap.isOpened():
                success, frame = cap.read()
                if not success:
                    break
                
                # Get landmarks for current frame
                landmarks = smoothed_landmarks[frame_idx] if frame_idx < len(smoothed_landmarks) else []
                
                # Calculate timestamp based on frame index and fps
                frame_time_seconds = frame_idx / fps
                frame_timestamp = base_timestamp + timedelta(seconds=frame_time_seconds)
                timestamp = frame_timestamp.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]  # Trim to milliseconds
                
                # Display frame with landmarks
                if landmarks:
                    # Create a temporary landmark structure for drawing
                    mp_landmark = mp_hands.HandLandmark  # Just reference the enum
                    
                    # Create a temporary landmark collection for drawing
                    from mediapipe.framework.formats import landmark_pb2
                    temp_landmarks = landmark_pb2.NormalizedLandmarkList()
                    for landmark_idx, x, y, z in landmarks:
                        landmark = temp_landmarks.landmark.add()
                        landmark.x = x
                        landmark.y = y
                        landmark.z = z
                        
                        # Convert normalized coordinates to pixel coordinates for CSV
                        px = int(x * frame.shape[1])
                        py = int(y * frame.shape[0])
                        
                        # Write to CSV
                        csv_writer.writerow([frame_idx, timestamp, landmark_idx, x, y, z])
                    
                    # Draw the landmarks and connections
                    mp_drawing.draw_landmarks(
                        frame,
                        temp_landmarks,
                        mp_hands.HAND_CONNECTIONS,
                        mp_drawing.DrawingSpec(color=(0, 255, 0), thickness=2, circle_radius=4),
                        mp_drawing.DrawingSpec(color=(255, 0, 0), thickness=2)
                    )
                
                # Write the frame to video
                out.write(frame)
                
                # Display progress
                frame_idx += 1
                if frame_idx % 30 == 0:
                    print(f"Rendering video: {frame_idx}/{total_frames} frames ({int(frame_idx/total_frames*100)}%)")
        
        # Release resources
        cap.release()
        out.release()
        hands.close()  # Clean up MediaPipe resources
        
        print(f"✅ Completed: {os.path.basename(video_path)}")
        print(f"Output files: \n- {os.path.basename(video_file)}\n- {os.path.basename(csv_file)}")
    
    except Exception as e:
        print(f"❌ Error processing video {os.path.basename(video_path)}: {str(e)}")
        # Continue with next video instead of crashing

cv2.destroyAllWindows()
print("\nAll videos processed.")