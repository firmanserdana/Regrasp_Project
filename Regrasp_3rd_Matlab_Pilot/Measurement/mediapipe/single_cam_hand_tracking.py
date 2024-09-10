import cv2
import mediapipe as mp
import csv
import time

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=1,
                       min_detection_confidence=0.5,
                       min_tracking_confidence=0.5)

# Initialize MediaPipe Drawing
mp_drawing = mp.solutions.drawing_utils

# OpenCV Video Capture
cap = cv2.VideoCapture(0)

# Prepare CSV file for output
csv_file = open('Regrasp_3rd_Matlab_Pilot\Measurement\mediapipe\hand_landmarks.csv', 'w', newline='')
csv_writer = csv.writer(csv_file)
csv_writer.writerow(['timestamp', 'landmark_index', 'x', 'y', 'z'])  # CSV header

start_time = time.time()

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
                timestamp = time.time() - start_time
                csv_writer.writerow([timestamp, idx, landmark.x, landmark.y, landmark.z])

    # Display the resulting frame
    cv2.imshow('Hand Tracking', image)

    if cv2.waitKey(5) & 0xFF == 27:  # Press 'Esc' to exit
        break

# Release everything when done
cap.release()
csv_file.close()
cv2.destroyAllWindows()
