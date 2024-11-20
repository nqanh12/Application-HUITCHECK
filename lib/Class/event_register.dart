class EventRegistration {
  final String eventId;
  final String name;
  final DateTime registrationDate;
  final String qrCode;
  final bool checkInStatus;
  final DateTime? checkInTime;
  final bool checkOutStatus;
  final DateTime? checkOutTime;

  EventRegistration({
    required this.eventId,
    required this.name,
    required this.registrationDate,
    required this.qrCode,
    required this.checkInStatus,
    this.checkInTime,
    required this.checkOutStatus,
    this.checkOutTime,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      eventId: json['eventId'] ?? '',
      name: json['name'] ?? 'Chưa bổ sung',
      registrationDate: DateTime.parse(json['registrationDate']),
      qrCode: json['qrCode'] ?? '',
      checkInStatus: json['checkInStatus'] ?? false,
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutStatus: json['checkOutStatus'] ?? false,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'name': name,
      'registrationDate': registrationDate.toIso8601String(),
      'qrCode': qrCode,
      'checkInStatus': checkInStatus,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutStatus': checkOutStatus,
      'checkOutTime': checkOutTime?.toIso8601String(),
    };
  }
}