import 'dart:async';
import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:huitcheck/Widget/button_widget.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic>? userInfo;
  List<dynamic> _upcomingEvents = [];
  int _unreadNotificationsCount = 0;
  Timer? _timer;
  late String _token;
  final bool _isLoggedIn = true;
  bool _isHovered = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLoggedIn) {
        _initializeToken();
      }
    });
  }
  void _initializeToken() async {
    await _loadToken();
    _fetchUserInfo();
    _fetchUpcomingEvents();
    _fetchUnreadNotificationsCount();
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
    });
  }

  Future<void> _fetchUserInfo() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/users/myInfo'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (mounted) {
        setState(() {
          userInfo = data['result'];
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user info')),
        );
      }
    }
  }

  Future<void> _fetchUpcomingEvents() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/events/listEvent'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> loadedEvents = data['result'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final departmentId = prefs.getString('departmentId');
      final adjustedEvents = loadedEvents.map((event) {
        event['dateStart'] = DateTime.parse(event['dateStart']).toIso8601String();
        event['dateEnd'] = DateTime.parse(event['dateEnd']).toIso8601String();
        return event;
      }).where((event) {
        final dateStart = DateTime.parse(event['dateStart']);
        return dateStart.isAfter(DateTime.now()) &&
            (event['departmentId'] == 'EN' || event['departmentId'] == departmentId);
      }).toList();

      if (mounted) {
        setState(() {
          _upcomingEvents = adjustedEvents;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: ${response.statusCode}')),
        );
      }
    }
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/users/countUnreadNotifications'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = data['result']['quantity'];
        });
      }
    } else {
      Logger().e('Failed to load unread notifications count: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          Center(
            child: SizedBox(
              width: 700, // Set the fixed width here
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                userInfo?['full_Name'] ?? 'Loading...',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 25, 25, 25),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const CircleAvatar(
                                backgroundImage: AssetImage('assets/avatar.png'),
                                radius: 25,
                                backgroundColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Sự kiện sắp tới",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _upcomingEvents.length,
                                        itemBuilder: (context, index) {
                                          final event = _upcomingEvents[index];
                                          return _buildEventCard(
                                            event,
                                            event['name'] ?? 'Chưa cập nhật',
                                            event['dateStart'] ?? 'Chưa cập nhật',
                                            event['dateEnd'] ?? 'Chưa cập nhật',
                                            event['locationId'] ?? 'Chưa cập nhật',
                                            event['description'] ?? 'Chưa cập nhật',
                                            event['checkInStatus'] ?? false,
                                            event['checkOutStatus'] ?? false,
                                            event['managerName'] ?? 'Chưa cập nhật',
                                            event['isRegistered'] ?? false,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        QuickAccessButton(
                                          label: "Sự kiện",
                                          icon: Icons.event,
                                          route: "/eventlist",
                                          iconColor: Colors.black,
                                        ),
                                        const SizedBox(height: 10),
                                        QuickAccessButton(
                                          label: _unreadNotificationsCount > 0 ? "Thông báo" : "Thông báo",
                                          icon: _unreadNotificationsCount > 0 ? Icons.notifications_active : Icons.notifications,
                                          route: "/notifications",
                                          iconColor: _unreadNotificationsCount > 0 ? Colors.red : Colors.black,
                                        ),
                                        const SizedBox(height: 10),
                                        QuickAccessButton(
                                          label: "Lịch sử",
                                          icon: Icons.history,
                                          route: "/history",
                                          iconColor: Colors.black,
                                        ),
                                        const SizedBox(height: 10),
                                        QuickAccessButton(
                                          label: "Phản hồi",
                                          icon: Icons.feedback,
                                          route: "/feedback",
                                          iconColor: Colors.black,
                                        ),
                                        const SizedBox(height: 10),
                                        QuickAccessButton(
                                          label: "Cài đặt",
                                          icon: Icons.settings,
                                          route: "/setting",
                                          iconColor: Colors.black,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic event, String title, String dateStart, String dateEnd, String location, String description, bool checkInStatus, bool checkOutStatus, String managerId, bool isRegistered) {
    final DateFormat dateFormat = DateFormat('dd-MM-yyyy - HH:mm'); // Define the date format

    final adjustedDateStart = DateTime.parse(dateStart).add(const Duration(hours: 7));
    final adjustedDateEnd = DateTime.parse(dateEnd).add(const Duration(hours: 7));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    "Bắt đầu: ${dateFormat.format(adjustedDateStart)}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    "Kết thúc: ${dateFormat.format(adjustedDateEnd)}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      "Địa điểm: $location",
                      style: const TextStyle(color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.manage_accounts, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      "Chủ trì: $managerId",
                      style: const TextStyle(color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/eventdetails/${event['eventId']}');
                  },
                  style: ButtonStyle(
                    side: MaterialStateProperty.resolveWith<BorderSide>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered)) {
                          return const BorderSide(color: Colors.blueAccent, width: 2);
                        }
                        return const BorderSide(color: Colors.black54, width: 1);
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Colors.blueAccent;
                        }
                        return Colors.black54;
                      },
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Colors.blue.withOpacity(0.1);
                        }
                        return Colors.transparent;
                      },
                    ),
                  ),
                  child: const Text("Xem chi tiết"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}