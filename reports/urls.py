from django.urls import path
from .views import get_reports_by_segment, get_segment_details, update_report_status , admin_get_reports, get_dashboard_stats, get_reports, get_segments_from_map

urlpatterns = [
    path('reports/bulk-update/', update_report_status),
    path('reports/<str:firebase_uid>/', get_reports),
    path('road-segments/map/', get_segments_from_map),
    path('admin/reports/', admin_get_reports),
    path('dashboard/stats/', get_dashboard_stats),
    path('segments/<int:segment_id>/details/', get_segment_details),
    path('reports/segment/<int:segment_id>/', get_reports_by_segment, name='reports_by_segment'),
]
