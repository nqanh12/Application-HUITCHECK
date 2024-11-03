import 'dart:convert';
import 'package:doan/Component/User/edit_personal_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdatePersonalScreen extends StatefulWidget {
  final String token;
  final String role;
  const UpdatePersonalScreen({super.key, required this.token, required this.role});

  @override
  UpdatePersonalScreenState createState() => UpdatePersonalScreenState();
}

class UpdatePersonalScreenState extends State<UpdatePersonalScreen> {
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    const String url = 'http://10.0.2.2:8080/api/users/myInfo';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['code'] == 1000) {
        setState(() {
          userInfo = jsonResponse['result'];
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user info: ${jsonResponse['code']}')),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user info: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Thông tin cá nhân",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFC5D8EC),
              Color(0xFF1975D7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: userInfo == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/background.png', // replace with your image asset path
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                children: [
                  // Profile avatar and name
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/avatar.png'), // Replace with your avatar image
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userInfo?['full_Name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Information details box
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow("Giới tính", userInfo?['gender'] ?? 'Chưa bổ sung '), // Replace with actual data if available
                          _buildInfoRow("Điện thoại", userInfo?['phone'] ?? 'Chưa bổ sung'),
                          _buildInfoRow("Lớp", userInfo?['class_id'] ?? 'Chưa bổ sung'),
                          _buildInfoRow("Email", userInfo?['email'] ?? 'Chưa bổ sung'),
                          _buildInfoRow("Địa chỉ", userInfo?['address'] ?? 'Chưa bổ sung'),
                          _buildInfoRow("Điểm rèn luyện", userInfo?['training_point'] ?? '0'),
                          const SizedBox(height: 20),
                          // Edit Button
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPersonalInfoScreen(
                                      role: widget.role,
                                      token: widget.token,
                                      fullName: userInfo?['full_Name'] ?? 'Chưa bổ sung',
                                      gender: userInfo?['gender'] ?? 'Chưa bổ sung',
                                      phone: userInfo?['phone'] ?? 'Chưa bổ sung',
                                      classID: userInfo?['class_id'] ?? 'Chưa bổ sung',
                                      email: userInfo?['email'] ?? 'Chưa bổ sung',
                                      address: userInfo?['address'] ?? 'Chưa bổ sung',
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchUserInfo();
                                }
                              },
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              label: const Text(
                                'Chỉnh sửa',
                                style: TextStyle(color: Colors.blue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}