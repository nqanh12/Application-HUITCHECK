import 'package:huitcheck/Class/event_register.dart';
import 'package:huitcheck/Class/training_point.dart';

class Users {
  final String id;
  final String userName;
  final String fullName;
  final String departmentId;
  final String gender;
  final String classId;
  final List<TrainingPoint> trainingPoint;
  final String email;
  final String? phone;
  final String? address;
  final List<EventRegistration> eventsRegistered;
  final List<String> roles;
  final int totalEventsRegistered;

  Users({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.departmentId,
    required this.gender,
    required this.classId,
    required this.trainingPoint,
    required this.email,
    this.phone,
    this.address,
    required this.eventsRegistered,
    required this.roles,
    required this.totalEventsRegistered,
  });

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      fullName: json['full_Name'] ?? '',
      departmentId: json['departmentId'] ?? '',
      gender: json['gender'] ?? '',
      classId: json['classId'] ?? '',
      trainingPoint: (json['training_point'] as List? ?? [])
          .map((tp) => TrainingPoint.fromJson(tp))
          .toList(),
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      eventsRegistered: (json['eventsRegistered'] as List? ?? [])
          .map((event) => EventRegistration.fromJson(event))
          .toList(),
      roles: List<String>.from(json['roles'] ?? []),
      totalEventsRegistered: json['totalEventsRegistered'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'full_Name': fullName,
      'departmentId': departmentId,
      'gender': gender,
      'classId': classId,
      'training_point': trainingPoint.map((tp) => tp.toJson()).toList(),
      'email': email,
      'phone': phone,
      'address': address,
      'eventsRegistered': eventsRegistered.map((event) => event.toJson()).toList(),
      'roles': roles,
      'totalEventsRegistered': totalEventsRegistered,
    };
  }
}
