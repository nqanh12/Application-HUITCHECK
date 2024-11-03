import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class QRCodePage extends StatefulWidget {
  final String eventId;
  final String token;
  final String role;
  final String name;
  final String dateStart;
  final String dateEnd;
  final String location;
  const QRCodePage({super.key, required this.eventId, required this.token, required this.role, required this.name, required this.dateStart, required this.dateEnd, required this.location});

  @override
  QRCodePageState createState() => QRCodePageState();
}

class QRCodePageState extends State<QRCodePage> {
  String? _qrCode;

  @override
  void initState() {
    super.initState();
    _fetchQRCode();
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
        setState(() {
          _qrCode = jsonResponse['result']['eventsRegistered'][0]['qrCode'];
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load QR code: ${jsonResponse['code']}')),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load QR code: ${response.statusCode}')),
      );
    }
  }

  String _formatDate(String date) {
    final DateTime parsedDate = DateTime.parse(date).add(const Duration(hours: 7));
    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
    return formatter.format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
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
            "QR Code",
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
        child: Center(
          child: _qrCode == null
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                  padding: const EdgeInsets.all(20),
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
                        // embeddedImage:const AssetImage('assets/logo.png'),
                        // embeddedImageStyle: const QrEmbeddedImageStyle(
                        //   size: Size(150, 150), // Adjust the size of the logo
                        // ),
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
                    ],
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}