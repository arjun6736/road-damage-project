import cv2
import logging
from pathlib import Path
from ultralytics import YOLO

from reports.services.severity_logic import (
    compute_severity,
    merge_overlapping_detections,
    compute_image_severity
)

logger = logging.getLogger(__name__)

# ============================================================
# CONFIG
# ============================================================

MODEL_PATH = Path("ml_models/best.pt")

CONF_THRESHOLD = 0.25
IOU_THRESHOLD = 0.45
IMG_SIZE = 640

_model = None


# ============================================================
# LOAD MODEL (Singleton)
# ============================================================

def get_model():
    global _model

    if _model is None:
        logger.info("[YOLO] Loading model...")
        _model = YOLO(str(MODEL_PATH))
        logger.info("[YOLO] Model loaded")

    return _model


# ============================================================
# PREPROCESS IMAGE
# ============================================================

def preprocess_image(image_path):
    img = cv2.imread(str(image_path))

    if img is None:
        raise ValueError("Failed to load image")

    height, width = img.shape[:2]

    return img, width, height


# ============================================================
# RUN YOLO
# ============================================================

def run_yolo(image_path):
    try:
        model = get_model()

        img, img_w, img_h = preprocess_image(image_path)

        results = model(
            img,
            imgsz=IMG_SIZE,
            conf=CONF_THRESHOLD,
            iou=IOU_THRESHOLD,
            device="cpu",  # change to "cuda" if GPU available
            verbose=False
        )

        result = results[0]

        detections = []

        if result.boxes is None or len(result.boxes) == 0:
            logger.info("[YOLO] No detections found")
            return img, [], 1.0

        boxes = result.boxes.xyxy.cpu().numpy()
        confs = result.boxes.conf.cpu().numpy()
        classes = result.boxes.cls.cpu().numpy()
        names = result.names

        for box, conf, cls_id in zip(boxes, confs, classes):
            cls_name = names[int(cls_id)]

            severity = compute_severity(
                box,
                conf,
                img_w,
                img_h,
                cls_name
            )

            detections.append({
                "box": box.tolist(),
                "confidence": float(conf),
                "class": cls_name,
                "severity": float(severity)
            })

        # 🔁 Merge >80% overlapping boxes
        detections = merge_overlapping_detections(detections)

        # 🎯 Scene severity = highest object severity
        scene_severity = compute_image_severity(detections)

        logger.info(f"[YOLO] {len(detections)} detections after merge")

        return img, detections, scene_severity

    except Exception as e:
        logger.error(f"[YOLO ERROR] {str(e)}")
        return None