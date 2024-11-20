import 'dart:async';
import 'package:huitcheck/API/api_login.dart';
import 'package:huitcheck/API/constants.dart';
import 'package:huitcheck/Screen/User/scannerqr.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
class ListEventCheck extends StatefulWidget {
  const ListEventCheck({super.key});

  @override
  EventListScreenState createState() => EventListScreenState();
}

class EventListScreenState extends State<ListEventCheck> {
  List<dynamic> _events = [];
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _timer;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _scrollController.addListener(_onScroll);
    _startAutoReload();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
    if (_token != null) {
      _fetchEvents();
    }
  }

  Future<void> _fetchEvents() async {
    if (_token == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? departmentId = prefs.getString('departmentId');
    String? role = prefs.getString('role');

    if (departmentId == null || role == null) return;

    const String url = '${baseUrl}api/events/listEvent';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> allEvents = json.decode(utf8.decode(response.bodyBytes))['result'];

      setState(() {
        _events = allEvents.where((event) {
          final DateFormat formatter = DateFormat('dd-MM-yyyy hh:mm a');
          final DateTime eventStartDate = DateTime.parse(event['dateStart']);
          final DateTime eventEndDate = DateTime.parse(event['dateEnd']);
          final DateTime now = DateTime.now();

          formatter.format(eventStartDate);
          formatter.format(eventEndDate);

          bool isEventInDepartment = (role.contains('MANAGER_DEPARTMENT') && event['departmentId'] == departmentId) ||
              (role.contains('MANAGER_ENTIRE') && event['departmentId'] == 'EN');

          return isEventInDepartment &&
              eventStartDate.isBefore(now) && eventEndDate.isAfter(now);
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: ${response.statusCode}')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoReload() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchEvents();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreEvents();
    }
  }

  void _loadMoreEvents() {
    // Load more events if needed
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
              const SizedBox(height: 20),
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
                            'Điểm danh sự kiện',
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
                      icon: const Icon(Icons.logout, color: Colors.black),
                      onPressed: () async {
                        bool? confirmLogout = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Xác nhận đăng xuất'),
                              content: const Text('Ban có chắc chắn muốn đăng xuất không?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.go('/login');
                                  },
                                  child: const Text('Đăng xuất'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmLogout == true) {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          LoginService().logout(_token!);
                          context.go('/login');
                        }
                      },
                    ),
                  ),
                ],
              ),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchEvents,
                  child: _buildEventList(),
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
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 20),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          hintText: "Tìm kiếm sự kiện...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final filteredEvents = _events
        .where((event) =>
        event['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          'Hiện tại không có sự kiện nào diễn ra',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 18,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(filteredEvents[index], index);
      },
    );
  }

  Widget _buildEventCard(dynamic event, int index) {
    final DateTime adjustedDateStart = DateTime.parse(event['dateStart']).add(const Duration(hours: 7));
    final DateTime adjustedDateEnd = DateTime.parse(event['dateEnd']).add(const Duration(hours: 7));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white.withOpacity(0.9),
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
              const SizedBox(height: 5),
              Text(
                event['departmentId'] == 'EN' ? 'Toàn trường' : 'Khoa: ${event['departmentId']}',
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
              const SizedBox(height: 5),
              Text(
                "Địa điểm: ${event['locationId']}",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          trailing: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 50),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRCodeScanScreen(token: _token!, role: '', eventId: event['eventId'], dateStart: event['dateStart'], dateEnd: event['dateEnd'], name: event['name']),
              ),
            ).then((_) {
              _fetchEvents(); // Reload data when returning from QRCodeScanScreen
            });
          },
        ),
      ),
    );
  }
}