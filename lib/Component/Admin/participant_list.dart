import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class Student {
  final String eventId; // user_id
  final String userName;
  final bool isConfirmed;
  final bool checkInStatus; // Trạng thái check-in
  final DateTime? checkInTime; // Thời gian check-in
  final bool checkOutStatus; // Trạng thái check-out
  final DateTime? checkOutTime; // Thời gian check-out
  final String? userCheckIn; // Người check-in
  final String? userCheckOut; // Người check-out
  String fullName;
  String className;
  bool isSelected;

  Student({
    required this.eventId,
    required this.userName,
    required this.isConfirmed,
    required this.checkInStatus,
    required this.checkInTime,
    required this.checkOutStatus,
    required this.checkOutTime,
    this.userCheckIn,
    this.userCheckOut,
    this.fullName = '',
    this.className = '',
    this.isSelected = false,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      eventId: json['eventId'] ?? '',
      userName: json['userName'] ?? '',
      isConfirmed: json['confirmed'] ?? false,
      checkInStatus: json['checkInStatus'] ?? false,
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutStatus: json['checkOutStatus'] ?? false,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      userCheckIn: json['userCheckIn'],
      userCheckOut: json['userCheckOut'],
      className: json['class_id'] ?? 'Chưa cập nhật',
      fullName: json['full_Name'] ?? 'Chưa cập nhật',
      isSelected: json['isSelected'] ?? false,
    );
  }
}

class ParticipantListScreen extends StatefulWidget {
  final String eventId;
  final String token;
  final String role;
  final DateTime dateEnd;

  const ParticipantListScreen({super.key, required this.eventId, required this.token, required this.role, required this.dateEnd});

  @override
  ParticipantListScreenState createState() => ParticipantListScreenState();
}

class ParticipantListScreenState extends State<ParticipantListScreen> {
  List<Student> participants = [];
  String filter = 'Tất cả';
  bool isAllSelected = false;
  final Logger _logger = Logger();
  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchFullName(String userName) async {
    final String url = '${baseUrl}api/users/getFullName/$userName';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final String fullName = data['result']['full_Name'];
      final String className = data['result']['class_id'];
      setState(() {
        for (var participant in participants) {
          if (participant.userName == userName) {
            participant.fullName = fullName; // Update fullName field
            participant.className = className; // Update className field
            break;
          }
        }
      });
    } else {
      // Handle error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load full name for $userName: ${response.statusCode}')),
      );
    }
  }

  // Fetch participants of the event
  Future<void> _fetchParticipants() async {
    final String url = '${baseUrl}api/events/participants/${widget.eventId}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<Student> loadedParticipants = (data['result']['participants'] as List)
          .map((participantJson) => Student.fromJson(participantJson))
          .toList();

      setState(() {
        participants = loadedParticipants;
      });

      for (var participant in participants) {
        _fetchFullName(participant.userName);
      }
    } else {
      // Handle error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load participants: ${response.statusCode}')),
      );
    }
  }

  Future<void> _confirmPointsForSelectedParticipants() async {
    for (var participant in participants) {
      if (participant.isSelected) {
        final String eventUrl = '${baseUrl}api/events/confirmPoint/${widget.eventId}/${participant.userName}';
        final String userUrl = '${baseUrl}api/users/confirmPointbyAdmin/${widget.eventId}/${participant.userName}';

        await http.put(
          Uri.parse(eventUrl),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        await http.put(
          Uri.parse(userUrl),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
          },
        );
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận thành công')),
        );
        _fetchParticipants();
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn sinh viên cần xác nhận điểm danh')),
        );
      }
    }

  }

  Future<void> _deleteParticipant(String eventId, String userName) async {
    final String url1 = '${baseUrl}api/users/deleteEventRegistered/$eventId/$userName';
    final String url2 = '${baseUrl}api/events/deleteParticipantByAdmin/$eventId/$userName';

    final response1 = await http.delete(
      Uri.parse(url1),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    final response2 = await http.delete(
      Uri.parse(url2),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response1.statusCode == 200 && response2.statusCode == 200) {
      _logger.i('Deleted participant $userName from event $eventId');
      _fetchParticipants(); // Reload participants after deletion
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete participant $userName from event $eventId')),
      );
    }
  }

  String _getRegistrationStatus(Student student) {
    if (student.checkInStatus && student.checkOutStatus) {
      return "Đã hoàn thành";
    } else if (student.checkInStatus || student.checkOutStatus) {
      return "Đang xử lý";
    } else {
      return "Cảnh báo";
    }
  }

  Color _getStatusColor(Student student) {
    if (student.checkInStatus && student.checkOutStatus) {
      return Colors.green; // Màu xanh lá khi hoàn thành
    } else if (student.checkInStatus || student.checkOutStatus) {
      return Colors.orange; // Màu cam khi đang xử lý
    } else {
      return Colors.red; // Màu đỏ khi cảnh báo
    }
  }

  Map<String, int> _countParticipants() {
    int completed = 0;
    int notCompleted = 0;

    for (var student in participants) {
      if (student.checkInStatus && student.checkOutStatus) {
        completed++;
      } else {
        notCompleted++;
      }
    }

    return {
      'completed': completed,
      'notCompleted': notCompleted,
    };
  }

  List<Student> _filterParticipants() {
    if (filter == 'Tất cả') {
      return participants;
    } else if (filter == 'Hoàn thành') {
      return participants.where((student) => student.checkInStatus && student.checkOutStatus).toList();
    } else {
      return participants.where((student) => !student.checkInStatus || !student.checkOutStatus).toList();
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      for (var participant in participants) {
        participant.isSelected = isAllSelected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countParticipants();
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
    final filteredParticipants = _filterParticipants();

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
            "Danh sách sinh viên",
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Set the background color to white
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0), // Optional: Add padding inside the container
                  child:Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assessment, color: Colors.blue, size: 40), // Add an icon
                          const SizedBox(width: 10), // Add some space between the icon and text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoàn thành: ${counts['completed']}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20), // Add some space between the texts
                              Text(
                                'Chưa hoàn thành: ${counts['notCompleted']}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButton<String>(
                                value: filter,
                                elevation: 16,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    filter = newValue!;
                                  });
                                },
                                items: <String>['Tất cả', 'Hoàn thành', 'Chưa hoàn thành']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              Row(
                                children: [
                                  Checkbox(value: isAllSelected, onChanged: _toggleSelectAll),
                                  const Text('Chọn tất cả'),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _confirmPointsForSelectedParticipants,
                        style: ElevatedButton.styleFrom(
                          elevation: 10,
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Duyệt điểm danh'),
                      ),
                    ],
                  )
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchParticipants, // Pull-to-refresh functionality
                child: filteredParticipants.isEmpty
                    ? const Center(
                  child: Text(
                    'Chưa có sinh viên đăng ký',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredParticipants.length,
                  itemBuilder: (context, index) {
                    var student = filteredParticipants[index];
                    return Dismissible(
                        key: Key(student.userName),
                        background: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Xác nhận xoá sinh viên này'),
                                content: Text('Bạn có chắn chắn muốn xóa  ${student.fullName}?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false); // Close the dialog
                                    },
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true); // Confirm deletion
                                    },
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          // Remove the participant from the list
                          _deleteParticipant(widget.eventId, student.userName);

                          // Optionally, show a snackbar to notify about the deletion
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${student.fullName} đã bị xoá khỏi danh sách')),
                          );
                        },
                        child: Card(
                          elevation: 10,
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: ListTile(
                            leading: student.isConfirmed
                                ? const SizedBox.shrink() // Hide the checkbox if isConfirmed is true
                                : Checkbox(
                              value: student.isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  student.isSelected = value ?? false;
                                });
                              },
                            ),
                            title: Text(student.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Check-in:   ',style: TextStyle(fontSize: 12)),
                                    student.checkInStatus
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.cancel_presentation, color: Colors.red),
                                  ],
                                ),
                                Text('Giờ vào: ${student.checkInTime != null ? dateFormat.format(student.checkInTime!) : 'N/A'}',style: const TextStyle(fontSize: 12)),
                                Text('Người check in: ${student.userCheckIn ?? 'Chưa điểm danh'}',style: const TextStyle(fontSize: 12)),
                                Row(
                                  children: [
                                    const Text('Check-out: ',style: TextStyle(fontSize: 12)),
                                    student.checkOutStatus
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.cancel_presentation, color: Colors.red),
                                  ],
                                ),
                                Text('Giờ ra: ${student.checkOutTime != null ? dateFormat.format(student.checkOutTime!) : 'N/A'}',style: const TextStyle(fontSize: 12)),
                                Text('Người check out: ${student.userCheckOut ?? 'Chưa điểm danh'}',style: const TextStyle(fontSize: 12)),
                                Text('MSSV: ${student.userName}',style: const TextStyle(fontSize: 12)),
                                Text('Lớp: ${student.className}',style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing:
                            Text(
                              _getRegistrationStatus(student),
                              style: TextStyle(
                                color: _getStatusColor(student),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              // Optional: Handle tap to view student details
                            },
                          ),
                        )
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}