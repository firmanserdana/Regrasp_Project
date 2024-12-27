import cv2
import os
import csv
import torch
from datetime import datetime
from mmpose.apis import MMPoseInferencer  # New unified inferencer interface
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

# Initialize MMPoseInferencer for InterHand2.6M-based 3D hand keypoint detection
inferencer = MMPoseInferencer(
    pose3d='internet_res50_4xb16-20e_interhand3d-256x256',  # Specify InterHand2.6M config
    pose3d_weights='checkpoints\\res50_intehand3dv1.0_all_256x256-42b7f2ac_20210702.pth',  # Path to downloaded checkpoint
    device='cuda' if torch.cuda.is_available() else 'cpu'
)

# OpenCV Video Capture
cap = cv2.VideoCapture(video_path)

# Prepare directories and file names
output_dir = 'Data'
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

# Prepare CSV file for output
csv_file_handle = open(csv_file, 'w', newline='')
csv_writer = csv.writer(csv_file_handle)
csv_writer.writerow(['timestamp', 'landmark_index', 'x', 'y', 'score'])  # CSV header

# Create a named window for displaying the video
window_name = 'Hand Tracking'
cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)

# Set brightness and contrast adjustment parameters
alpha = 0.8  # Contrast adjustment
beta = 14    # Brightness adjustment

while cap.isOpened():
    success, image = cap.read()
    if not success:
        print("Video processing completed.")
        break

    # Apply brightness and contrast adjustments
    adjusted_image = cv2.convertScaleAbs(image, alpha=alpha, beta=beta)

    # Run inference on the frame using MMPoseInferencer (updated API)
    result_generator = inferencer(adjusted_image)

    for result in result_generator:
        print(result)  # Print the result to debug

        if 'pred_instances' in result and result['pred_instances']:  # Check if any hand keypoints are detected
            hand_kpts = result['pred_instances']['keypoints'][0]  # Assume single-hand tracking

            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
            for idx, (x, y, score) in enumerate(hand_kpts):
                csv_writer.writerow([timestamp, idx, x.item(), y.item(), score.item()])

            # Visualization of keypoints (optional)
            vis_image = result['visualization'].get_image()
        else:
            print("No keypoints detected")  # Print message if no keypoints are detected
            vis_image = adjusted_image

        # Write the current frame to the video file
        out.write(vis_image)

        # Display the resulting frame
        cv2.imshow(window_name, vis_image)

        if cv2.waitKey(5) & 0xFF == 27:  # Press 'Esc' to exit
            break

# Release everything when done
cap.release()
out.release()
csv_file_handle.close()
cv2.destroyAllWindows()