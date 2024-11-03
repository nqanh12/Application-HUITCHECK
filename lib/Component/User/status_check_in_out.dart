import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

class CheckInOutStatusScreen extends StatefulWidget {
  final String token;
  final String role;
  const CheckInOutStatusScreen({super.key, required this.token, required this.role});

  @override
  CheckInOutStatusScreenState createState() => CheckInOutStatusScreenState();
}

class CheckInOutStatusScreenState extends State<CheckInOutStatusScreen> {
  List<Event> events = [];
  String? selectedYear;
  List<String> years = [];

  @override
  void initState() {
    super.initState();
    _initializeYears();
    _fetchRegisteredEvents();
    selectedYear = DateTime.now().year.toString();
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    for (int i = 0; i < 10; i++) {
      years.add((currentYear - i).toString());
    }
  }

  Future<void> _fetchRegisteredEvents() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/users/getRegisteredEvents'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<Event> fetchedEvents = (data['result']['eventsRegistered'] as List)
          .map((event) => Event.fromJson(event))
          .toList();

      for (var event in fetchedEvents) {
        event.name = await _fetchEventName(event.eventId);
      }

      setState(() {
        events = fetchedEvents;
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load registered events: ${response.statusCode}')),
      );
    }
  }

  Future<String?> _fetchEventName(String eventId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/events/getEventName/$eventId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['result']['name'];
    } else {
      return null;
    }
  }

  List<Event> _filterEventsByYear() {
    return events.where((event) {
      return DateTime.parse(event.registrationDate).year.toString() == selectedYear;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filterEventsByYear();

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
            "Trạng thái",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.06, // Điều chỉnh kích thước font theo tỷ lệ màn hình
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        elevation: 0,
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    hint: const Text(
                      "Chọn năm",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: selectedYear,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedYear = newValue;
                      });
                    },
                    items: years.map<DropdownMenuItem<String>>((String year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            year,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                      size: 24,
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredEvents.isEmpty
                  ? const Center(
                child: Text(
                  'Chưa đăng kí sự kiện nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _fetchRegisteredEvents,
                child: ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _buildEventCard(event);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    String status;
    Color statusColor;
    IconData statusIcon;

    if (event.checkInStatus && event.checkOutStatus) {
      status = 'Đã hoàn thành';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    } else if (event.checkInStatus) {
      status = 'Chưa check out';
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
    } else if (event.checkOutStatus) {
      status = 'Chưa check in';
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
    } else if (DateTime.now().isAfter(DateTime.parse(event.registrationDate))) {
      status = 'Đã Bỏ lỡ';
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    } else {
      status = 'Pending';
      statusColor = Colors.yellow;
      statusIcon = Icons.pending;
    }
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final String formattedCheckInTime = event.checkInTime != null
        ? formatter.format(DateTime.parse(event.checkInTime!).add(const Duration(hours: 7)))
        : 'Chưa điểm danh';
    final String formattedCheckOutTime = event.checkOutTime != null
        ? formatter.format(DateTime.parse(event.checkOutTime!).add(const Duration(hours: 7)))
        : 'Chưa điểm danh';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        elevation: 10, // Set the desired elevation
        borderRadius: BorderRadius.circular(15), // Optional: Add border radius for rounded corners
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          leading: Icon(
            statusIcon,
            color: statusColor,
            size: 35,
          ),
          title: Text(
            event.name ?? 'Loading ....',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Row(
                children: [
                  const Text(
                    "Check - in :",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Icon(
                    event.checkInStatus ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: event.checkInStatus ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                formattedCheckInTime,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Text(
                    "Check - out :",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    event.checkOutStatus ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: event.checkOutStatus ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                formattedCheckOutTime,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 15,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Event {
  final String eventId;
  String? name;
  final String registrationDate;
  final String qrCode;
  final bool checkInStatus;
  final String? checkInTime;
  final bool checkOutStatus;
  final String? checkOutTime;

  Event({
    required this.eventId,
    this.name,
    required this.registrationDate,
    required this.qrCode,
    required this.checkInStatus,
    this.checkInTime,
    required this.checkOutStatus,
    this.checkOutTime,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['eventId'],
      name: json['name'],
      registrationDate: json['registrationDate'],
      qrCode: json['qrCode'],
      checkInStatus: json['checkInStatus'],
      checkInTime: json['checkInTime'],
      checkOutStatus: json['checkOutStatus'],
      checkOutTime: json['checkOutTime'],
    );
  }
}