import uuid
from django.db import models
from reports.models import Report


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    firebase_uid = models.CharField(max_length=255)
    fcm_token = models.CharField(max_length=255, null=True, blank=True)

    report = models.ForeignKey(
        Report,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(max_length=50)

    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} - {self.firebase_uid}"
