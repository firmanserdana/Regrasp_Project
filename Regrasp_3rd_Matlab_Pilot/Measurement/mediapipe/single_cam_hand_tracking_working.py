import cv2
import mediapipe as mp
import csv
from datetime import datetime

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=1,
                       min_detection_confidence=0.5,
                       min_tracking_confidence=0.5)

# Initialize MediaPipe Drawing
mp_drawing = mp.solutions.drawing_utils

# Get list of available cameras
def list_available_cameras(max_cameras=10):
    available_cameras = []
    for camera_id in range(max_cameras):
        cap = cv2.VideoCapture(camera_id)
        if cap.isOpened():
            available_cameras.append(camera_id)
            cap.release()
    return available_cameras

if __name__ == "__main__":
    cameras = list_available_cameras()
    if cameras:
        print("Available cameras:", cameras)
    else:
        print("No cameras found.")

# Select the camera to use by user input
camera_id = int(input("Enter the camera ID to use: "))

# Add Subject identifier
subject_id = input("Enter the subject ID: ")

# OpenCV Video Capture
cap = cv2.VideoCapture(camera_id)

# Define the codec and create a VideoWriter object to save the video
fourcc = cv2.VideoWriter_fourcc(*'XVID')  # You can change codec (e.g., 'XVID', 'MJPG', 'MP4V')
fps = 30.0  # Frames per second
frame_width = int(cap.get(3))  # Frame width from the camera
frame_height = int(cap.get(4))  # Frame height from the camera
out = cv2.VideoWriter(f'Regrasp_3rd_Matlab_Pilot/Measurement/mediapipe/hand_tracking_output_{subject_id}.avi', fourcc, fps, (frame_width, frame_height))

# Prepare CSV file for output
csv_file = open('Regrasp_3rd_Matlab_Pilot/Measurement/mediapipe/hand_landmarks_'+subject_id+'.csv', 'w', newline='')
csv_writer = csv.writer(csv_file)
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
    cv2.imshow('Hand Tracking', image)

    if cv2.waitKey(5) & 0xFF == 27:  # Press 'Esc' to exit
        break

# Release everything when done
cap.release()
out.release()
csv_file.close()
cv2.destroyAllWindows()
