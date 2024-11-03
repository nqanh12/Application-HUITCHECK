import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Participant {
  String userName;
  bool checkInStatus;
  DateTime? checkInTime;
  bool checkOutStatus;
  DateTime? checkOutTime;
  String? fullName;

  Participant({
    required this.userName,
    required this.checkInStatus,
    this.checkInTime,
    required this.checkOutStatus,
    this.checkOutTime,
    this.fullName,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userName: json['userName'],
      checkInStatus: json['checkInStatus'],
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutStatus: json['checkOutStatus'],
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
    );
  }
}

class EventParticipantsScreen extends StatefulWidget {
  final String token;
  final String eventId;

  const EventParticipantsScreen({super.key, required this.token, required this.eventId});

  @override
  EventParticipantsScreenState createState() => EventParticipantsScreenState();
}

class EventParticipantsScreenState extends State<EventParticipantsScreen> {
  List<Participant> participants = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/events/participants/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> participantsJson = data['result']['participants'];
      setState(() {
        participants = participantsJson.map((json) => Participant.fromJson(json)).toList();
        _fetchFullNames();
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load participants: ${response.statusCode}')),
      );
    }
  }

  Future<void> _fetchFullNames() async {
    for (var participant in participants) {
      final response = await http.get(
        Uri.parse('${baseUrl}api/users/getFullName/${participant.userName}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          participant.fullName = data['result']['full_Name'];
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load full name for ${participant.userName}: ${response.statusCode}')),
        );
      }
    }
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd-MM-yyyy  -  HH:mm').format(dateTime.add(const Duration(hours: 7)));
  }

  int countCheckInAndOut() {
    return participants.where((participant) => participant.checkInStatus && participant.checkOutStatus).length;
  }

  int countTotalParticipants() {
    return participants.length;
  }

  IconData getStatusIcon(Participant participant) {
    if (participant.checkInStatus && participant.checkOutStatus) {
      return Icons.check_circle;
    } else if (participant.checkInStatus || participant.checkOutStatus) {
      return Icons.warning;
    } else {
      return Icons.cancel;
    }
  }

  Color getStatusColor(Participant participant) {
    if (participant.checkInStatus && participant.checkOutStatus) {
      return Colors.green;
    } else if (participant.checkInStatus || participant.checkOutStatus) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          child: Text(
            "Danh sách sinh viên",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 25, 117, 215),
              Color.fromARGB(255, 255, 255, 255),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Tổng số sinh viên đã hoàn thành: ${countCheckInAndOut()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tổng số sinh viên tham gia sự kiện: ${countTotalParticipants()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchParticipants,
                  child: ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 240, 245, 252),
                                Color.fromARGB(255, 197, 216, 236),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color.fromARGB(255, 25, 117, 215),
                              child: Text(
                                participant.fullName?.substring(0, 1) ?? '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              participant.fullName ?? "Chưa cập nhật",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                      'Check-in: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      participant.checkInStatus ? "Đã Check-in" : "Chưa Check-in",
                                      style: TextStyle(
                                        color: participant.checkInStatus ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                      'Giờ vào: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      formatDateTime(participant.checkInTime),
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                      'Check-out: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      participant.checkOutStatus ? "Đã Check-out" : "Chưa Check-out",
                                      style: TextStyle(
                                        color: participant.checkOutStatus ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                      'Giờ ra: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      formatDateTime(participant.checkOutTime),
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              getStatusIcon(participant),
                              color: getStatusColor(participant),
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}