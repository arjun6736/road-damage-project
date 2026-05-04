import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/road_segment.dart';

class RoadSegmentService {
  static const String baseUrl = "https://routefixer.dpdns.org/api";

  Future<List<RoadSegment>> fetchSegments({
    required double latitude,
    required double longitude,
    required int zoom,
  }) async {
    final uri = Uri.parse("$baseUrl/road-segments/map/").replace(
      queryParameters: {
        'lat': latitude.toStringAsFixed(6),
        'lng': longitude.toStringAsFixed(6),
        'zoom': zoom.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("API failed: ${response.statusCode}");
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => RoadSegment.fromJson(e)).toList();
  }
}
