import 'package:huitcheck/API/constants.dart';
import 'package:huitcheck/Component/Admin/event_statistics.dart';
import 'package:huitcheck/Component/Admin/participant_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventList {
  String id;
  String eventId;
  String name;
  int capacity;
  String description;
  String locationId; // ID of the location
  DateTime dateStart;
  DateTime dateEnd;
  String managerId; // ID of the event manager

  EventList({
    required this.id,
    required this.eventId,
    required this.name,
    required this.capacity,
    required this.description,
    required this.locationId,
    required this.dateStart,
    required this.dateEnd,
    required this.managerId,
  });

  factory EventList.fromJson(Map<String, dynamic> json) {
    return EventList(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 0,
      description: json['description'] ?? '',
      locationId: json['locationId'] ?? '',
      dateStart: DateTime.parse(json['dateStart'] ?? ' '),
      dateEnd: DateTime.parse(json['dateEnd'] ?? ''),
      managerId: json['managerId'] ?? '',
    );
  }
}

class EventListManagementScreen extends StatefulWidget {
  final String token;
  final String role;
  const EventListManagementScreen({super.key, required this.token, required this.role});

  @override
  EventListManagementScreenState createState() => EventListManagementScreenState();
}

class EventListManagementScreenState extends State<EventListManagementScreen> {
  List<EventList> events = [];
  List<EventList> filteredEvents = [];
  TextEditingController searchController = TextEditingController();
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    _fetchEvents(); // Load initial events
  }

  Future<void> _fetchEvents() async {
    const String url = '${baseUrl}api/events/listEvent';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<EventList> loadedEvents = (data['result'] as List)
          .map((eventJson) => EventList.fromJson(eventJson))
          .toList();

      // Adjust the dateStart and dateEnd by adding 7 hours
      final adjustedEvents = loadedEvents.map((event) {
        event.dateStart = event.dateStart.add(const Duration(hours: 7));
        event.dateEnd = event.dateEnd.add(const Duration(hours: 7));
        return event;
      }).toList();

      setState(() {
        events = adjustedEvents;
        events.sort((a, b) => b.dateStart.compareTo(a.dateStart)); // Sort by date in descending order
        filteredEvents = events;
      });
    } else {
      // Handle error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: ${response.statusCode}')),
      );
    }
  }

  void _filterEvents(String query) {
    setState(() {
      final lowerCaseQuery = query.toLowerCase();

      filteredEvents = events.where((event) {
        final matchesName = event.name.toLowerCase().contains(lowerCaseQuery);

        // If a year is selected, filter by event's start date year
        final matchesYear = selectedYear == null || event.dateStart.year.toString() == selectedYear;

        return matchesName && matchesYear;
      }).toList();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Get the unique years from the event list
    List<String> eventYears = events
        .map((event) => event.dateStart.year.toString())
        .toSet()
        .toList(); // Use a Set to avoid duplicates
    eventYears.sort(); // Sort the years

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
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Tìm kiếm theo tên sự kiện",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
                onChanged: (value) {
                  _filterEvents(value); // Filter events when search query changes
                },
              ),
              const SizedBox(height: 10),
              // Dropdown for year filtering
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Increased vertical padding for more space
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  borderRadius: BorderRadius.circular(15),
                  elevation: 10,
                  value: selectedYear,
                  hint: const Text("Chọn năm"),
                  items: eventYears.map((year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value;
                      _filterEvents(searchController.text); // Re-apply the filter with the new year
                    });
                  },
                  isExpanded: true,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchEvents, // Pull-to-refresh functionality
                  child: filteredEvents.isEmpty
                      ? const Center(
                    child: Text(
                      'Chưa có sự kiện ',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      final dateFormat = DateFormat('dd-MM-yyyy HH:mm a');
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 10,
                        margin: const EdgeInsets.only(bottom: 30),
                        child: ListTile(
                          title: Text(event.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Địa điểm: ${event.locationId}"),
                              Text("Sức chứa: ${event.capacity}"),
                              Text("Bắt đầu: ${dateFormat.format(event.dateStart)}"),
                              Text("Kết thúc: ${dateFormat.format(event.dateEnd)}"),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'participants') {
                                // Navigate to the participant list
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParticipantListScreen(eventId: event.eventId, token: widget.token, role: widget.role,dateEnd: event.dateEnd),
                                  ),
                                );
                              } else if (value == 'statistics') {
                                // Navigate to the event statistics screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventStatisticsScreen(
                                      eventId: event.eventId,
                                      name: event.name,
                                      location: event.locationId,
                                      dateStart: event.dateStart,
                                      dateEnd: event.dateEnd,
                                      token: widget.token,
                                      role: widget.role,
                                      timestamp: DateTime.now(),
                                    ),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                const PopupMenuItem(
                                  value: 'participants',
                                  child: Text('Xem danh sách'),
                                ),
                                const PopupMenuItem(
                                  value: 'statistics',
                                  child: Text('Xem thống kế'),
                                ),
                              ];
                            },
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