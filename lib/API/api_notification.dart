import 'package:huitcheck/API/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  final String token;

  NotificationService(this.token);

  Future<void> deleteNotification(String notificationId) async {
    final String url = '${baseUrl}api/users/deleteNotification/$notificationId';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification');
    }
  }
  Future<List<NotificationItem>> fetchNotifications() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/users/getNotifications'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['code'] == 1000) {
        final notifications = (data['result']['notifications'] as List)
            .map((json) => NotificationItem.fromJson(json))
            .toList();
        notifications.sort((a, b) => b.createDate.compareTo(a.createDate)); // Sort by createDate in descending order
        return notifications;
      } else {
        throw Exception('Failed to load notifications: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final url = '${baseUrl}api/users/markAsRead/$notificationId';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.statusCode}');
    }
  }

  Future<void> markAllAsRead() async {
    const url = '${baseUrl}api/users/markAllAsRead';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
    }
  }
}

class NotificationItem {
  String notificationId;
  String createUser;
  String message;
  String createDate;
  bool isRead;

  NotificationItem({
    required this.notificationId,
    required this.createUser,
    required this.message,
    required this.createDate,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notification_id'],
      createUser: json['createUser'],
      message: json['message'],
      createDate: json['createDate'],
      isRead: json['read'],
    );
  }
}