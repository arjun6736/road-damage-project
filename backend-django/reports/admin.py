from django.contrib import admin
from .models import Report
from notifications.services import send_notification


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ("id", "status", "road_name", "city")
    list_filter = ("status", "city")

    def save_model(self, request, obj, form, change):
        old_status = None

        if change:
            old_status = Report.objects.get(pk=obj.pk).status

        super().save_model(request, obj, form, change)

        if change and old_status != obj.status:
            send_notification(
                firebase_uid=obj.firebase_uid,
                report=obj,
                title="Report status updated",
                message=f"Your report status changed to '{obj.status}'.",
                notification_type="ADMIN"
            )
