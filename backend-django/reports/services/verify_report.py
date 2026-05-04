import cv2
from pathlib import Path
from decimal import Decimal
from django.conf import settings
from reports.models import Report
from reports.services.yolo_service import run_yolo
from notifications.services import send_notification
import logging

logger = logging.getLogger(__name__)

# ===============================
# BBOX OUTPUT DIR (teacher view)
# ===============================
BBOX_DIR = Path(settings.MEDIA_ROOT) / "verified_bbox"
BBOX_DIR.mkdir(parents=True, exist_ok=True)


# ============================================================
# SAFE NOTIFICATION HANDLER (Never break ML pipeline)
# ============================================================
def notify_user(report, title, message):
    try:
        if not report.firebase_uid:
            logger.warning(f"[NOTIFY] Missing Firebase UID for report {report.id}")
            return

        send_notification(
            firebase_uid=report.firebase_uid,
            report=report,
            title=title,
            message=message,
            notification_type="YOLO"
        )

    except Exception as e:
        logger.error(f"[NOTIFY ERROR] {str(e)}")


# ============================================================
# SAVE BOUNDING BOX IMAGE
# ============================================================
def save_bbox_image(img, detections, report_id):
    """
    Saves single bbox image per report.
    Overwrites previous file to prevent duplicates.
    """

    for d in detections:
        x1, y1, x2, y2 = map(int, d["box"])

        label = (
            f"{d['class']} | "
            f"Conf: {round(d['confidence'] * 100, 1)}% | "
            f"Sev: {round(d['severity'], 2)}"
        )

        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)

        cv2.putText(
            img,
            label,
            (x1, max(y1 - 10, 20)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            (0, 255, 0),
            2
        )

    filename = f"report_{report_id}.jpg"
    output_path = BBOX_DIR / filename
    cv2.imwrite(str(output_path), img)


# ============================================================
# MAIN VERIFICATION FUNCTION
# ============================================================
def verify_image(report_id):

    try:
        report = Report.objects.get(id=report_id)
    except Report.DoesNotExist:
        logger.warning(f"[VERIFY] Report {report_id} does not exist")
        return

    # ----------------------------------------------------------
    # Prevent duplicate processing
    # ----------------------------------------------------------
    if report.status in ["Verified", "Rejected"]:
        logger.info(f"[VERIFY] Report {report.id} already processed")
        return

    old_status = report.status

    # ----------------------------------------------------------
    # Validate image existence
    # ----------------------------------------------------------
    if not report.image:
        logger.warning(f"[VERIFY] Report {report.id} has no image")
        return

    image_path = Path(report.image.path)

    if not image_path.exists():
        logger.error(f"[VERIFY] Image missing on disk: {image_path}")

        report.status = "Rejected"
        report.severity = "Low"
        report.save(update_fields=["status", "severity", "updated_at"])

        if old_status != report.status:
            notify_user(
                report,
                "Report rejected",
                "Image file was not found. Please upload a clear image."
            )
        return

    # ----------------------------------------------------------
    # Run YOLO
    # ----------------------------------------------------------
    result = run_yolo(str(image_path))

    if not result:
        logger.error(f"[VERIFY] YOLO processing failed for Report {report.id}")

        report.status = "Rejected"
        report.severity = "Low"
        report.save(update_fields=["status", "severity", "updated_at"])

        if old_status != report.status:
            notify_user(
                report,
                "Report rejected",
                "Image processing failed. Please try again."
            )
        return

    img, detections, scene_severity = result

    # ----------------------------------------------------------
    # No detections
    # ----------------------------------------------------------
    if not detections:
        report.status = "Rejected"
        report.ml_prediction = None
        report.ml_confidence = None
        report.severity = "Low"

        report.save(update_fields=[
            "status",
            "ml_prediction",
            "ml_confidence",
            "severity",
            "updated_at"
        ])

        if old_status != report.status:
            notify_user(
                report,
                "Report rejected",
                "No road damage was detected in your submitted image. Please upload a clear image."
            )

        return

    # ----------------------------------------------------------
    # Save bounding box image
    # ----------------------------------------------------------
    save_bbox_image(img, detections, report.id)

    # ----------------------------------------------------------
    # VERIFIED CASE
    # ----------------------------------------------------------
    max_confidence = max(d["confidence"] for d in detections)

    # Collect unique detected classes
    detected_classes = list(set(d["class"] for d in detections))
    prediction_string = ", ".join(cls.lower() for cls in detected_classes)

    # ----------------------------------------------------------
    # PROFESSIONAL SEVERITY CATEGORY MAPPING
    # ----------------------------------------------------------
    if scene_severity < 4:
        final_severity = "Low"
    elif scene_severity < 7.5:
        final_severity = "Medium"
    else:
        final_severity = "High"

    report.status = "Verified"
    report.ml_prediction = prediction_string
    report.ml_confidence = Decimal(round(max_confidence * 100, 2))
    report.severity = final_severity

    report.save(update_fields=[
        "status",
        "ml_prediction",
        "ml_confidence",
        "severity",
        "updated_at"
    ])

    if old_status != report.status:
        notify_user(
            report,
            "Report verified",
            "Your road damage report has been verified successfully."
        )

    logger.info(
        f"[VERIFY] Report {report.id} verified | "
        f"Classes: {prediction_string} | "
        f"Severity: {final_severity}"
    )