import 'package:huitcheck/Class/course.dart';
import 'package:huitcheck/Class/participant.dart';

class Event {
  final String id;
  final String eventId;
  final String name;
  final String departmentId;
  final int capacity;
  final int currentParticipants;
  final String description;
  final String locationId;
  final DateTime dateStart;
  final DateTime dateEnd;
  final String managerName;
  final List<Participant> participants;
  final List<Courses> courses;

  Event({
    required this.id,
    required this.eventId,
    required this.name,
    required this.departmentId,
    required this.capacity,
    required this.currentParticipants,
    required this.description,
    required this.locationId,
    required this.dateStart,
    required this.dateEnd,
    required this.managerName,
    required this.participants,
    required this.courses,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      departmentId: json['departmentId'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      description: json['description'] ?? '',
      locationId: json['locationId'] ?? '',
      dateStart: DateTime.parse(json['dateStart']),
      dateEnd: DateTime.parse(json['dateEnd']),
      managerName: json['managerName'] ?? '',
      participants: (json['participants'] as List<dynamic>?)
          ?.map((participant) => Participant.fromJson(participant))
          .toList() ?? [],
      courses: (json['course'] as List<dynamic>?)
          ?.map((course) => Courses.fromJson(course))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'departmentId': departmentId,
      'capacity': capacity,
      'currentParticipants': currentParticipants,
      'description': description,
      'locationId': locationId,
      'dateStart': dateStart.toIso8601String(),
      'dateEnd': dateEnd.toIso8601String(),
      'managerName': managerName,
      'participants': participants.map((participant) => participant.toJson()).toList(),
      'course': courses.map((course) => course.toJson()).toList(),
    };
  }
}