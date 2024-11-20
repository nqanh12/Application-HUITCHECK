import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:huitcheck/API/refresh_service.dart';
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
  List<Participant> filteredParticipants = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
    searchController.addListener(_filterParticipants);
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
        participants.sort((a, b) {
          final aTime = a.checkOutTime ?? a.checkInTime;
          final bTime = b.checkOutTime ?? b.checkInTime;
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          } else if (aTime != null) {
            return -1;
          } else if (bTime != null) {
            return 1;
          }
          return 0;
        });
        filteredParticipants = participants;
        _fetchFullNames();
      });
    } else {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load full name for ${participant.userName}: ${response.statusCode}')),
        );
      }
    }
  }

  void _filterParticipants() {
    setState(() {
      filteredParticipants = participants.where((participant) {
        return participant.fullName?.toLowerCase().contains(searchController.text.toLowerCase()) ?? false;
      }).toList();
    });
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
              const SizedBox(height: 10),
              Stack(
                children: [
                  Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Danh sách sinh viên',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(5),
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tổng số sinh viên tham gia sự kiện: ${countTotalParticipants()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm sinh viên',
                    prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchParticipants,
                  child: ListView.builder(
                    itemCount: filteredParticipants.length,
                    itemBuilder: (context, index) {
                      final participant = filteredParticipants[index];
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
                            title: Text(
                              participant.fullName ?? "Chưa cập nhật",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'MSSV: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      participant.userName,
                                      style: TextStyle(
                                        color: participant.checkInStatus ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
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
                                    IconButton(onPressed: (){
                                      RefreshService().refreshCheckInStatus(widget.eventId, participant.userName);
                                      Future.delayed(const Duration(seconds: 1), () {
                                        setState(() {
                                          _fetchParticipants();
                                        });
                                      });
                                    }, icon: Icon(Icons.refresh_outlined, color: Colors.green, size: 16,)),
                                  ],
                                ),
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
                                    IconButton(onPressed: (){
                                      RefreshService().refreshCheckOutStatus(widget.eventId, participant.userName);
                                      Future.delayed(const Duration(seconds: 1), () {
                                        setState(() {
                                          _fetchParticipants();
                                        });
                                      });
                                    }, icon: Icon(Icons.refresh_outlined, color: Colors.green, size: 16,)),
                                  ],
                                ),
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