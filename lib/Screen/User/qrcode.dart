import 'dart:async';
import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRCodePage extends StatefulWidget {
  final String eventId;
  final String token;
  final String name;
  final String dateStart;
  final String dateEnd;
  final String location;
  const QRCodePage({super.key, required this.eventId, required this.token, required this.name, required this.dateStart, required this.dateEnd, required this.location});

  @override
  QRCodePageState createState() => QRCodePageState();
}

class QRCodePageState extends State<QRCodePage> {
  String? _qrCode;
  bool _checkInStatus = false;
  bool _checkOutStatus = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startFetchingStatus();
  }

  void _startFetchingStatus() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) {
        timer.cancel();
      } else {
        _fetchCheckInCheckOutStatus();
        _fetchQRCode();
      }
    });
  }

  Future<void> _fetchQRCode() async {
    final String url = '${baseUrl}api/users/getQRCode/${widget.eventId}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['code'] == 1000) {
        if (mounted) {
          setState(() {
            _qrCode = jsonResponse['result']['eventsRegistered'][0]['qrCode'];
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load QR code: ${jsonResponse['code']}')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load QR code: ${response.statusCode}')),
        );
      }
    }
  }

  Future<void> _fetchCheckInCheckOutStatus() async {
    final String url = '${baseUrl}api/users/getCheckInCheckOutStatus/${widget.eventId}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['code'] == 1000) {
        final event = data['result']['eventsRegistered'].firstWhere(
              (event) => event['eventId'] == widget.eventId,
          orElse: () => null,
        );
        if (event != null) {
          if (mounted) {
            setState(() {
              _checkInStatus = event['checkInStatus'];
              _checkOutStatus = event['checkOutStatus'];
            });
          }
        }
      } else {
        throw Exception('Failed to load check-in/check-out status: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load check-in/check-out status: ${response.statusCode}');
    }
  }

  String _formatDate(String date) {
    final DateTime parsedDate = DateTime.parse(date).add(const Duration(hours: 7));
    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
    return formatter.format(parsedDate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
            "QR Code",
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
          child: _qrCode == null
              ? const CircularProgressIndicator()
              : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500,maxHeight: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 50),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: _qrCode!,
                          version: QrVersions.auto,
                          size: 350.0,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Bắt đầu : ${_formatDate(widget.dateStart)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Kết thúc : ${_formatDate(widget.dateEnd)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}