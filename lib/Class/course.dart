class Courses {
  final String courseId;
  final String courseName;
  final String id;

  Courses({required this.courseId, required this.courseName, required this.id});

  factory Courses.fromJson(Map<String, dynamic> json) {
    return Courses(
      courseId: json['courseId'].toString(),
      courseName: json['courseName'] ?? '',
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      '_id': id,
    };
  }
}