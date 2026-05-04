from django.db import models
from django.utils import timezone

class Report(models.Model):
    # -------------------------
    # Core Report Fields
    # -------------------------
    firebase_uid = models.CharField(max_length=100)
    fcm_token = models.CharField(max_length=255, null=True, blank=True)
    image = models.ImageField(
        upload_to='report_images/',
        null=True,
        blank=True
    )

    damage_type = models.CharField(max_length=50)
    severity = models.CharField(max_length=20, default='Low')

    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)

    description = models.TextField(blank=True, null=True)

    # -------------------------
    # YOLOv8 Outputs
    # -------------------------
    ml_prediction = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text="YOLO detected damage class (e.g., pothole, crack)"
    )

    ml_confidence = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="YOLO confidence score (%)"
    )

    # -------------------------
    # Reverse Geocoding Fields
    # -------------------------
    road_name = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Reverse-geocoded road/street name"
    )

    locality = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="Area or sub-locality"
    )

    city = models.CharField(
        max_length=100,
        blank=True,
        null=True
    )

    # -------------------------
    # Dynamic Segment / Grouping
    # -------------------------
    segment_id = models.IntegerField(
        null=True,
        blank=True,
        help_text="ID of the road segment this report belongs to"
    )

    # -------------------------
    # Workflow Status
    # -------------------------
    STATUS_CHOICES = [
        ('Pending', 'Pending'),
        ('Rejected', 'Rejected'),
        ('Verified', 'Verified'),
        ('In-Process', 'In-Process'),
        ('Resolved', 'Resolved'),
    ]
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='Pending'
    )

    timestamp = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Report {self.pk} | Segment {self.segment_id} | {self.status}"


class RoadCaptureSegment(models.Model):
    """
    Stores continuous road segments.
    Multiple reports can belong to one segment.
    """

    # Polyline: "lat1,lng1|lat2,lng2|..."
    polyline_points = models.TextField()

    # Segment endpoints
    start_lat = models.DecimalField(max_digits=10, decimal_places=7)
    start_lng = models.DecimalField(max_digits=10, decimal_places=7)
    end_lat = models.DecimalField(max_digits=10, decimal_places=7)
    end_lng = models.DecimalField(max_digits=10, decimal_places=7)

    # Center for map focus
    center_lat = models.DecimalField(max_digits=10, decimal_places=7)
    center_lng = models.DecimalField(max_digits=10, decimal_places=7)

    road_name = models.CharField(max_length=255, blank=True, null=True)
    locality = models.CharField(max_length=100, blank=True, null=True)
    city = models.CharField(max_length=100, blank=True, null=True)

    capture_time = models.DateTimeField(default=timezone.now)

    class Meta:
        verbose_name = "Road Segment"

    def __str__(self):
        return f"Road Segment {self.id} | {self.road_name}"
