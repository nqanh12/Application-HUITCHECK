import 'package:huitcheck/API/constants.dart';
import 'package:huitcheck/Component/User/detail_event.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

class ListEvent extends StatefulWidget {
  final String role;
  final String token;
  const ListEvent({super.key, required this.role, required this.token});

  @override
  EventListScreenState createState() => EventListScreenState();
}

class EventListScreenState extends State<ListEvent> {
  List<dynamic> _events = [];
  List<String> _registeredEventIds = [];
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _filter = 'Đang diễn ra';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchEvents();
    _fetchRegisteredEvents();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchEvents();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
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
      setState(() {
        _events = json.decode(utf8.decode(response.bodyBytes))['result'];
        _events.sort((a, b) => DateTime.parse(b['dateStart']).compareTo(DateTime.parse(a['dateStart'])));
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: ${response.statusCode}')),
      );
    }
  }

  Future<void> _fetchRegisteredEvents() async {
    const String url = '${baseUrl}api/users/getRegisteredEvents';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> registeredEvents = json.decode(response.body)['result']['eventsRegistered'];
      setState(() {
        _registeredEventIds = registeredEvents.map((event) => event['eventId'].toString()).toList();
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load registered events: ${response.statusCode}')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreEvents();
    }
  }

  void _loadMoreEvents() {
    // Implement pagination if needed
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  String _formatDateTime(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
    return formatter.format(parsedDate);
  }

  void _onFilterChanged(String? value) {
    setState(() {
      _filter = value ?? 'Tất cả';
    });
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
            "Sự kiện",
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
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildFilterOptions(),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchEvents,
                  child: _events.isEmpty
                      ? const Center(
                    child: Text(
                      'Hiện tại không có sự kiện',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  )
                      : _buildEventList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 10.0),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Tìm kiếm sự kiện...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        value: _filter,
        onChanged: _onFilterChanged,
        items: <String>['Tất cả', 'Sắp tới', 'Đã qua', 'Đang diễn ra','Hôm nay']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        isExpanded: true,
        underline: Container(),
        icon: const Icon(Icons.filter_list, color: Colors.black),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildEventList() {
    final filteredEvents = _events
        .where((event) =>
    event['name'].toLowerCase().contains(_searchQuery.toLowerCase()) &&
        (_filter == 'Tất cả' || _applyFilter(event)))
        .toList();

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(filteredEvents[index], index);
      },
    );
  }

  bool _applyFilter(dynamic event) {
    final DateTime now = DateTime.now();
    final DateTime eventStartDate = DateTime.parse(event['dateStart']);
    final DateTime eventEndDate = DateTime.parse(event['dateEnd']);

    if (_filter == 'Sắp tới') {
      return eventStartDate.isAfter(now);
    } else if (_filter == 'Đã qua') {
      return eventEndDate.isBefore(now);
    } else if (_filter == 'Đang diễn ra') {
      return now.isAfter(eventStartDate) && now.isBefore(eventEndDate);
    } else if (_filter == 'Hôm nay') {
      return (eventStartDate.year == now.year &&
          eventStartDate.month == now.month &&
          eventStartDate.day == now.day) ||
          (eventStartDate.isBefore(now) && eventEndDate.isAfter(now));
    }
    return true;
  }

  Widget _buildEventCard(dynamic event, int index) {
    final bool isRegistered = _registeredEventIds.contains(event['eventId']);
    final DateTime now = DateTime.now();
    final DateTime adjustedDateStart = DateTime.parse(event['dateStart']).add(const Duration(hours: 7));
    final DateTime adjustedDateEnd = DateTime.parse(event['dateEnd']).add(const Duration(hours: 7));
    final DateTime eventEndDate = DateTime.parse(event['dateEnd']);
    final bool isPastEvent = now.isAfter(eventEndDate);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: isPastEvent ? Colors.red.withOpacity(0.5) : (isRegistered ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.9)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListTile(
          contentPadding: const EdgeInsets.all(5),
          title: Text(
            event['name'],
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Số lượng: ${event['capacity']}",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 5),
              Text(
                "Ngày bắt đầu: ${_formatDateTime(adjustedDateStart.toIso8601String())} ",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 5),
              Text(
                "Ngày kết thúc: ${_formatDateTime(adjustedDateEnd.toIso8601String())} ",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
          onTap: isPastEvent ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsScreen(
                  isRegistered: _registeredEventIds.contains(event['eventId']),
                  role: widget.role,
                  token: widget.token,
                  eventId: event['eventId'],
                  name: event['name'],
                  dateStart: event['dateStart'],
                  dateEnd: event['dateEnd'],
                  location: event['locationId'],
                  description: event['description'],
                  managerId: event['managerName'],
                  onUpdate: () {
                    _fetchEvents();
                    _fetchRegisteredEvents();
                  },
                ),
              ),
            ).then((_) {
              _fetchEvents(); // Reload data when returning from EventDetailsScreen
              _fetchRegisteredEvents();
            });
          },
        ),
      ),
    );
  }
}