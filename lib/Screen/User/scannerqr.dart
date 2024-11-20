import 'package:huitcheck/API/constants.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huitcheck/Screen/User/student_list_event.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRCodeScanScreen extends StatefulWidget {
  final String role;
  final String token;
  final String eventId;
  final String dateStart;
  final String dateEnd;
  final String name;
  const QRCodeScanScreen({super.key, required this.name, required this.role, required this.token, required this.eventId, required this.dateStart, required this.dateEnd});

  @override
  QRCodeScanScreenState createState() => QRCodeScanScreenState();
}

class QRCodeScanScreenState extends State<QRCodeScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? studentInfo;
  String? checkStatus;
  bool isCheckIn = true;
  List<dynamic> participants = [];
  final Logger _logger = Logger();
  @override
  void initState() {
    super.initState();
    requestCameraPermission(); // Request camera permission
    _fetchParticipants(); // Fetch participants list
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future<void> _fetchParticipants() async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/events/participants/${widget.eventId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        participants = data['result']['participants'];
      });
    } else {
      // Handle error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load participants: ${response.statusCode}')),
      );
    }
  }

  Future<void> _fetchFullNameAndClass(String userName) async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/users/getFullName/$userName'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['code'] == 1000) {
        final fullName = data['result']['full_Name'];
        final className = data['result']['class_id'];
        setState(() {
          studentInfo = 'MSSV: $userName\nHọ và tên: $fullName\nLớp: $className\n$checkStatus';
        });
      } else {
        setState(() {
          studentInfo = 'Failed to load full name and class for $userName';
        });
      }
    } else {
      setState(() {
        studentInfo = 'Failed to load full name and class for $userName: ${response.statusCode}';
      });
    }
  }

  Future<void> _checkInOut(String userName) async {
    final DateTime eventStartTime = DateTime.parse(widget.dateStart);
    final DateTime currentTime = DateTime.now();

    if (isCheckIn && currentTime.isAfter(eventStartTime.add(const Duration(hours: 1)))) {
      setState(() {
        checkStatus = 'Điểm danh vào không thành công\nQuá thời gian cho phép';
      });
      await _fetchFullNameAndClass(userName);
      return;
    }

    final String checkInOut = isCheckIn ? 'checkIn' : 'checkOut';
    final String userUrl = '${baseUrl}api/users/$checkInOut/${widget.eventId}/$userName';
    final String eventUrl = '${baseUrl}api/events/$checkInOut/${widget.eventId}/$userName';

    final userResponse = await http.put(
      Uri.parse(userUrl),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    final eventResponse = await http.put(
      Uri.parse(eventUrl),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (userResponse.statusCode == 200 && eventResponse.statusCode == 200) {
      json.decode(userResponse.body);
      setState(() {
        checkStatus = isCheckIn ? 'Điểm danh vào thành công' : 'Điểm danh ra thành công';
      });
      await _fetchFullNameAndClass(userName);
    } else {
      _logger.e('Failed to check in/out: ${userResponse.statusCode} - ${eventResponse.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double aspectRatio = screenWidth / screenHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[

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
          // QR Scanner section
          Positioned(
            top: MediaQuery.of(context).size.height * 0.0, // Adjust top position based on screen height
            left: MediaQuery.of(context).size.width * 0.00, // Adjust left position based on screen width
            right: MediaQuery.of(context).size.width * 0.00, // Adjust right position based on screen width
            bottom: MediaQuery.of(context).size.height * 0.0, // Adjust bottom position based on screen height
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5, // Set height to 50% of screen height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio, // Use dynamic aspect ratio
                child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    cameraFacing: CameraFacing.front, // Use front camera
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.white,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: screenWidth * 0.7, // Adjust cutout size based on screen width
                      cutOutBottomOffset: 100.0, // Adjust the bottom offset as needed
                    )
                ),
              ),
            ),
          ),
          Positioned(
            top: 30, // Adjust the top position as needed
            left: 20, // Adjust the left position as needed
            right: 20, // Adjust the right position as needed
            child: Stack(
              children: [
                Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'Danh sách sự kiện',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back , color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.00,
            right: MediaQuery.of(context).size.width * 0.00,
            bottom: MediaQuery.of(context).size.height * 0.10,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (studentInfo != null)
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Thông tin sinh viên đã quét',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    studentInfo ?? 'Chưa có thông tin',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (checkStatus != null)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getStatusIcon(checkStatus!),
                                          color: _getStatusColor(checkStatus!),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Refined Check-In / Check-Out switch at the top-right corner
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Switch(
                    value: isCheckIn,
                    onChanged: (value) {
                      setState(() {
                        isCheckIn = value;
                      });
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                  Text(
                    isCheckIn ? 'Check In' : 'Check Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCheckIn ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EventParticipantsScreen(token: widget.token, eventId: widget.eventId)),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Xem danh sách'),
              style: ElevatedButton.styleFrom(
                elevation: 10,
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                foregroundColor: const Color.fromARGB(255, 0, 92, 250),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null) {
        final String scannedCode = scanData.code!;
        final String eventCode = widget.eventId; // Assuming eventId is the event QR code

        if (scannedCode.substring(0, 9) == eventCode) {
          final studentId = scannedCode.substring(9); // Remaining characters
          final participant = participants.firstWhere(
                (participant) => participant['userName'] == studentId,
            orElse: () => null,
          );

          if (participant != null) {
            if (isCheckIn) {
              if (participant['checkInStatus'] == true) {
                setState(() {
                  checkStatus = 'Đã điểm danh vào';
                });
                await _fetchFullNameAndClass(studentId);
              } else {
                await _checkInOut(studentId);
                await _fetchFullNameAndClass(studentId);
              }
            } else {
              if (participant['checkOutStatus'] == true) {
                setState(() {
                  checkStatus = 'Đã điểm danh ra';
                });
                await _fetchFullNameAndClass(studentId);
              } else {
                await _checkInOut(studentId);
                await _fetchFullNameAndClass(studentId);
              }
            }
          } else {
            setState(() {
              studentInfo = 'Sinh viên chưa đăng kí';
              checkStatus = null;
            });
          }
        } else {
          setState(() {
            studentInfo = 'Không tìm thấy sinh viên';
            checkStatus = null;
          });
        }
      } else {
        setState(() {
          studentInfo = 'No QR code data';
          checkStatus = null;
        });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Điểm danh vào thành công':
      case 'Điểm danh ra thành công':
        return Icons.check_circle_outline;
      case 'Đã điểm danh vào':
      case 'Đã điểm danh ra':
      case 'Không tìm thấy sinh viên':
      case 'Điểm danh vào không thành công\nQuá thời gian cho phép':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Điểm danh vào thành công':
      case 'Điểm danh ra thành công':
        return Colors.green;
      case 'Đã điểm danh vào':
      case 'Đã điểm danh ra':
      case 'Không tìm thấy sinh viên':
      case 'Điểm danh vào không thành công\nQuá thời gian cho phép':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}