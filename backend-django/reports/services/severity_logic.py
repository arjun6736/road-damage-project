import math


# ============================================================
# IOU CALCULATION
# ============================================================

def compute_iou(box1, box2):
    """
    Compute Intersection over Union between two bounding boxes.
    Box format: [x1, y1, x2, y2]
    """

    x1 = max(box1[0], box2[0])
    y1 = max(box1[1], box2[1])
    x2 = min(box1[2], box2[2])
    y2 = min(box1[3], box2[3])

    inter_w = max(0, x2 - x1)
    inter_h = max(0, y2 - y1)

    inter_area = inter_w * inter_h

    area1 = max(0, box1[2] - box1[0]) * max(0, box1[3] - box1[1])
    area2 = max(0, box2[2] - box2[0]) * max(0, box2[3] - box2[1])

    union_area = area1 + area2 - inter_area

    if union_area <= 0:
        return 0.0

    return inter_area / union_area


# ============================================================
# OBJECT LEVEL SEVERITY (PROFESSIONALLY CALIBRATED)
# ============================================================

def compute_severity(box, confidence, img_w, img_h, cls_name):
    """
    Compute severity score from 1–10.

    Priority weights:
    Size        → 60%
    Type        → 15%
    Position    → 20%
    Confidence  → 5%
    """

    x1, y1, x2, y2 = box

    # ------------------------------------------------
    # SIZE SCORE (MOST IMPORTANT)
    # ------------------------------------------------

    box_w = max(0, x2 - x1)
    box_h = max(0, y2 - y1)
    box_area = box_w * box_h

    img_area = img_w * img_h

    if img_area == 0:
        return 1.0

    size_ratio = box_area / img_area

    # Logarithmic scaling for proper separation
    size_score = math.log1p(size_ratio * 60) / math.log1p(60)
    size_score = min(1.0, size_score)


    # ------------------------------------------------
    # POSITION SCORE
    # Objects closer to bottom are more dangerous
    # ------------------------------------------------

    vertical_position = ((y1 + y2) / 2) / img_h

    position_score = 0.5 + (vertical_position * 0.5)


    # ------------------------------------------------
    # DAMAGE TYPE SCORE
    # ------------------------------------------------

    damage_weights = {
        "pothole": 1.0,
        "alligator crack": 0.85,
        "rutting": 0.8,
        "crack": 0.6
    }

    type_score = damage_weights.get(cls_name.lower(), 0.5)


    # ------------------------------------------------
    # CONFIDENCE SCORE (small influence)
    # ------------------------------------------------

    confidence_score = 0.9 + (confidence * 0.1)


    # ------------------------------------------------
    # FINAL WEIGHTED SCORE
    # ------------------------------------------------

    weighted_score = (
        size_score * 0.60 +
        position_score * 0.20 +
        type_score * 0.15 +
        confidence_score * 0.05
    )

    severity = 1 + (weighted_score * 9)

    severity = max(1.0, min(10.0, severity))

    return float(round(severity, 2))


# ============================================================
# MERGE OVERLAPPING DETECTIONS
# ============================================================

def merge_overlapping_detections(detections, iou_threshold=0.8):
    """
    Merge duplicate detections representing same object.
    Keeps highest severity and averages confidence.
    """

    detections = detections.copy()
    merged = []

    while detections:

        base = detections.pop(0)
        group = [base]

        remaining = []

        for det in detections:

            iou = compute_iou(base["box"], det["box"])

            if iou >= iou_threshold:
                group.append(det)
            else:
                remaining.append(det)

        # Merge group properly
        if len(group) > 1:

            max_severity = max(d["severity"] for d in group)
            avg_conf = sum(d["confidence"] for d in group) / len(group)

            base["severity"] = round(
                max_severity * (0.97 + avg_conf * 0.03), 2
            )

            base["confidence"] = round(avg_conf, 3)

        merged.append(base)
        detections = remaining

    return merged


# ============================================================
# IMAGE LEVEL SEVERITY
# ============================================================

def compute_image_severity(detections):
    """
    Compute overall image severity (1–10)
    Based on worst damage and overall condition.
    """

    if not detections:
        return 1.0

    severities = [d["severity"] for d in detections]

    max_sev = max(severities)
    avg_sev = sum(severities) / len(severities)

    count = len(severities)

    # Worst damage dominates
    base_score = (max_sev * 0.75) + (avg_sev * 0.25)

    # Density escalation
    density_factor = min(1.15, 1.0 + count * 0.04)

    final_score = base_score * density_factor

    final_score = max(1.0, min(10.0, final_score))

    return float(round(final_score, 2))


# ============================================================
# COMPLETE PIPELINE FUNCTION
# ============================================================

def process_detections(raw_detections, img_w, img_h):
    """
    Full pipeline.

    raw_detections format:
    [
        {
            "box": [x1, y1, x2, y2],
            "confidence": float,
            "class": str
        }
    ]

    Returns:
        merged_detections,
        image_severity
    """

    processed = []

    for det in raw_detections:

        severity = compute_severity(
            det["box"],
            det["confidence"],
            img_w,
            img_h,
            det["class"]
        )

        processed.append({
            "box": det["box"],
            "confidence": det["confidence"],
            "class": det["class"],
            "severity": severity
        })

    merged = merge_overlapping_detections(processed)

    image_severity = compute_image_severity(merged)

    return merged, image_severity