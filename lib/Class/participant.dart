class Participant {
  final String userName;
  final bool confirmed;
  final bool checkInStatus;
  final String? userCheckIn;
  final bool checkOutStatus;
  final DateTime? checkInTime;
  final String? userCheckOut;
  final DateTime? checkOutTime;
  String? fullName;
  String? className;

  Participant({
    required this.userName,
    this.confirmed = false,
    required this.checkInStatus,
    this.userCheckIn,
    required this.checkOutStatus,
    this.checkInTime,
    this.userCheckOut,
    this.checkOutTime,
    this.fullName,
    this.className
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
        userName: json['userName'] ?? '',
        confirmed: json['confirmed'] ?? false,
        checkInStatus: json['checkInStatus'] ?? false,
        userCheckIn: json['userCheckIn'] ?? '',
        checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
        checkOutStatus: json['checkOutStatus'] ?? false,
        userCheckOut: json['userCheckOut'] ?? '',
        checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
        fullName: json['fullName'] ?? 'Chưa bổ sung',
        className: json['class_id'] ?? 'Chưa bổ sung'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'confirmed': confirmed,
      'checkInStatus': checkInStatus,
      'userCheckIn': userCheckIn,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutStatus': checkOutStatus,
      'userCheckOut': userCheckOut,
      'checkOutTime': checkOutTime?.toIso8601String(),
      'fullName': fullName,
      'class_id': className
    };
  }
}