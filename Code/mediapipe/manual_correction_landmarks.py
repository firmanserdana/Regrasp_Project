from PyQt5.QtCore import QThread, pyqtSignal, QTimer, QEventLoop
from PyQt5.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QLabel, QPushButton, QFileDialog, QWidget, QHBoxLayout, QSlider, QTableWidget, QTableWidgetItem, QMessageBox
from PyQt5.QtGui import QImage, QPixmap
from PyQt5.Qt import Qt
import mediapipe as mp
import cv2
import pandas as pd
import sys
import queue


class HandTrackingWorker(QThread):
    frame_processed = pyqtSignal(object, object, int)  # Emit frame, landmarks, and frame index
    progress = pyqtSignal(int)  # Emit progress percentage
    error = pyqtSignal(str)  # Emit errors to the main thread
    finished_tracking = pyqtSignal()  # Emit when tracking is complete

    def __init__(self, video_path, hands, result_queue):
        super().__init__()
        self.video_path = video_path
        self.hands = hands
        self.running = True
        self.result_queue = result_queue

    def run(self):
        try:
            cap = cv2.VideoCapture(self.video_path)
            if not cap.isOpened():
                raise ValueError("Error opening video file")

            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            frame_idx = 0

            while self.running and cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break

                # Process frame
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                results = self.hands.process(frame_rgb)

                # Collect results
                if results.multi_hand_landmarks:
                    frame_landmarks = []
                    for hand_landmarks in results.multi_hand_landmarks:
                        for i, landmark in enumerate(hand_landmarks.landmark):
                            frame_landmarks.append(
                                {"Frame": frame_idx, "Landmark": i, "X": landmark.x, "Y": landmark.y, "Z": landmark.z}
                            )
                    self.result_queue.put(frame_landmarks)

                # Emit progress
                progress = int((frame_idx / total_frames) * 100)
                self.progress.emit(progress)
                frame_idx += 1

            cap.release()
            self.progress.emit(100)  # Ensure progress is set to 100%
            self.finished_tracking.emit()  # Emit signal when tracking is complete
        except Exception as e:
            self.error.emit(str(e))

    def stop(self):
        self.running = False
        self.quit()
        self.wait()


class HandTrackingApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Hand Tracking Editor")
        self.setGeometry(100, 100, 1200, 800)

        # Mediapipe setup
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(static_image_mode=False, max_num_hands=2)
        self.mp_drawing = mp.solutions.drawing_utils

        # Video and worker thread
        self.video_path = None
        self.worker = None
        self.result_queue = queue.Queue()
        self.landmarks_df = pd.DataFrame()
        self.current_frame_index = 0
        self.playing = False

        # UI setup
        self.init_ui()

        # Timer to fetch results from the queue
        self.timer = QTimer()
        self.timer.timeout.connect(self.process_queue)
        self.timer.start(100)  # Check every 100ms

    def init_ui(self):
        layout = QVBoxLayout()

        # Video display
        self.video_label = QLabel("Video will be displayed here")
        self.video_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.video_label)

        # Buttons
        button_layout = QHBoxLayout()
        self.load_video_button = QPushButton("Load Video")
        self.track_hands_button = QPushButton("Track Hands")
        self.save_button = QPushButton("Save Landmarks")
        self.play_button = QPushButton("Play")
        self.pause_button = QPushButton("Pause")
        button_layout.addWidget(self.load_video_button)
        button_layout.addWidget(self.track_hands_button)
        button_layout.addWidget(self.save_button)
        button_layout.addWidget(self.play_button)
        button_layout.addWidget(self.pause_button)
        layout.addLayout(button_layout)

        # Slider for navigating frames
        self.frame_slider = QSlider(Qt.Horizontal)
        self.frame_slider.setEnabled(False)
        layout.addWidget(self.frame_slider)

        # Frame number display
        self.frame_number_label = QLabel("Frame: 0")
        layout.addWidget(self.frame_number_label)

        # Landmark Table
        self.landmark_table = QTableWidget()
        layout.addWidget(self.landmark_table)

        # Set up connections
        self.load_video_button.clicked.connect(self.load_video)
        self.track_hands_button.clicked.connect(self.start_hand_tracking)
        self.save_button.clicked.connect(self.save_landmarks)
        self.frame_slider.valueChanged.connect(self.on_frame_change)
        self.play_button.clicked.connect(self.play_video)
        self.pause_button.clicked.connect(self.pause_video)
        self.landmark_table.itemChanged.connect(self.on_table_item_changed)

        # Set layout
        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

    def load_video(self):
        self.video_path, _ = QFileDialog.getOpenFileName(self, "Select Video File", "", "Video Files (*.mp4 *.avi *.mov)")
        if self.video_path:
            self.cap = cv2.VideoCapture(self.video_path)
            if not self.cap.isOpened():
                QMessageBox.critical(self, "Error", "Failed to open video file.")
                return
            self.frame_slider.setEnabled(True)
            self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
            self.frame_slider.setMaximum(self.total_frames - 1)
            self.load_frame(0)

    def load_frame(self, index):
        if self.cap:
            self.cap.set(cv2.CAP_PROP_POS_FRAMES, index)
            success, frame = self.cap.read()
            if success:
                self.current_frame_index = index
                landmarks = self.get_landmarks_for_frame(index)
                self.display_frame(frame, landmarks)

    def display_frame(self, frame, landmarks=None):
        # Convert frame to RGB
        rgb_image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Define the hand connections based on landmark indices
        hand_connections = [
            (0, 1), (1, 2), (2, 3), (3, 4),  # Thumb
            (0, 5), (5, 6), (6, 7), (7, 8),  # Index finger
            (0, 9), (9, 10), (10, 11), (11, 12),  # Middle finger
            (0, 13), (13, 14), (14, 15), (15, 16),  # Ring finger
            (0, 17), (17, 18), (18, 19), (19, 20)  # Pinky
        ]

        # Draw landmarks if available
        if landmarks is not None and not landmarks.empty:
            # Create a dictionary of landmark points
            landmark_points = {}
            for _, row in landmarks.iterrows():
                x = int(row["X"] * frame.shape[1])
                y = int(row["Y"] * frame.shape[0])
                landmark_points[row["Landmark"]] = (x, y)
                cv2.circle(rgb_image, (x, y), 5, (0, 255, 0), -1)

            # Draw the hand connections
            for start_idx, end_idx in hand_connections:
                if start_idx in landmark_points and end_idx in landmark_points:
                    cv2.line(rgb_image, landmark_points[start_idx], landmark_points[end_idx], (0, 255, 0), 2)

        # Convert to QImage for display
        h, w, ch = rgb_image.shape
        bytes_per_line = ch * w
        qt_image = QImage(rgb_image.data, w, h, bytes_per_line, QImage.Format_RGB888)

        # Update QLabel
        self.video_label.setPixmap(QPixmap.fromImage(qt_image))

    def start_hand_tracking(self):
        if not self.video_path:
            QMessageBox.warning(self, "Warning", "Please load a video first!")
            return

        # Stop existing worker if running
        if self.worker:
            self.worker.stop()

        # Clear existing data
        self.landmarks_df = pd.DataFrame()

        # Start worker
        self.worker = HandTrackingWorker(self.video_path, self.hands, self.result_queue)
        self.worker.frame_processed.connect(self.on_frame_processed)
        self.worker.progress.connect(self.update_progress)
        self.worker.error.connect(self.handle_worker_error)
        self.worker.finished_tracking.connect(self.on_tracking_finished)  # Connect the finished signal
        self.worker.start()

    def on_frame_processed(self, frame, landmarks, frame_idx):
        # Handle the frame and landmarks (process the result and update the UI)
        # Display the landmarks on the frame (for example, drawing circles on landmarks)
        self.display_frame(frame, landmarks)

        # Optionally, update the slider or other parts of the UI if necessary
        self.frame_slider.setValue(frame_idx)

        # If you want to do any additional processing with the landmarks, you can store or update them here
        landmarks_df = pd.DataFrame(landmarks)
        self.landmarks_df = pd.concat([self.landmarks_df, landmarks_df], ignore_index=True)

        # Update the table with the latest landmarks for the current frame
        self.update_table()

    def process_queue(self):
        while not self.result_queue.empty():
            frame_landmarks = self.result_queue.get()
            new_df = pd.DataFrame(frame_landmarks)
            self.landmarks_df = pd.concat([self.landmarks_df, new_df], ignore_index=True)

        # Update the table with the current frame's landmarks
        self.update_table()

    def on_frame_change(self, value):
        self.load_frame(value)
        self.update_table()
        self.frame_number_label.setText(f"Frame: {value}")

    def get_landmarks_for_frame(self, frame_idx):
        if "Frame" not in self.landmarks_df.columns:
            return pd.DataFrame()
        return self.landmarks_df[self.landmarks_df["Frame"] == frame_idx]

    def update_table(self):
        landmarks = self.get_landmarks_for_frame(self.current_frame_index)
        self.landmark_table.setRowCount(len(landmarks))
        self.landmark_table.setColumnCount(5)
        self.landmark_table.setHorizontalHeaderLabels(["Frame", "Landmark", "X", "Y", "Z"])

        for i, (_, row) in enumerate(landmarks.iterrows()):
            for j, key in enumerate(row.keys()):
                item = QTableWidgetItem(str(row[key]))
                self.landmark_table.setItem(i, j, item)

        # Make table editable for X, Y, Z columns
        self.landmark_table.setEditTriggers(QTableWidget.AllEditTriggers)

    def on_table_item_changed(self, item):
        try:
            row = item.row()
            col = item.column()
            value = item.text()

            # Ensure the item is not None
            if not value:
                return

            # Update the landmarks_df with the new value
            frame_item = self.landmark_table.item(row, 0)
            landmark_item = self.landmark_table.item(row, 1)

            if frame_item is None or landmark_item is None:
                return

            frame_idx = int(float(frame_item.text()))
            landmark_idx = int(float(landmark_item.text()))

            self.landmarks_df.loc[
                (self.landmarks_df["Frame"] == frame_idx) & (self.landmarks_df["Landmark"] == landmark_idx),
                self.landmark_table.horizontalHeaderItem(col).text()
            ] = float(value)
        except ValueError as e:
            QMessageBox.critical(self, "Error", f"Invalid value: {e}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"An error occurred: {e}")

    def save_landmarks(self):
        save_path, _ = QFileDialog.getSaveFileName(self, "Save Landmarks", "", "CSV Files (*.csv)")
        if save_path:
            try:
                self.landmarks_df.to_csv(save_path, index=False)
                QMessageBox.information(self, "Success", "Landmarks saved successfully!")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to save landmarks: {e}")

    def update_progress(self, progress):
        self.setWindowTitle(f"Hand Tracking Editor - Progress: {progress}%")

    def handle_worker_error(self, error_message):
        QMessageBox.critical(self, "Error", error_message)

    def on_tracking_finished(self):
        QMessageBox.information(self, "Info", "Hand tracking is complete. You can now edit the landmarks.")
        self.landmark_table.setEditTriggers(QTableWidget.AllEditTriggers)

    def closeEvent(self, event):
        if self.worker:
            self.worker.stop()
        if self.cap:
            self.cap.release()
        self.hands.close()
        event.accept()

    def play_video(self):
        self.playing = True
        self.play_video_loop()

    def pause_video(self):
        self.playing = False

    def play_video_loop(self):
        if self.playing and self.current_frame_index < self.total_frames:
            self.current_frame_index += 1
            self.frame_slider.setValue(self.current_frame_index)
            QEventLoop().processEvents()
            QTimer.singleShot(30, self.play_video_loop)  # Adjust the delay as needed


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = HandTrackingApp()
    window.show()
    sys.exit(app.exec_())