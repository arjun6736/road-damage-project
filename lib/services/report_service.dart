import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ReportService {
  static const String baseUrl = "https://routefixer.dpdns.org/api";

  // =====================================================
  // GET USER REPORTS
  // =====================================================
  Future<List<dynamic>> getReports(String firebaseUid) async {
    final url = Uri.parse("$baseUrl/reports/$firebaseUid/");

    debugPrint("API CALL → GET USER REPORTS");
    debugPrint("URL → $url");

    final response = await http.get(url);

    debugPrint("STATUS → ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      debugPrint("USER REPORTS COUNT → ${data.length}");

      return data;
    } else {
      debugPrint("FAILED USER REPORT FETCH");

      throw Exception("Failed to load reports");
    }
  }

  // =====================================================
  // GET SEGMENT REPORTS
  // =====================================================
  Future<List<dynamic>> getReportsBySegment(int segmentId) async {
    debugPrint("API CALL → GET SEGMENT REPORTS");

    final response = await http.get(
      Uri.parse("https://routefixer.dpdns.org/api/reports/segment/$segmentId/"),
    );

    debugPrint("STATUS → ${response.statusCode}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = jsonDecode(response.body);

      final List<dynamic> reports = jsonBody['reports'] ?? [];

      debugPrint("PARSED REPORT COUNT → ${reports.length}");

      return reports;
    } else {
      throw Exception("Failed to fetch reports");
    }
  }

  // =====================================================
  // SEND REPORT
  // =====================================================
  Future<http.Response> sendReport({
    required String firebaseUid,
    required File imageFile,
    required String title,
    required String description,
    required String gps,
    required String time,
  }) async {
    final url = Uri.parse("$baseUrl/reports/$firebaseUid/");

    debugPrint("API CALL → SEND REPORT");
    debugPrint("URL → $url");

    final request = http.MultipartRequest("POST", url);

    final token = await FirebaseMessaging.instance.getToken();

    debugPrint("FCM TOKEN → $token");

    request.fields['damage_type'] = title;
    request.fields['description'] = description;
    request.fields['gps'] = gps;
    request.fields['time'] = time;
    request.fields['fcm_token'] = token ?? "";

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("SEND REPORT STATUS → ${response.statusCode}");

    return response;
  }
}
