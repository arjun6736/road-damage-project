import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoadSegment {
  final int id;
  final String roadName;
  final String locality;
  final String city;
  final String severity; // ✅ ADD THIS
  final List<LatLng> points;

  RoadSegment({
    required this.id,
    required this.roadName,
    required this.locality,
    required this.city,
    required this.severity,
    required this.points,
  });

  factory RoadSegment.fromJson(Map<String, dynamic> json) {
    return RoadSegment(
      id: json['id'],
      roadName: json['road_name'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      severity: json['max_severity'] ?? 'low', // ✅ SAFE DEFAULT
      points: _decodePolylineString(json['polyline_points']),
    );
  }

  static List<LatLng> _decodePolylineString(String polyline) {
    return polyline.split('|').map((pair) {
      final coords = pair.split(',');
      return LatLng(double.parse(coords[0]), double.parse(coords[1]));
    }).toList();
  }
}
