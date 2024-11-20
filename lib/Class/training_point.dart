class TrainingPoint {
  final int semesterOne;
  final int semesterTwo;
  final int semesterThree;
  final int semesterFour;
  final int semesterFive;
  final int semesterSix;
  final int semesterSeven;
  final int semesterEight;

  TrainingPoint({
    required this.semesterOne,
    required this.semesterTwo,
    required this.semesterThree,
    required this.semesterFour,
    required this.semesterFive,
    required this.semesterSix,
    required this.semesterSeven,
    required this.semesterEight,
  });

  factory TrainingPoint.fromJson(Map<String, dynamic> json) {
    return TrainingPoint(
      semesterOne: json['semesterOne'] ?? 0,
      semesterTwo: json['semesterTwo'] ?? 0,
      semesterThree: json['semesterThree'] ?? 0,
      semesterFour: json['semesterFour'] ?? 0,
      semesterFive: json['semesterFive'] ?? 0,
      semesterSix: json['semesterSix'] ?? 0,
      semesterSeven: json['semesterSeven'] ?? 0,
      semesterEight: json['semesterEight'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semesterOne': semesterOne,
      'semesterTwo': semesterTwo,
      'semesterThree': semesterThree,
      'semesterFour': semesterFour,
      'semesterFive': semesterFive,
      'semesterSix': semesterSix,
      'semesterSeven': semesterSeven,
      'semesterEight': semesterEight,
    };
  }
}