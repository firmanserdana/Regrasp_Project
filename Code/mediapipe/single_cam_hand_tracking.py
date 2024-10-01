import cv2
import mediapipe as mp
import csv
from datetime import datetime
import sys
import os

if len(sys.argv) != 2:
    print("Usage: python3 hand_tracking.py <camera_id>")
    sys.exit(1)

camera_id = int(sys.argv[1])

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=1,
                       min_detection_confidence=0.5,
                       min_tracking_confidence=0.5)

# Initialize MediaPipe Drawing
mp_drawing = mp.solutions.drawing_utils

# OpenCV Video Capture
cap = cv2.VideoCapture(camera_id)

# Prepare directories and file names
output_dir = 'Data\mediapipe'
os.makedirs(output_dir, exist_ok=True)  # Ensure the directory exists

# Function to increment file name
def get_incremented_filename(base_path, extension):
    file_number = 1
    while os.path.exists(f'{base_path}_{file_number}.{extension}'):
        file_number += 1
    return f'{base_path}_{file_number}.{extension}'

# Function to compute the recording number for the filename
def compute_rec_number(save_path, date_str):
    # List all files in the directory
    file_list = os.listdir(save_path)
    
    # Filter files that contain today's date
    files_today = [f for f in file_list if date_str in f]
    
    # Extract recording numbers from filenames
    rec_numbers = []
    for file_name in files_today:
        match = re.search(r'rec(\d+)', file_name)
        if match:
            rec_numbers.append(int(match.group(1)))

    # Determine the highest recording number
    if rec_numbers:
        max_rec_number = max(rec_numbers)
    else:
        max_rec_number = 0
    
    # Return the next available recording number
    return max_rec_number + 1

# Get file paths with incremented numbers
time_record = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
base_filename = os.path.join(output_dir, f'hand_tracking_output_cam-{camera_id}_{time_record}')
video_file = get_incremented_filename(base_filename, 'avi')
csv_file = get_incremented_filename(base_filename.replace('output', 'landmarks'), 'csv')

# Define the codec and create a VideoWriter object to save the video
fourcc = cv2.VideoWriter_fourcc(*'XVID')  # You can change codec (e.g., 'XVID', 'MJPG', 'MP4V')
fps = 30.0  # Frames per second
frame_width = int(cap.get(3))  # Frame width from the camera
frame_height = int(cap.get(4))  # Frame height from the camera
out = cv2.VideoWriter(video_file, fourcc, fps, (frame_width, frame_height))

# Prepare CSV file for output
csv_file_handle = open(csv_file, 'w', newline='')
csv_writer = csv.writer(csv_file_handle)
csv_writer.writerow(['timestamp', 'landmark_index', 'x', 'y', 'z'])  # CSV header

# Create a named window and set it to normal to ensure it pops up in the front
window_name = 'Hand Tracking'
cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
cv2.setWindowProperty(window_name, cv2.WND_PROP_TOPMOST, 1)

while cap.isOpened():
    success, image = cap.read()
    if not success:
        print("Ignoring empty camera frame.")
        continue

    # Flip the image horizontally for a later selfie-view display
    image = cv2.flip(image, 1)

    # Convert the BGR image to RGB
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Process the image and find hands
    result = hands.process(image_rgb)

    # Draw hand landmarks and save to CSV if hands are found
    if result.multi_hand_landmarks:
        for hand_landmarks in result.multi_hand_landmarks:
            mp_drawing.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)

            # Write each landmark (x, y, z) to CSV
            for idx, landmark in enumerate(hand_landmarks.landmark):
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
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
