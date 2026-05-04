// services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationService {
  static const String baseUrl = 'https://routefixer.dpdns.org/api';

  Future<List<NotificationModel>> getNotifications(String firebaseUid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/$firebaseUid/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<bool> markAsRead(String firebaseUid, String notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$firebaseUid/$notificationId/read/'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(String firebaseUid) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$firebaseUid/mark-all-read/'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(
    String firebaseUid,
    String notificationId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$firebaseUid/$notificationId/'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
}
