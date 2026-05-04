from reports.models import RoadCaptureSegment, Report
from reports.utils.geo import haversine
from django.conf import settings
import googlemaps

gmaps = googlemaps.Client(key=settings.GOOGLE_ROADS_API_KEY)

SEGMENT_MATCH_RADIUS = 20     # meters
SEGMENT_EXTEND_RADIUS = 30    # meters


# ============================================================
# MAIN ENTRY
# ============================================================
def resolve_road_segment(report: Report):
    lat = float(report.latitude)
    lng = float(report.longitude)

    segments = RoadCaptureSegment.objects.filter(
        city=report.city,
        road_name=report.road_name
    )

    for segment in segments:
        start_dist = haversine(lat, lng, segment.start_lat, segment.start_lng)
        end_dist   = haversine(lat, lng, segment.end_lat, segment.end_lng)

        # 1️⃣ Attach only
        if start_dist < SEGMENT_MATCH_RADIUS or end_dist < SEGMENT_MATCH_RADIUS:
            attach_report(report, segment)
            return

        # 2️⃣ Extend start
        if start_dist < SEGMENT_EXTEND_RADIUS:
            extend_segment(segment, lat, lng, at_start=True)
            attach_report(report, segment)
            return

        # 3️⃣ Extend end
        if end_dist < SEGMENT_EXTEND_RADIUS:
            extend_segment(segment, lat, lng, at_start=False)
            attach_report(report, segment)
            return

    # 4️⃣ Create brand new segment
    create_new_segment(report)


# ============================================================
# SEGMENT CREATION
# ============================================================
def create_new_segment(report):
    lat = float(report.latitude)
    lng = float(report.longitude)

    polyline = generate_initial_polyline(lat, lng)

    start_lat, start_lng = parse_point(polyline[0])
    end_lat, end_lng     = parse_point(polyline[-1])
    center_lat, center_lng = calculate_center(polyline)

    segment = RoadCaptureSegment.objects.create(
        polyline_points="|".join(polyline),
        start_lat=start_lat,
        start_lng=start_lng,
        end_lat=end_lat,
        end_lng=end_lng,
        center_lat=center_lat,
        center_lng=center_lng,
        road_name=report.road_name,
        locality=report.locality,
        city=report.city,
    )

    attach_report(report, segment)


# ============================================================
# SEGMENT EXTENSION
# ============================================================
def extend_segment(segment, lat, lng, at_start=False):
    points = segment.polyline_points.split("|")

    anchor = parse_point(points[0] if at_start else points[-1])
    new_points = generate_extension_polyline(anchor, (lat, lng))

    if not new_points:
        return

    if at_start:
        points = new_points[::-1] + points
    else:
        points = points + new_points

    segment.polyline_points = "|".join(points)

    segment.start_lat, segment.start_lng = parse_point(points[0])
    segment.end_lat, segment.end_lng     = parse_point(points[-1])
    segment.center_lat, segment.center_lng = calculate_center(points)

    segment.save(update_fields=[
        "polyline_points",
        "start_lat", "start_lng",
        "end_lat", "end_lng",
        "center_lat", "center_lng"
    ])


# ============================================================
# GOOGLE ROADS HELPERS
# ============================================================
def generate_initial_polyline(lat, lng, length_m=50):
    """
    Generates ~50m road-aligned polyline centered at report point
    """
    delta = (length_m / 2) / 111320

    path = [
        (lat - delta, lng),
        (lat + delta, lng)
    ]

    return snap_path(path)


def generate_extension_polyline(p1, p2):
    """
    Generates road-aligned points between two GPS locations
    """
    return snap_path([p1, p2])


def snap_path(path):
    try:
        snapped = gmaps.snap_to_roads(
            path=path,
            interpolate=True
        )

        if not snapped:
            return []

        return [
            f"{p['location']['latitude']},{p['location']['longitude']}"
            for p in snapped
        ]

    except Exception as e:
        print(" Roads API error:", e)
        return []


# ============================================================
# UTILITIES
# ============================================================
def attach_report(report, segment):
    report.segment_id = segment.id
    report.save(update_fields=["segment_id"])


def parse_point(point_str):
    lat, lng = point_str.split(",")
    return float(lat), float(lng)


def calculate_center(points):
    lats, lngs = zip(*(parse_point(p) for p in points))
    return sum(lats) / len(lats), sum(lngs) / len(lngs)
