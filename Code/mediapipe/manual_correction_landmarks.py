import cv2
import tkinter as tk
from tkinter import Canvas, Button
from tkinter import filedialog
import numpy as np
import matplotlib.pyplot as plt
import os

class LabelingTool:
    def __init__(self, root, video_path):
        self.root = root
        self.video_path = video_path
        self.cap = cv2.VideoCapture(video_path)
        self.total_frames = int(self.cap.get(cv2.CAP_PROP_FRAME_COUNT))
        self.fps = self.cap.get(cv2.CAP_PROP_FPS)
        self.current_frame = 0
        self.landmarks = {'shoulder': {}, 'elbow': {}, 'wrist': {}}
        self.selected_landmark = 'shoulder'
        self.canvas_image = None

        # Get video dimensions and resize for display
        self.video_width = int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        self.video_height = int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        self.display_width = int(self.video_width * 0.5)
        self.display_height = int(self.video_height * 0.5)

        # Set up the UI with resized canvas
        self.canvas = Canvas(root, width=self.display_width, height=self.display_height)
        self.canvas.pack(side=tk.LEFT)

        control_frame = tk.Frame(root)
        control_frame.pack(side=tk.RIGHT, fill=tk.Y)

        # Joint selection buttons
        Button(control_frame, text='Shoulder', command=lambda: self.change_label('shoulder')).pack(pady=10)
        Button(control_frame, text='Elbow', command=lambda: self.change_label('elbow')).pack(pady=10)
        Button(control_frame, text='Wrist', command=lambda: self.change_label('wrist')).pack(pady=10)
        
        # Navigation buttons
        Button(control_frame, text='Previous Frame', command=self.prev_frame).pack(pady=10)
        Button(control_frame, text='Next Frame', command=self.next_frame).pack(pady=10)
        Button(control_frame, text='Save Labels and Estimate Angle', command=self.save_and_estimate).pack(pady=10)

        self.canvas.bind("<Button-1>", self.click_event)
        root.bind("<Key>", self.key_event)
        self.show_frame()

    def change_label(self, landmark):
        self.selected_landmark = landmark

    def click_event(self, event):
        x, y = event.x, event.y
        self.landmarks[self.selected_landmark][self.current_frame] = (x, y)
        self.show_frame()

    def key_event(self, event):
        if event.keysym == "s":
            self.change_label('shoulder')
        elif event.keysym == "e":
            self.change_label('elbow')
        elif event.keysym == "w":
            self.change_label('wrist')
        elif event.keysym == "p":
            self.prev_frame()
        elif event.keysym == "n":
            self.next_frame()
        elif event.keysym == "Up":
            if self.current_frame in self.landmarks[self.selected_landmark]:
                x, y = self.landmarks[self.selected_landmark][self.current_frame]
                self.landmarks[self.selected_landmark][self.current_frame] = (x, y - 1)
                self.show_frame()
        elif event.keysym == "Down":
            if self.current_frame in self.landmarks[self.selected_landmark]:
                x, y = self.landmarks[self.selected_landmark][self.current_frame]
                self.landmarks[self.selected_landmark][self.current_frame] = (x, y + 1)
                self.show_frame()
        elif event.keysym == "Left":
            if self.current_frame in self.landmarks[self.selected_landmark]:
                x, y = self.landmarks[self.selected_landmark][self.current_frame]
                self.landmarks[self.selected_landmark][self.current_frame] = (x - 1, y)
                self.show_frame()
        elif event.keysym == "Right":
            if self.current_frame in self.landmarks[self.selected_landmark]:
                x, y = self.landmarks[self.selected_landmark][self.current_frame]
                self.landmarks[self.selected_landmark][self.current_frame] = (x + 1, y)
                self.show_frame()

    def prev_frame(self):
        self.current_frame = max(0, self.current_frame - 5)
        self.root.update_idletasks()  # Ensure the UI updates immediately
        self.show_frame()

    def next_frame(self):
        self.current_frame = min(self.total_frames - 1, self.current_frame + 5)
        self.carry_forward_labels()
        self.root.update_idletasks()  # Ensure the UI updates immediately
        self.show_frame()

    def carry_forward_labels(self):
        # Carry forward the last known positions to the current frame if not already labeled
        if self.current_frame not in self.landmarks['shoulder']:
            self.landmarks['shoulder'][self.current_frame] = self.landmarks['shoulder'].get(self.current_frame - 5, (self.display_width // 2, self.display_height // 2))
        if self.current_frame not in self.landmarks['elbow']:
            self.landmarks['elbow'][self.current_frame] = self.landmarks['elbow'].get(self.current_frame - 5, (self.display_width // 2, self.display_height // 2))
        if self.current_frame not in self.landmarks['wrist']:
            self.landmarks['wrist'][self.current_frame] = self.landmarks['wrist'].get(self.current_frame - 5, (self.display_width // 2, self.display_height // 2))

    def show_frame(self):
        self.cap.set(cv2.CAP_PROP_POS_FRAMES, self.current_frame)
        ret, frame = self.cap.read()
        if not ret:
            return
        
        # Resize frame
        frame_resized = cv2.resize(frame, (self.display_width, self.display_height))

        # Display previously labeled points
        for key, color in zip(self.landmarks.keys(), [(0, 255, 0), (255, 0, 0), (0, 0, 255)]):
            x, y = self.landmarks[key].get(self.current_frame, (self.display_width // 2, self.display_height // 2))
            cv2.circle(frame_resized, (x, y), 5, color, -1)

        self.photo = tk.PhotoImage(master=self.canvas, data=cv2.imencode('.png', frame_resized)[1].tobytes())
        self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW)
        self.root.update_idletasks()  # Ensure the UI updates immediately

    def save_and_estimate(self):
        angles = []

        # Linearly interpolate positions for all frames
        for landmark in self.landmarks:
            frames = sorted(self.landmarks[landmark].keys())
            positions = np.array([self.landmarks[landmark][frame] for frame in frames])
            for frame in range(self.total_frames):
                if frame not in self.landmarks[landmark]:
                    if frame < frames[0]:
                        self.landmarks[landmark][frame] = positions[0]
                    elif frame > frames[-1]:
                        self.landmarks[landmark][frame] = positions[-1]
                    else:
                        idx = np.searchsorted(frames, frame)
                        t0, t1 = frames[idx - 1], frames[idx]
                        p0, p1 = positions[idx - 1], positions[idx]
                        self.landmarks[landmark][frame] = p0 + (frame - t0) / (t1 - t0) * (p1 - p0)

        for i in range(self.total_frames):
            shoulder = np.array(self.landmarks['shoulder'][i])
            elbow = np.array(self.landmarks['elbow'][i])
            wrist = np.array(self.landmarks['wrist'][i])

            ba = shoulder - elbow
            bc = wrist - elbow

            cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
            angle = np.degrees(np.arccos(cosine_angle))
            angles.append(angle)

        # Resampling the angles to 200 Hz
        original_times = np.arange(0, len(angles) / self.fps, 1 / self.fps)
        new_times = np.arange(0, original_times[-1], 1 / 200)
        resampled_angles = np.interp(new_times, original_times, angles)

        # Save the resampled angles to a text file
        video_name = os.path.splitext(os.path.basename(self.video_path))[0]
        output_path = os.path.join(os.path.dirname(self.video_path), f"{video_name}_angles.txt")
        np.savetxt(output_path, np.column_stack((new_times, resampled_angles)), header="Time(s)\tAngle(deg)", fmt="%.6f")
        print(f"Resampled angles saved to {output_path}")

        # Plot the resampled elbow angle over time
        plt.figure(figsize=(10, 6))
        plt.plot(new_times, resampled_angles, label=f'Elbow Angle (Resampled at 200 Hz)')
        plt.xlabel('Time (seconds)')
        plt.ylabel('Elbow Angle (degrees)')
        plt.title('Elbow Angle Over Time (Resampled at 200 Hz)')
        plt.legend()
        plt.grid(True)
        plt.show()

def main():
    root = tk.Tk()
    root.title("Manual Landmark Labeling Tool")
    video_path = filedialog.askopenfilename(title="Select Video File", filetypes=[("Video files", "*.mp4 *.avi *.mov")])
    if video_path:
        app = LabelingTool(root, video_path)
        root.mainloop()

if __name__ == "__main__":
    main()
       
