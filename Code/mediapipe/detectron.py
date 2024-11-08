import cv2
import numpy as np
import torch
from detectron2.engine import DefaultPredictor
from detectron2.config import get_cfg
from detectron2 import model_zoo
from detectron2.utils.visualizer import Visualizer

# Initialize Detectron2 Mask R-CNN model
def setup_mask_rcnn():
    cfg = get_cfg()
    cfg.merge_from_file(model_zoo.get_config_file("COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml"))
    cfg.MODEL.ROI_HEADS.SCORE_THRESH_TEST = 0.5  # Set threshold for this model
    cfg.MODEL.WEIGHTS = model_zoo.get_checkpoint_url("COCO-InstanceSegmentation/mask_rcnn_R_50_FPN_3x.yaml")
    cfg.MODEL.DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
    return DefaultPredictor(cfg)

# Function to remove segmented objects (rubber bands)
def remove_segmented_objects(image_bgr, predictor):
    outputs = predictor(image_bgr)
    
    # Get masks of detected objects
    masks = outputs["instances"].pred_masks.cpu().numpy()
    
    # Create a mask for all detected objects (e.g., rubber bands)
    combined_mask = np.zeros_like(image_bgr[:, :, 0], dtype=np.uint8)
    
    for mask in masks:
        combined_mask = np.logical_or(combined_mask, mask).astype(np.uint8)
    
    # Inpaint (remove) the detected objects by filling in masked areas
    inpainted_image = cv2.inpaint(image_bgr, combined_mask * 255, inpaintRadius=3, flags=cv2.INPAINT_TELEA)
    
    return inpainted_image

# Initialize Detectron2 predictor (Mask R-CNN)
predictor = setup_mask_rcnn()

# Open video capture
cap = cv2.VideoCapture('your_video_path.mp4')

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        break

    # Remove rubber bands using object segmentation and inpainting
    processed_frame = remove_segmented_objects(frame, predictor)

    # Display processed frame
    cv2.imshow("Processed Frame", processed_frame)
    
    if cv2.waitKey(5) & 0xFF == 27:  # Press 'Esc' to exit
        break

cap.release()
cv2.destroyAllWindows()