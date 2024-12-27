import pyrealsense2 as rs
import numpy as np
import cv2
import os
import sys
import csv
from datetime import datetime
import time
import mediapipe as mp

# Check for the correct number of arguments
if len(sys.argv) != 3:
    print("Usage: python single_cam_hand_tracking.py <camera_id> <recording_notes>")
    sys.exit(1)

camera_id = int(sys.argv[1])
recording_notes = str(sys.argv[2])

# Function to increment file name based on the filename which based on the current date and time
def get_incremented_filename(base_path, extension):
    timestamp, basename = os.path.splitext(base_path)[0].rsplit('_', 1)
    file_number = 1
    while os.path.exists(f'{timestamp}_{basename}{file_number}.{extension}'):
        file_number += 1
    return f'{timestamp}_{basename}{file_number}.{extension}'

# Initialize RealSense pipeline
pipeline = rs.pipeline()
config = rs.config()
config.enable_stream(rs.stream.depth, 640, 480, rs.format.z16, 30)
config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)
pipeline.start(config)

# Initialize MediaPipe
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands()

# Get file paths with incremented numbers
time_record = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
output_dir = 'output'
os.makedirs(output_dir, exist_ok=True)
base_filename = os.path.join(output_dir, f'{time_record}_hand-tracking-output-cam-{camera_id}-rec')
video_file = get_incremented_filename(base_filename, 'avi')
csv_file = get_incremented_filename(base_filename.replace('output', 'landmarks'), 'csv')

# Define the codec and create a VideoWriter object to save the video
fourcc = cv2.VideoWriter_fourcc(*'MJPG')  # You can change codec (e.g., 'XVID', 'MJPG', 'MP4V')
fps = 30.0  # Frames per second
frame_width = 1920
frame_height = 1080
out = cv2.VideoWriter(video_file, fourcc, fps, (frame_width, frame_height))

# Prepare CSV file for output
csv_file_handle = open(csv_file, 'w', newline='')
csv_writer = csv.writer(csv_file_handle)
csv_writer.writerow(['timestamp', 'landmark_index', 'x', 'y', 'z', 'depth'])  # CSV header

# Create a named window and set it to normal to ensure it pops up in the front
window_name = 'Hand Tracking'
cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
cv2.setWindowProperty(window_name, cv2.WND_PROP_TOPMOST, 1)

# Calculate the time interval between frames
frame_interval = 1.0 / fps

try:
    while True:
        start_time = time.time()

        # Wait for a coherent pair of frames: depth and color
        frames = pipeline.wait_for_frames()
        depth_frame = frames.get_depth_frame()
        color_frame = frames.get_color_frame()

        if not depth_frame or not color_frame:
            continue

        # Convert images to numpy arrays
        depth_image = np.asanyarray(depth_frame.get_data())
        color_image = np.asanyarray(color_frame.get_data())

        # Add recording notes to the frame
        cv2.putText(color_image, time_record, (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (240, 255, 255), 1)
        cv2.putText(color_image, recording_notes, (50, 70), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (240, 255, 255), 1)

        # Convert the BGR image to RGB
        image_rgb = cv2.cvtColor(color_image, cv2.COLOR_BGR2RGB)

        # Process the image and find hands
        result = hands.process(image_rgb)

        # Write the current frame to the video file
        out.write(color_image)

        # Save landmarks to CSV if hands are found
        if result.multi_hand_landmarks:
            for hand_landmarks in result.multi_hand_landmarks:
                # Draw the hand landmarks on the image
                mp_drawing.draw_landmarks(color_image, hand_landmarks, mp_hands.HAND_CONNECTIONS)

                # Save landmarks to CSV
                for idx, landmark in enumerate(hand_landmarks.landmark):
                    x = int(landmark.x * frame_width)
                    y = int(landmark.y * frame_height)
                    z = landmark.z
                    depth = depth_image[y, x] if 0 <= x < frame_width and 0 <= y < frame_height else 0
                    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
                    csv_writer.writerow([timestamp, idx, x, y, z, depth])

        # Display the color image
        cv2.imshow(window_name, color_image)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

        # Ensure the loop runs at the specified frame rate
        elapsed_time = time.time() - start_time
        time.sleep(max(0, frame_interval - elapsed_time))
finally:
    # Stop streaming
    pipeline.stop()
    out.release()
    csv_file_handle.close()
    cv2.destroyAllWindows()