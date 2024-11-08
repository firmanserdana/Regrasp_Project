import cv2
import mediapipe as mp
import numpy as np
import csv
from datetime import datetime
import os
import tkinter as tk
from tkinter import filedialog

# Initialize the file dialog
root = tk.Tk()
root.withdraw()  # Hide the root window

# Open file dialog to select video file
video_path = filedialog.askopenfilename(
    title="Select a video file",
    filetypes=[("Video Files", "*.mp4;*.avi;*.mov;*.mkv"), ("All Files", "*.*")]
)

# Check if a file was selected
if not video_path:
    print("No video file selected. Exiting.")
    exit()

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=1, min_detection_confidence=0.5, min_tracking_confidence=0.5)

# Initialize MediaPipe Drawing
mp_drawing = mp.solutions.drawing_utils

# OpenCV Video Capture
cap = cv2.VideoCapture(video_path)

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

# Get file paths with incremented numbers
time_record = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
base_filename = os.path.join(output_dir, f'{time_record}_hand-tracking-output')
video_file = get_incremented_filename(base_filename, 'avi')
csv_file = get_incremented_filename(base_filename.replace('output', 'landmarks'), 'csv')

# Define the codec and create a VideoWriter object to save the video
fourcc = cv2.VideoWriter_fourcc(*'XVID')  # You can change codec (e.g., 'XVID', 'MJPG', 'MP4V')
fps = cap.get(cv2.CAP_PROP_FPS)  # Get the original FPS from the video
frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))  # Frame width from the video
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))  # Frame height from the video
out = cv2.VideoWriter(video_file, fourcc, fps, (frame_width, frame_height))

# Prepare CSV file for output (for Mediapipe landmarks)
csv_file_handle = open(csv_file, 'w', newline='')
csv_writer = csv.writer(csv_file_handle)
csv_writer.writerow(['timestamp', 'landmark_index', 'x', 'y', 'z'])  # CSV header

# Create a named window for displaying the video
window_name = 'Hand Tracking'
cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)

# Read first frame to select ROIs (rubber band and finger)
success, frame = cap.read()
if not success:
    print("Failed to read video.")
    exit()

# Select ROI for rubber band using cv2.selectROI()
rubber_band_roi = cv2.selectROI("Select Rubber Band", frame, showCrosshair=True, fromCenter=False)
x_rubber, y_rubber, w_rubber, h_rubber = rubber_band_roi

# Extract average color from rubber band ROI in HSV format
rubber_band_region_bgr = frame[y_rubber:y_rubber+h_rubber, x_rubber:x_rubber+w_rubber]
rubber_band_region_hsv = cv2.cvtColor(rubber_band_region_bgr, cv2.COLOR_BGR2HSV)
avg_rubber_band_hsv = np.mean(rubber_band_region_hsv.reshape(-1, 3), axis=0)  # Get average HSV color

print(f"Average Rubber Band Color (HSV): {avg_rubber_band_hsv}")

# Define lower and upper bounds for rubber band detection in HSV based on average color (adjustable range)
lower_rubber_band_hsv = np.array([max(0, avg_rubber_band_hsv[0] - 10), max(50, avg_rubber_band_hsv[1] - 40), max(50, avg_rubber_band_hsv[2] - 40)])
upper_rubber_band_hsv = np.array([min(180, avg_rubber_band_hsv[0] + 10), min(255, avg_rubber_band_hsv[1] + 40), min(255, avg_rubber_band_hsv[2] + 40)])

# Select ROI for finger (to sample its color)
finger_roi = cv2.selectROI("Select Finger", frame, showCrosshair=True, fromCenter=False)
x_finger, y_finger, w_finger, h_finger = finger_roi

# Extract average color from finger ROI (BGR format)
finger_region_bgr = frame[y_finger:y_finger+h_finger, x_finger:x_finger+w_finger]
avg_finger_color_bgr = np.mean(finger_region_bgr.reshape(-1, 3), axis=0)  # Get average BGR color

print(f"Average Finger Color (BGR): {avg_finger_color_bgr}")

while cap.isOpened():
    success, image = cap.read()
    if not success:
        print("Video processing completed.")
        break

    # Convert image to HSV for better color detection of rubber band
    hsv_image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    # Create a mask for detecting rubber band based on its HSV range
    mask_rubber_band = cv2.inRange(hsv_image, lower_rubber_band_hsv, upper_rubber_band_hsv)

    # Replace detected rubber band pixels with average finger color in BGR space
    image[mask_rubber_band > 0] = avg_finger_color_bgr

    # Convert back to RGB for Mediapipe processing
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Process hand landmarks using Mediapipe Hands model on modified image
    result = hands.process(image_rgb)

    # Draw hand landmarks and save them if hands are detected in each frame.
    if result.multi_hand_landmarks:
        for hand_landmarks in result.multi_hand_landmarks:
            mp_drawing.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            for idx, landmark in enumerate(hand_landmarks.landmark):
                csv_writer.writerow([timestamp, idx, landmark.x, landmark.y, landmark.z])

    # Write modified frame to output video file.
    out.write(image)

    # Display modified frame with replaced rubber band color.
    cv2.imshow(window_name, image)

    if cv2.waitKey(5) & 0xFF == 27:  # Press 'Esc' to exit loop.
        break

# Release everything when done.
cap.release()
out.release()
csv_file_handle.close()
cv2.destroyAllWindows()