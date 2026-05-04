# reports/views.py
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from notifications.services import send_notification
from .models import Report, RoadCaptureSegment
from .serializers import ReportSerializer, RoadSegmentSerializer
from math import radians, cos, sin, asin, sqrt

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser
from django.db.models import Q
from rest_framework.permissions import AllowAny
from django.db.models import Count
from reports.tasks import process_report_task
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.decorators import parser_classes
from django.db.models import Case, When, Value, IntegerField, Avg, Max

@api_view(['POST'])
def update_report_status(request):
    ids = request.data.get('report_ids', [])
    new_status = request.data.get('status')

    if not ids:
        return Response({"error": "No report IDs provided."}, status=status.HTTP_400_BAD_REQUEST)

    if not new_status:
        return Response({"error": "No status provided."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        reports = Report.objects.filter(id__in=ids)

        updated_count = reports.update(status=new_status)

        # Send push notifications
        for report in reports:
            send_notification(
                firebase_uid=report.firebase_uid,
                report=report,
                title="Report status updated",
                message=f"Your report status changed to '{new_status}'.",
                notification_type="ADMIN"
            )

        return Response({
            "message": "Update Successful",
            "updated_count": updated_count
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
def admin_get_reports(request):
    qs = Report.objects.all()

    # -------- FILTERS --------
    status = request.GET.get('status')
    severity = request.GET.get('severity')
    search = request.GET.get('search')
    from_date = request.GET.get('from_date')
    to_date = request.GET.get('to_date')
    ordering = request.GET.get('ordering', '-timestamp')

    #  Whitelist ordering (CRITICAL)
    ALLOWED_ORDERING = {
        'timestamp', '-timestamp',
        'updated_at', '-updated_at',
        'severity', '-severity',
        'status', '-status',
    }

    if ordering not in ALLOWED_ORDERING:
        ordering = '-timestamp'

    if status:
        qs = qs.filter(status=status)

    if severity:
        qs = qs.filter(severity=severity)

    if search:
        qs = qs.filter(
            Q(description__icontains=search) |
            Q(road_name__icontains=search)
        )

    if from_date:
        qs = qs.filter(timestamp__date__gte=from_date)

    if to_date:
        qs = qs.filter(timestamp__date__lte=to_date)

    qs = qs.order_by(ordering)

    serializer = ReportSerializer(
        qs,
        many=True,
        context={'request': request}
    )
    print(serializer.data)
    return Response(serializer.data)




@api_view(['GET'])
@permission_classes([AllowAny])
def get_dashboard_stats(request):
    # KPI Counts
    stats = Report.objects.aggregate(
        total=Count('id'),
        resolved=Count('id', filter=Q(status='Resolved')),
        pending=Count('id', filter=Q(status='Pending')),
        in_progress=Count('id', filter=Q(status='In Progress'))
    )

    # Severity Counts
    severity_stats = Report.objects.values('severity').annotate(count=Count('id'))
    severity_dict = {item['severity']: item['count'] for item in severity_stats}

    # Ensure all keys exist (prevents undefined in frontend)
    severity_dict = {
        "High": severity_dict.get("High", 0),
        "Medium": severity_dict.get("Medium", 0),
        "Low": severity_dict.get("Low", 0),
    }

    # Recent Reports
    recent_qs = Report.objects.order_by('-timestamp')[:5]
    recent_serializer = ReportSerializer(recent_qs, many=True, context={'request': request})

    return Response({
        "stats": stats,
        "severity_graph": severity_dict,
        "recent_reports": recent_serializer.data
    })



def haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    return R * c
def radius_from_zoom(zoom):
    # Convert zoom to radius (meters)
    if zoom >= 18:
        r = 150     # ~150m
    elif zoom >= 16:
        r = 500     # ~500m
    elif zoom >= 14:
        r = 2500    # ~2.5 km
    elif zoom >= 12:
        r = 12000   # ~12 km
    elif zoom >= 10:
        r = 30000   # ~30 km (district-level)
    else:
        r = 50000   # huge fallback

    MIN_R = 100       # do not go lower than 100m
    MAX_R = 20000     # do not exceed 20km (district size)

    if r < MIN_R:
        r = MIN_R
    
    if r > MAX_R:
        r = MAX_R

    return r
@api_view(['GET'])
def get_segments_from_map(request):
    try:
        lat = float(request.GET.get('lat'))
        lng = float(request.GET.get('lng'))
        zoom = int(request.GET.get('zoom', 15))

        # 1. Compute search radius
        radius = radius_from_zoom(zoom)

        # 2. Bounding box filter (Fast)
        lat_range = radius / 111111
        lng_range = radius / (111111 * cos(radians(lat)))

        candidate_segments = RoadCaptureSegment.objects.filter(
            center_lat__gte=lat - lat_range,
            center_lat__lte=lat + lat_range,
            center_lng__gte=lng - lng_range,
            center_lng__lte=lng + lng_range
        )

        # 3. Exact distance filter & Collect IDs
        final_segments = []
        visible_segment_ids = []
        
        for seg in candidate_segments:
            d = haversine(lat, lng, float(seg.center_lat), float(seg.center_lng))
            if d <= radius:
                final_segments.append(seg)
                visible_segment_ids.append(seg.id)

        # ---------------------------------------------------------
        # 4. AGGREGATE HIGHEST SEVERITY PER SEGMENT
        # ---------------------------------------------------------
        # We query the Report table ONCE for all visible segments.
        # We map text severities to numbers to find the MAX.
        
        severity_data = Report.objects.filter(segment_id__in=visible_segment_ids).annotate(
            severity_val=Case(
                When(severity__iexact='Critical', then=Value(4)),
                When(severity__iexact='High', then=Value(3)),
                When(severity__iexact='Medium', then=Value(2)),
                When(severity__iexact='Low', then=Value(1)),
                default=Value(0),
                output_field=IntegerField(),
            )
        ).values('segment_id').annotate(
            max_severity_score=Max('severity_val') # Finds the highest number (e.g. 3)
        )

        # 5. Create a lookup dictionary: { segment_id : max_score }
        # Example: { 101: 3, 102: 1 }
        severity_map = {item['segment_id']: item['max_severity_score'] for item in severity_data}

        # 6. Map scores back to text labels
        score_to_label = {
            4: 'Critical',
            3: 'High',
            2: 'Medium',
            1: 'Low',
            0: 'Low' # Default if no reports found
        }

        # 7. Serialize and Inject the Data
        serializer = RoadSegmentSerializer(final_segments, many=True)
        data = serializer.data

        for item in data:
            seg_id = item['id']
            # Get the max score for this segment (default to 0)
            max_score = severity_map.get(seg_id, 0)
            # Convert score (3) -> Text ("High")
            item['max_severity'] = score_to_label[max_score]

        return Response(data, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


# Define a temporary path for saving images (MUST be outside your app code)
@parser_classes([MultiPartParser, FormParser])
@api_view(['GET', 'POST'])
def get_reports(request, firebase_uid):
    
    # --------------------------
    # HANDLE GET REQUEST (GET ALL REPORTS FOR A SPECIFIC USER)
    # --------------------------
    if request.method == 'GET':
        try:
            reports = Report.objects.filter(firebase_uid=firebase_uid).order_by('-timestamp')
            serializer = ReportSerializer(reports, many=True, context={'request': request} )
            print("FILES:", request.FILES)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
             # Handle database or other unexpected errors
             return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


    # --------------------------
    # HANDLE POST REQUEST (SAVE NEW REPORT)
    # --------------------------
    elif request.method == 'POST':
        mutable_data = request.data.copy()
        mutable_data['firebase_uid'] = firebase_uid # Assign the UID from the URL

        # 3. Instantiate Serializer and Validate
        serializer = ReportSerializer(
            data=mutable_data,
            context={'request': request}
        )

        if serializer.is_valid():
            # 4. Save the instance and trigger the snapping signal
            report_instance = serializer.save() 
            process_report_task.delay(report_instance.id)
            # 5. Return success response
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            # 6. Return validation errors
            print("SERIALIZER ERRORS:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    # --------------------------
    # ⭐ FALLBACK (FIXES NONE TYPE ERROR)
    # --------------------------
    else:
        # This handles unexpected methods (PUT, DELETE, etc.) 
        # that might bypass the @api_view decorator.
        return Response(
            {"detail": f"Method '{request.method}' not allowed."},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
    
@api_view(['GET'])
@permission_classes([AllowAny])
def get_segment_details(request, segment_id):
    # 1. Get the Segment
    segment = get_object_or_404(RoadCaptureSegment, pk=segment_id)

    # 2. Get all reports for this segment
    reports = Report.objects.filter(segment_id=segment.id)

    # 3. LOGIC: Convert Text Severity to Numbers for Calculation
    # We map: Low -> 1, Medium -> 2, High -> 3, Critical -> 4
    severity_scoring = Case(
        When(severity__iexact='Low', then=Value(1)),
        When(severity__iexact='Medium', then=Value(2)),
        When(severity__iexact='High', then=Value(3)),
        When(severity__iexact='Critical', then=Value(4)),
        default=Value(1), # Default to 1 if unknown
        output_field=IntegerField(),
    )

    # 4. Run the Math (Aggregate)
    # We annotate the query with the numeric score, then average/max it
    stats = reports.annotate(score=severity_scoring).aggregate(
        total_reports=Count('id'),
        avg_score=Avg('score'),       # Calculates average of 1, 2, 3...
        max_score=Max('score'),       # Finds the highest number
        last_date=Max('timestamp')
    )

    # 5. Convert the Max Number back to Text for the UI
    # If max_score was 3, we want to return "High"
    score_to_text = {1: 'Low', 2: 'Medium', 3: 'High', 4: 'Critical'}
    
    # Handle edge case: if 0 reports, max_score is None, default to 'Low'
    max_severity_text = score_to_text.get(stats['max_score'], 'Low')

    # Handle edge case: if 0 reports, avg_score is None, default to 0.0
    avg_severity_val = stats['avg_score'] if stats['avg_score'] is not None else 0.0
    
    # Handle edge case: if 0 reports, use segment creation time
    last_report_time = stats['last_date'] if stats['last_date'] else segment.capture_time

    # 6. Return JSON matching your Dart Model
    return Response({
        "id": segment.id,
        "total_reports": stats['total_reports'],
        "max_severity": max_severity_text,       # Returns "High", "Low", etc.
        "last_report_date": last_report_time,
        "avg_severity": round(avg_severity_val, 2) # Returns 1.5, 2.0, etc.
    })

@api_view(['GET'])
def get_reports_by_segment(request, segment_id):

    try:
        reports = Report.objects.filter(
            segment_id=segment_id
        ).order_by('-timestamp')

        serializer = ReportSerializer(
            reports,
            many=True,
            context={'request': request}
        )

        return Response({
            "success": True,
            "segment_id": segment_id,
            "total_reports": reports.count(),
            "reports": serializer.data
        }, status=status.HTTP_200_OK)

    except Exception as e:

        return Response({
            "success": False,
            "error": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)