from celery import shared_task
from reports.models import Report
from reports.services.verify_report import verify_image
from reports.services.location_service import get_snapped_location
from reports.services.segment_service import resolve_road_segment

@shared_task(bind=True, autoretry_for=(Exception,), retry_backoff=30, retry_kwargs={'max_retries': 3})
def process_report_task(self, report_id):
    print(f"[CELERY] Processing Report {report_id}")

    try:
        report = Report.objects.get(id=report_id)
    except Report.DoesNotExist:
        print("Report not found")
        return

    # ===============================
    # STEP 1: YOLO Verification
    # ===============================
    verify_image(report_id)

    # 🔹 Reload updated state
    report.refresh_from_db()

    if report.status != "Verified":
        print("Image rejected by YOLO. Workflow stopped.")
        return

    print("YOLO verified successfully")

    # ===============================
    # STEP 2: Location Snapping
    # ===============================
    loc_data = get_snapped_location(report.latitude, report.longitude)

    if not loc_data:
        print("Google Maps snapping failed")
        return

    report.road_name = loc_data["road_name"]
    report.locality = loc_data["locality"]
    report.city = loc_data["city"]
    report.latitude = loc_data["snapped_lat"]
    report.longitude = loc_data["snapped_lon"]

    report.save(update_fields=[
        "road_name",
        "locality",
        "city",
        "latitude",
        "longitude",
        "updated_at"
    ])

    print(f"Location snapped: {report.road_name}")

    # ===============================
    # STEP 3: Segmentation (future)
    # ===============================
    # assign_road_segment.delay(report.id)
    resolve_road_segment(report)
    print("Segmentation completed")