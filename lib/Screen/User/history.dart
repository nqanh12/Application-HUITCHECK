import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:huitcheck/Class/event_register.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class CheckInOutStatusScreen extends StatefulWidget {
  const CheckInOutStatusScreen({super.key});

  @override
  CheckInOutStatusScreenState createState() => CheckInOutStatusScreenState();
}

class CheckInOutStatusScreenState extends State<CheckInOutStatusScreen> {
  List<EventRegistration> events = [];
  String? selectedYear;
  String? selectedSemester;
  List<String> years = [];
  String? _token;
  Map<String, String> eventNames = {};

  @override
  void initState() {
    super.initState();
    _loadToken();
    _initializeYears();
    selectedYear = DateTime.now().year.toString();
    selectedSemester = 'Học kì 1';
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
    if (_token != null) {
      _fetchRegisteredEvents();
    }
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    for (int i = 0; i < 10; i++) {
      years.add((currentYear - i).toString());
    }
  }

  Future<void> _fetchRegisteredEvents() async {
    if (_token == null) return; // Ensure _token is not null before making the API call

    final response = await http.get(
      Uri.parse('${baseUrl}api/users/getRegisteredEvents'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<EventRegistration> fetchedEvents = (data['result']['eventsRegistered'] as List)
          .map((event) => EventRegistration.fromJson(event))
          .toList();

      for (var event in fetchedEvents) {
        eventNames[event.eventId] = await _fetchEventName(event.eventId);
      }

      setState(() {
        events = fetchedEvents;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load registered events: ${response.statusCode}')),
      );
    }
  }

  Future<String> _fetchEventName(String eventId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/events/getEventName/$eventId'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['result']['name'];
    } else {
      return 'Unknown Event';
    }
  }

  List<EventRegistration> _filterEventsByYearAndSemester() {
    return events.where((event) {
      final eventYear = event.registrationDate.year.toString();
      final eventMonth = event.registrationDate.month;
      if (selectedSemester == 'Học kì 1') {
        return eventYear == selectedYear && (eventMonth >= 8 || eventMonth <= 2);
      } else {
        return eventYear == selectedYear && (eventMonth >= 2 && eventMonth <= 6);
      }
    }).toList();
  }

  Future<void> _submitFeedback(String eventId, String feedback) async {
    final response = await http.post(
      Uri.parse('${baseUrl}api/feedback/createFeedback'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'eventId': eventId,
        'feedback': feedback,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gứi feedback thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: ${response.statusCode}')),
      );
    }
  }

  void _showFeedbackDialog(String eventId, String eventName) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Feedback của $eventName',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Nhập feedback',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _submitFeedback(eventId, feedbackController.text);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Gửi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filterEventsByYearAndSemester();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          child: Text(
            "Sự kiện đã đăng kí",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.height * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        elevation: 0,
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
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
        child: Center(
          child: SizedBox(
            width: 700,
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
                    child: Column(
                      children: [
                        DropdownButtonHideUnderline(
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
                        const SizedBox(height: 10),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            hint: const Text(
                              "Chọn học kì",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: selectedSemester,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedSemester = newValue;
                              });
                            },
                            items: ['Học kì 1', 'Học kì 2']
                                .map<DropdownMenuItem<String>>((String semester) {
                              return DropdownMenuItem<String>(
                                value: semester,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    semester,
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
                      ],
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
        ),
      ),
    );
  }

  Widget _buildEventCard(EventRegistration event) {

    if (event.checkInStatus && event.checkOutStatus) {
    } else if (event.checkInStatus) {
    } else if (event.checkOutStatus) {
    } else if (DateTime.now().isAfter(event.registrationDate)) {
    } else {
    }
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final String formattedRegistrationDate = formatter.format(event.registrationDate.add(const Duration(hours: 7)));
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
        elevation: 10,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          title: Text(
            eventNames[event.eventId] ?? event.name, // Use event name from the map
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 5),
              Row(
                children: [
                  Text(
                    "Ngày đăng kí:",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    formattedRegistrationDate,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _showFeedbackDialog(event.eventId, eventNames[event.eventId] ?? event.name);
                },
                icon: Icon(Icons.feedback_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}