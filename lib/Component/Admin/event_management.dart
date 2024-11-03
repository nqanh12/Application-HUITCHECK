import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class Event {
  String eventID;
  String name;
  int capacity;
  int currentParticipants;
  String description;
  String locationId;
  DateTime dateStart;
  DateTime dateEnd;
  String managerId;

  Event({
    required this.eventID,
    required this.name,
    required this.capacity,
    required this.description,
    required this.locationId,
    required this.dateStart,
    required this.dateEnd,
    required this.managerId,
    this.currentParticipants = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventID: json['eventId'],
      name: json['name'],
      capacity: json['capacity'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      description: json['description'],
      locationId: json['locationId'],
      dateStart: DateTime.parse(json['dateStart']),
      dateEnd: DateTime.parse(json['dateEnd']),
      managerId: json['managerName'],

    );
  }
}

class EventManagementScreen extends StatefulWidget {
  final String role;
  final String token;
  const EventManagementScreen({super.key, required this.role, required this.token});

  @override
  EventManagementScreenState createState() => EventManagementScreenState();
}

class EventManagementScreenState extends State<EventManagementScreen> {
  List<Event> events = [];
  List<Event> filteredEvents = [];
  TextEditingController searchController = TextEditingController();
  String? selectedYear;
  final Logger _logger = Logger();
  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year.toString();
    _fetchEvents(); // Load initial events
  }

  Future<void> _updateEvent(Event event) async {
    final adjustedDateStart = event.dateStart.subtract(const Duration(hours: 7));
    final adjustedDateEnd = event.dateEnd.subtract(const Duration(hours: 7));
    final String url = '${baseUrl}api/events/update/${event.eventID}';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'name': event.name,
        'capacity': event.capacity,
        'description': event.description,
        'locationId': event.locationId,
        'dateStart': adjustedDateStart.toIso8601String(),
        'dateEnd': adjustedDateEnd.toIso8601String(),
        'managerName': event.managerId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final updatedEvent = Event.fromJson(data['result']);
      setState(() {
        final index = events.indexWhere((e) => e.eventID == updatedEvent.eventID);
        if (index != -1) {
          events[index] = updatedEvent;
          filteredEvents = events;
        }
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: ${response.statusCode}')),
      );
    }
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
      final List<Event> loadedEvents = (data['result'] as List)
          .map((eventJson) => Event.fromJson(eventJson))
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
        _filterEvents(searchController.text); // Filter events after fetching
      });
    } else {
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
        final matchesYear = selectedYear == null || event.dateStart.year.toString() == selectedYear;
        return matchesName && matchesYear;
      }).toList();
    });
  }
  void _showLogoutDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Xác nhận xóa sự kiện",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: const Text("Bạn có chắc chắn muốn xóa sự kiện này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Không",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _deleteEvent(event);
                await _fetchEvents();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Có",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showEventForm({Event? event}) {
    final isEditing = event != null;
    final nameController = TextEditingController(text: isEditing ? event.name : '');
    final capacityController = TextEditingController(text: isEditing ? event.capacity.toString() : '');
    final descriptionController = TextEditingController(text: isEditing ? event.description : '');
    final locationIdController = TextEditingController(text: isEditing ? event.locationId : '');
    final managerNameController = TextEditingController(text: isEditing ? event.managerId : '');
    DateTime? selectedDateStart = isEditing ? event.dateStart : null;
    DateTime? selectedDateEnd = isEditing ? event.dateEnd : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? "Sửa sự kiện" : "Thêm sự kiện"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, "Tên sự kiện"),
                    const SizedBox(height: 10),
                    _buildTextField(capacityController, "Sức chứa", keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    _buildTextField(descriptionController, "Mô tả"),
                    const SizedBox(height: 10),
                    _buildTextField(locationIdController, "Địa điểm"),
                    const SizedBox(height: 10),
                    _buildTextField(managerNameController, "quản lí sự kiện"),
                    const SizedBox(height: 10),
                    _buildDatePicker("Ngày bắt đầu", selectedDateStart, (date) {
                      setState(() {
                        selectedDateStart = date;
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildDatePicker("Ngày kết thúc", selectedDateEnd, (date) {
                      setState(() {
                        selectedDateEnd = date;
                      });
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_validateForm(nameController, capacityController, descriptionController, locationIdController, managerNameController, selectedDateStart, selectedDateEnd)) {
                      if (isEditing) {
                        setState(() {
                          event.name = nameController.text;
                          event.capacity = int.parse(capacityController.text);
                          event.description = descriptionController.text;
                          event.locationId = locationIdController.text;
                          event.dateStart = selectedDateStart!;
                          event.dateEnd = selectedDateEnd!;
                          event.managerId = managerNameController.text;
                        });
                        _updateEvent(event);
                      } else {
                        final newEvent = Event(
                          eventID: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
                          capacity: int.parse(capacityController.text),
                          name: nameController.text,
                          description: descriptionController.text,
                          locationId: locationIdController.text,
                          dateStart: selectedDateStart!,
                          dateEnd: selectedDateEnd!,
                          managerId: managerNameController.text, // Replace with the actual manager ID
                        );
                        _createEvent(newEvent);
                        _sendNotification('Thông báo có ${newEvent.name} sắp diễn ra');
                        await _fetchEvents();
                      }
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                      );
                    }
                  },
                  child: Text(isEditing ? "Sửa" : "Thêm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _validateForm(
      TextEditingController nameController,
      TextEditingController capacityController,
      TextEditingController descriptionController,
      TextEditingController locationIdController,
      TextEditingController managerNameController,
      DateTime? selectedDateStart,
      DateTime? selectedDateEnd,
      ) {
    if (nameController.text.isEmpty ||
        capacityController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        locationIdController.text.isEmpty ||
        managerNameController.text.isEmpty ||
        selectedDateStart == null ||
        selectedDateEnd == null) {
      return false;
    }

    if (selectedDateEnd.isBefore(selectedDateStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải lớn hơn ngày bắt đầu')),
      );
      return false;
    }

    return true;
  }

  Future<void> _createEvent(Event event) async {
    // Subtract 7 hours from the dateStart and dateEnd
    final adjustedDateStart = event.dateStart.subtract(const Duration(hours: 7));
    final adjustedDateEnd = event.dateEnd.subtract(const Duration(hours: 7));

    final response = await http.post(
      Uri.parse('${baseUrl}api/events/createEvent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'name': event.name,
        'capacity': event.capacity,
        'description': event.description,
        'locationId': event.locationId,
        'dateStart': adjustedDateStart.toIso8601String(),
        'dateEnd': adjustedDateEnd.toIso8601String(),
        'managerName': event.managerId,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['code'] == 1000) {
        setState(() {
          events.add(Event.fromJson(data['result']));
          _filterEvents(searchController.text); // Re-apply the filter after adding a new event
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo sự kiện thành công')),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: ${data['message']}')),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: ${response.statusCode}')),
      );
    }
  }

  Future<void> _selectDateTime(BuildContext context, DateTime? initialDate, Function(DateTime) onDateTimeSelected) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Only allow dates from today onwards
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // Use 24-hour format
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        onDateTimeSelected(selectedDateTime);
      }
    }
  }
  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return InkWell(
      onTap: () => _selectDateTime(context, selectedDate, (date) {
        setState(() {
          onDateSelected(date);
        });
      }),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
        ),
        child: Text(
          selectedDate != null ? DateFormat('dd-MM-yyyy HH:mm a').format(selectedDate) : 'Chọn ngày và giờ',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Future<void> _sendNotification(String message) async {
    const String url = '${baseUrl}api/users/sendNotification';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['code'] == 1000) {
        _logger.i('Notification sent successfully');
      } else {
        // Handle API error response
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: ${data['message']}')),
        );
      }
    } else {
      // Handle HTTP error response
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: ${response.statusCode}')),
      );
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final String url = '${baseUrl}api/events/delete/${event.eventID}';
    final String urlUser  = '${baseUrl}api/users/deleteEventAllUSers/${event.eventID}';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    final responseUser = await http.delete(
      Uri.parse(urlUser),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200 && responseUser.statusCode == 200) {
      setState(() {
        events.remove(event);
        filteredEvents = events; // Reset filtered list after deletion
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa sự kiện thành công')),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa sự kiện thất bại: ${response.statusCode}')),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    List<String> eventYears = events
        .map((event) => event.dateStart.year.toString())
        .toSet()
        .toList(); // Use a Set to avoid duplicates
    eventYears.sort(); // Sort the years

    if (selectedYear != null && !eventYears.contains(selectedYear)) {
      selectedYear = null;
    }

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
              // Search Bar
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
                      'Chưa có sự kiện',
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
                              Text("Sức chứa : ${event.capacity}"),
                              Text("Số người tham gia : ${event.currentParticipants}"),
                              Text("Địa điểm : ${event.locationId}"),
                              Text("Bắt đầu: ${dateFormat.format(event.dateStart)}"),
                              Text("Kết thúc: ${dateFormat.format(event.dateEnd)}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _showEventForm(event: event),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showLogoutDialog(context, event),
                              ),
                            ],
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
      floatingActionButton: Material(
        elevation: 10,
        shadowColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: FloatingActionButton(
          onPressed: () => _showEventForm(),
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}

