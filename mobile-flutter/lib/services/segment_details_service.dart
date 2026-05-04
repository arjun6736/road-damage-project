import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/segment_details.dart';

class SegmentDetailsService {
  final String baseUrl = "https://routefixer.dpdns.org/api";

  Future<SegmentDetails> fetchDetails(int segmentId) async {
    final url = Uri.parse("$baseUrl/segments/$segmentId/details/");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return SegmentDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load segment details");
    }
  }
}
