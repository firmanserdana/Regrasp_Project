import cv2
import mediapipe as mp
import csv
import time
import numpy as np
import datetime as datetime

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=1,
                       min_detection_confidence=0.5,
                       min_tracking_confidence=0.5)

# Initialize MediaPipe Drawing
mp_drawing = mp.solutions.drawing_utils

# Initialize number of cameras
num_cameras = 2

# OpenCV Video Capture for multiple cameras (use as many as connected)
cameras = [cv2.VideoCapture(i) for i in range(num_cameras)]  # Change 2 to the number of cameras you have

print("Available cameras:", [cam.isOpened() for cam in cameras])

# Add Subject identifier
subject_id = input("Enter the subject ID: ")

# Prepare CSV file for output
csv_file = open('Regrasp_3rd_Matlab_Pilot/Measurement/mediapipe/hand_landmarks_fusion_'+subject_id+'.csv', 'w', newline='')
csv_writer = csv.writer(csv_file)
csv_writer.writerow(['timestamp', 'landmark_index', 'x', 'y', 'z', 'camera_count'])  # CSV header

# Create a named window and set it to normal to ensure it pops up in the front
window_name = 'Hand Tracking'
cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
cv2.setWindowProperty(window_name, cv2.WND_PROP_TOPMOST, 1)

start_time = time.time()

while all([cam.isOpened() for cam in cameras]):
    frames = []
    results = []
    
    for cam in cameras:
        success, frame = cam.read()
        if success:
            frame = cv2.flip(frame, 1)
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frames.append(frame)
            # Process with MediaPipe
            result = hands.process(frame_rgb)
            results.append(result)

    # Initialize accumulators for averaging landmarks
    landmark_sum = {}
    camera_contributions = {}  # Track how many cameras contribute to each landmark
    
    for cam_index, result in enumerate(results):
        if result.multi_hand_landmarks:
            for hand_landmarks in result.multi_hand_landmarks:
                for idx, landmark in enumerate(hand_landmarks.landmark):
                    # If this is the first time seeing this landmark, initialize it
                    if idx not in landmark_sum:
                        landmark_sum[idx] = np.array([0.0, 0.0, 0.0])
                        camera_contributions[idx] = 0
                    
                    # Add the landmark (x, y, z) position to the sum
                    landmark_sum[idx] += np.array([landmark.x, landmark.y, landmark.z])
                    camera_contributions[idx] += 1

    # Calculate the average position of each landmark from multiple camera views
    fused_landmarks = {}
    for idx in landmark_sum:
        if camera_contributions[idx] > 0:
            # Average landmark position
            fused_landmarks[idx] = landmark_sum[idx] / camera_contributions[idx]

            # DL - openpose - github - freemocap - mediapipe - handtracking - hand_landmarks_fusion.py

            # Write to CSV
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            csv_writer.writerow([timestamp, idx, *fused_landmarks[idx], camera_contributions[idx]])

    # Display frames for each camera with hand landmarks drawn
    for cam_index, frame in enumerate(frames):
        if results[cam_index].multi_hand_landmarks:
            for hand_landmarks in results[cam_index].multi_hand_landmarks:
                mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)
        cv2.imshow(f'Camera {cam_index}', frame)

    if cv2.waitKey(5) & 0xFF == 27:  # Press 'Esc' to exit
        break

# Release everything when done
for cam in cameras:
    cam.release()
csv_file.close()
cv2.destroyAllWindows()
