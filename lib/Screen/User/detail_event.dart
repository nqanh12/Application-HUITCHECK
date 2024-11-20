import 'dart:async';
import 'package:huitcheck/API/constants.dart';
import 'package:huitcheck/Screen/User/qrcode.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:huitcheck/Class/events.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  EventDetailsScreenState createState() => EventDetailsScreenState();
}

class EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistered = false;
  bool _checkInStatus = false;
  bool _checkOutStatus = false;
  Timer? _timer;
  bool _isDescriptionExpanded = false;
  Event? _event;
  String? _token;
  String _departmentName = '';
  Map<String, dynamic>? userInfo;
  final Map<String, String> _courseNames = {};

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
    _fetchEventDetails();
    _checkRegistrationStatus();
    _startAutoReload();
  }

  void _startAutoReload() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchEventDetails();
      _fetchCheckInCheckOutStatus();
    });
  }
  Future<void> _fetchCheckInCheckOutStatus() async {
    if (_token == null) return;

    final response = await http.get(
      Uri.parse('${baseUrl}api/users/getCheckInCheckOutStatus/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['code'] == 1000) {
        final event = data['result']['eventsRegistered'].firstWhere(
              (event) => event['eventId'] == widget.eventId,
          orElse: () => null,
        );
        if (event != null && mounted) {
          setState(() {
            _checkInStatus = event['checkInStatus'];
            _checkOutStatus = event['checkOutStatus'];
          });
        }
      } else {
        throw Exception('Failed to load check-in/check-out status: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load check-in/check-out status: ${response.statusCode}');
    }
  }
  Future<void> _fetchEventDetails() async {
    if (_token == null) return;

    final response = await http.get(
      Uri.parse('${baseUrl}api/events/getInfo/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['code'] == 1000) {
        setState(() {
          _event = Event.fromJson(data['result']);
        });
        _fetchDepartmentName(_event!.departmentId);
        _fetchCourseNames(_event!.courses.map((course) => course.courseId).toList());
      } else {
        throw Exception('Failed to load event details: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load event details: ${response.statusCode}');
    }
  }

  Future<void> _checkRegistrationStatus() async {
    if (_token == null) return;

    final response = await http.post(
      Uri.parse('${baseUrl}api/users/checkRegistered/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['code'] == 1000) {
        setState(() {
          _isRegistered = data['result'];
        });
      } else {
        throw Exception('Failed to check registration status: ${data['message']}');
      }
    } else {
      throw Exception('Failed to check registration status: ${response.statusCode}');
    }
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

  Future<void> _fetchDepartmentName(String departmentId) async {
    if (_token == null) return;
    final String url = '${baseUrl}api/department/getDepartmentName/$departmentId';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _departmentName = result['result'];
      });
    } else {
      setState(() {
        _departmentName = 'Unknown';
      });
    }
  }

  Future<void> _fetchCourseNames(List<String> courseIds) async {
    if (_token == null) return;

    for (String courseId in courseIds) {
      setState(() {
        if (courseId == 'K0') {
          _courseNames[courseId] = 'Toàn khóa';
        } else if (courseId == 'K1') {
          _courseNames[courseId] = 'K';
        } else if (courseId == 'K2') {
          _courseNames[courseId] = 'K2';
        } else {
          _courseNames[courseId] = 'K${courseId.substring(1)}';
        }
      });
    }
  }

  Future<void> _cancelRegistration() async {
    if (_token == null) return;

    final userResponse = await http.delete(
      Uri.parse('${baseUrl}api/users/deleteRegisteredEvent/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    final eventResponse = await http.delete(
      Uri.parse('${baseUrl}api/events/deleteParticipant/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (userResponse.statusCode == 200 && eventResponse.statusCode == 200) {
      setState(() {
        _isRegistered = false;
        _checkInStatus = false;
        _checkOutStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hủy đăng ký thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hủy đăng ký thất bại')),
      );
    }
  }

  Future<void> _registerEvent() async {
    if (_token == null) return;

    // Fetch user info to get class_id
    await _fetchUserInfo();

    // Check if class_id matches any courseId of the event or if courseId is K0
    if (userInfo != null && userInfo!['classId'] != null) {
      String classId = userInfo!['classId'];
      bool isCourseIdMatched = _event!.courses.any((course) =>
      classId.substring(0, 2) == course.courseId.substring(1) || course.courseId == 'K0'
      );

      if (!isCourseIdMatched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn không có quyền đăng ký sự kiện này')),
        );
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch user class ID')),
      );
      return;
    }

    final userResponse = await http.post(
      Uri.parse('${baseUrl}api/users/registerEvent/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    final eventResponse = await http.post(
      Uri.parse('${baseUrl}api/events/addParticipant/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (userResponse.statusCode == 200 && eventResponse.statusCode == 200) {
      setState(() {
        _isRegistered = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thất bại')),
      );
    }
  }

  Future<void> _refreshData() async {
    await _fetchEventDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final bool isFull = _event!.currentParticipants >= _event!.capacity;
    final DateTime now = DateTime.now();
    final DateTime eventStart = _event!.dateStart;
    final bool isEventStarted = now.isAfter(eventStart);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          onPressed: () {
            context.go('/eventlist');
          },
        ),
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          child: Text(
            "Chi tiết",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.height * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
      ),
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          child: Container(
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
                child: Center(
                  child: SizedBox(
                    width: 700,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _event!.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Ngày bắt đầu: ${_formatDateTime(_event!.dateStart.toIso8601String())}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Ngày kết thúc: ${_formatDateTime(_event!.dateEnd.toIso8601String())}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.departure_board,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Dành cho: ${_event!.courses.map((course) => _courseNames[course.courseId] ?? 'Loading...').join(', ')}",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _departmentName,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Sức chứa: ${_event!.capacity}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Tổng số người đăng ký: ${_event!.currentParticipants}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Địa điểm: ${_event!.locationId}',
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
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Mô tả",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _event!.description,
                                  maxLines: _isDescriptionExpanded ? null : 1,
                                  overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isDescriptionExpanded = !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Text(
                                    _isDescriptionExpanded ? "Thu gọn" : "Xem thêm",
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Chủ trì: ${_event!.managerName}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      _checkInStatus ? Icons.check_circle_outline : Icons.cancel_outlined,
                                      color: _checkInStatus ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _checkInStatus ? "Đã check-in" : "Chưa check-in",
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      _checkOutStatus ? Icons.check_circle_outline : Icons.cancel_outlined,
                                      color: _checkOutStatus ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _checkOutStatus ? "Đã check-out" : "Chưa check-out",
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!isFull && !isEventStarted)
                              ElevatedButton(
                                onPressed: _isRegistered ? null : () {
                                  _showRegisterDialog(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRegistered ? Colors.grey : Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  "Đăng ký",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            if (!isEventStarted)
                              ElevatedButton(
                                onPressed: _isRegistered ? () {
                                  _showCancelDialog(context);
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRegistered ? Colors.red : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  "Huỷ đăng ký",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ElevatedButton(
                              onPressed: _isRegistered ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QRCodePage(name: _event!.name, eventId: widget.eventId, token: _token!, dateStart: _event!.dateStart.toIso8601String(), dateEnd: _event!.dateEnd.toIso8601String(), location: _event!.locationId),
                                  ),
                                );
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRegistered ? Colors.blue : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: const Text(
                                "Lấy mã QR",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        ),
      ),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận đăng ký"),
          content: const Text("Bạn có muốn đăng ký sự kiện này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registerEvent();
              },
              child: const Text("Đồng ý"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Hủy"),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Xác nhận hủy đăng ký",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            "Bạn có muốn hủy đăng ký sự kiện này không?",
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelRegistration();
              },
              child: const Text(
                "Đồng ý",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Hủy",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
String _formatDateTime(String dateTime) {
  final DateTime parsedDate = DateTime.parse(dateTime).add(const Duration(hours: 7));
  final DateFormat formatter = DateFormat('dd/MM/yyyy - HH:mm');
  return formatter.format(parsedDate);
}