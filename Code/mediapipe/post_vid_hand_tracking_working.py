import cv2
import mediapipe as mp
import csv
from datetime import datetime
import os
import tkinter as tk
from tkinter import filedialog

# Initialize the file dialog
root = tk.Tk()
root.withdraw()  # Hide the root window

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
    # OpenCV Video Capture
    cap = cv2.VideoCapture(video_path)

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

    # Prepare CSV file for output
    csv_file_handle = open(csv_file, 'w', newline='')
    csv_writer = csv.writer(csv_file_handle)
    csv_writer.writerow(['timestamp', 'landmark_index', 'x', 'y', 'z'])  # CSV header

    # Create a named window for displaying the video
    window_name = 'Hand Tracking'
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)

    while cap.isOpened():
        success, image = cap.read()
        if not success:
            print(f"Video processing completed for {video_path}.")
            break

        # Flip the image horizontally for a selfie-view display (optional)
        # image = cv2.flip(image, 1)

        # Convert the BGR image to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # Process the image and find hands
        result = hands.process(image_rgb)

        # Draw hand landmarks and save to CSV if hands are found
        if result.multi_hand_landmarks:
            for hand_landmarks in result.multi_hand_landmarks:
                mp_drawing.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
                # Write each landmark (x, y, z) to CSV
                for idx, landmark in enumerate(hand_landmarks.landmark):
                    csv_writer.writerow([timestamp, idx, landmark.x, landmark.y, landmark.z])

        # Write the current frame to the video file
        out.write(image)

        # Display the resulting frame
        cv2.imshow(window_name, image)

        if cv2.waitKey(5) & 0xFF == 27:  # Press 'Esc' to exit
            break

    # Release everything when done
    cap.release()
    out.release()
    csv_file_handle.close()
    cv2.destroyAllWindows()

print("All videos processed.")