from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Notification


@api_view(["GET"])
def user_notifications(request, firebase_uid):

    notifications = Notification.objects.filter(
        firebase_uid=firebase_uid
    ).order_by("-created_at")

    data = [{
        "id": str(n.id),
        "title": n.title,
        "message": n.message,
        "type": n.notification_type,
        "is_read": n.is_read,
        "created_at": n.created_at.isoformat()
    } for n in notifications]

    return Response(data, status=status.HTTP_200_OK)


@api_view(["POST"])
def mark_as_read(request, firebase_uid, notification_id):

    updated = Notification.objects.filter(
        id=notification_id,
        firebase_uid=firebase_uid
    ).update(is_read=True)

    if updated:
        return Response({"success": True})
    return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)


@api_view(["POST"])
def mark_all_as_read(request, firebase_uid):

    updated = Notification.objects.filter(
        firebase_uid=firebase_uid,
        is_read=False
    ).update(is_read=True)

    return Response({"success": True, "updated_count": updated})


@api_view(["DELETE"])
def delete_notification(request, firebase_uid, notification_id):

    deleted, _ = Notification.objects.filter(
        id=notification_id,
        firebase_uid=firebase_uid
    ).delete()

    if deleted:
        return Response({"success": True}, status=status.HTTP_204_NO_CONTENT)

    return Response({"error": "Not found"}, status=status.HTTP_404_NOT_FOUND)
