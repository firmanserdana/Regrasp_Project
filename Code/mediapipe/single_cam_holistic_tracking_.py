import cv2
import mediapipe as mp
import csv

# Initialize MediaPipe Holistic
mp_holistic = mp.solutions.holistic
holistic = mp_holistic.Holistic()
mp_drawing = mp.solutions.drawing_utils

# Open the webcam
cap = cv2.VideoCapture(0)

# Open a CSV file to write the landmarks
with open('landmarks.csv', mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['frame', 'landmark_type', 'x', 'y', 'z', 'visibility'])

    def save_landmarks(frame_num, landmarks, landmark_type):
        if landmarks:
            for idx, landmark in enumerate(landmarks.landmark):
                writer.writerow([frame_num, landmark_type, landmark.x, landmark.y, landmark.z, landmark.visibility])

    frame_num = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Convert the BGR image to RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Process the image and detect the holistic features
        results = holistic.process(image)

        # Save the landmarks to CSV
        save_landmarks(frame_num, results.face_landmarks, 'face')
        save_landmarks(frame_num, results.pose_landmarks, 'pose')
        save_landmarks(frame_num, results.left_hand_landmarks, 'left_hand')
        save_landmarks(frame_num, results.right_hand_landmarks, 'right_hand')

        # Draw the face landmarks
        mp_drawing.draw_landmarks(frame, results.face_landmarks, mp_holistic.FACEMESH_TESSELATION)

        # Draw the pose landmarks
        mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS)

        # Draw the hand landmarks
        mp_drawing.draw_landmarks(frame, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS)
        mp_drawing.draw_landmarks(frame, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS)

        # Display the output
        cv2.imshow('MediaPipe Holistic', frame)

        if cv2.waitKey(10) & 0xFF == ord('q'):
            break

        frame_num += 1

# Release the webcam and close the window
cap.release()
cv2.destroyAllWindows()