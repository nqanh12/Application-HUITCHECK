class Notifications {
  // ignore: non_constant_identifier_names
  final String notification_id;
  final String createUser;
  final String message;
  final DateTime createDate;
  final bool isRead;

  Notifications({
    // ignore: non_constant_identifier_names
    required this.notification_id,
    required this.createUser,
    required this.message,
    required this.createDate,
    required this.isRead,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      notification_id: json['notification_id'] ?? '',
      createUser: json['createUser'] ?? '',
      message: json['message'] ?? '',
      createDate: DateTime.parse(json['createDate']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notification_id,
      'createUser': createUser,
      'message': message,
      'createDate': createDate.toIso8601String(),
      'isRead': isRead,
    };
  }
}