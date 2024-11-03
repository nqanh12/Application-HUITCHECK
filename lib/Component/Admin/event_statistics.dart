import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

final DateFormat dateFormat = DateFormat('dd-MM-yyyy HH:mm a');

class EventStatisticsScreen extends StatefulWidget {
  final String eventId;
  final String name;
  final String location;
  final DateTime dateStart;
  final DateTime dateEnd;
  final DateTime timestamp;
  final String token;
  final String role;

  const EventStatisticsScreen({
    super.key,
    required this.eventId,
    required this.name,
    required this.location,
    required this.dateStart,
    required this.dateEnd,
    required this.timestamp,
    required this.token,
    required this.role,
  });

  @override
  EventStatisticsScreenState createState() => EventStatisticsScreenState();
}

class EventStatisticsScreenState extends State<EventStatisticsScreen> {
  int totalParticipants = 0;
  int checkedIn = 0;
  int checkedOut = 0;
  int completedBoth = 0;
  int notCompletedEither = 0;

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
      final participants = data['result']['participants'] as List;

      setState(() {
        totalParticipants = participants.length;
        checkedIn = participants.where((p) => p['checkInStatus']).length;
        checkedOut = participants.where((p) => p['checkOutStatus']).length;
        completedBoth = participants.where((p) => p['checkInStatus'] && p['checkOutStatus']).length;
        notCompletedEither = participants.where((p) => !p['checkInStatus'] && !p['checkOutStatus']).length;
      });
    } else {
      // Handle error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load participants: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00, // Điều chỉnh padding theo tỷ lệ màn hình
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00, // Điều chỉnh padding tiêu đề theo chiều cao màn hình
          ),
          child: Text(
            "Thống kê",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.06, // Điều chỉnh kích thước font theo tỷ lệ màn hình
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        toolbarHeight: MediaQuery.of(context).size.height * 0.06, // Điều chỉnh chiều cao AppBar theo màn hình
      ),
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
              // Event Information Card
              Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Name
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Date
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ngày bắt đầu: ${dateFormat.format(widget.dateStart)} \n Ngày kết thúc: ${dateFormat.format(widget.dateEnd)}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Statistics Card
              Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thống kê',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatisticTile('Tổng số sinh viên', totalParticipants, Icons.people, Colors.blue),
                          _buildStatisticTile('Đã điểm danh', completedBoth, Icons.check_circle, Colors.green),
                          _buildStatisticTile('Chưa điểm danh', notCompletedEither, Icons.warning_amber, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticTile(String title, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }
}