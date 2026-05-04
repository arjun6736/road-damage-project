import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
from .models import Notification
import logging

logger = logging.getLogger(__name__)

# ============================================================
# Initialize Firebase (Only Once)
# ============================================================
if not firebase_admin._apps:
    cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT)
    firebase_admin.initialize_app(cred)


# ============================================================
# SEND FCM PUSH
# ============================================================
def send_push_notification(token, title, message, report_id=None):
    """
    Sends real-time FCM push notification.
    Includes report_id in data for Flutter navigation.
    """

    if not token:
        logger.warning("No FCM token provided")
        return

    try:
        msg = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=message,
            ),
            data={
                "report_id": str(report_id) if report_id else "",
                "type": "report_update"
            },
            token=token,
        )

        messaging.send(msg)
        logger.info("FCM notification sent successfully")

    except Exception as e:
        logger.error(f"FCM Error: {str(e)}")


# ============================================================
# STORE + PUSH NOTIFICATION
# ============================================================
def send_notification(*, firebase_uid, report, title, message, notification_type):
    """
    Stores notification in DB + sends FCM push.
    Simple single-device logic (college project version).
    """

    # 1️⃣ Store notification in DB
    notification = Notification.objects.create(
        firebase_uid=firebase_uid,
        report=report,
        title=title,
        message=message,
        notification_type=notification_type,
    )

    # 2️⃣ Get FCM token from Report model
    token = getattr(report, "fcm_token", None)

    # 3️⃣ Send push notification
    send_push_notification(
        token=token,
        title=title,
        message=message,
        report_id=report.id
    )

    return notification
