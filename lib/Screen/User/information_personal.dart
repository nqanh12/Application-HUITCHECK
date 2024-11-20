import 'dart:convert';
import 'package:huitcheck/API/constants.dart';
import 'package:huitcheck/Class/training_point.dart';
import 'package:huitcheck/Screen/User/edit_personal_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:huitcheck/Class/users.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePersonalScreen extends StatefulWidget {
  const UpdatePersonalScreen({super.key});

  @override
  UpdatePersonalScreenState createState() => UpdatePersonalScreenState();
}

class UpdatePersonalScreenState extends State<UpdatePersonalScreen> {
  Users? userInfo;
  String? token;
  String? role;

  @override
  void initState() {
    super.initState();
    _loadTokenAndRole();
  }

  Future<void> _loadTokenAndRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      role = prefs.getString('role');
    });
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    if (token == null) return;

    const String url = '${baseUrl}api/users/myInfo';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['code'] == 1000) {
        setState(() {
          userInfo = Users.fromJson(jsonResponse['result']);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user info: ${jsonResponse['code']}')),
        );
      }
    } else {
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
            Positioned.fill(
              child: Image.asset(
                'assets/background.png',
                fit: BoxFit.cover,
              ),
            ),
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/avatar.png'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userInfo?.fullName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 700,
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
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow("Mã sinh viên", userInfo?.userName ?? 'Chưa bổ sung '),
                                const Divider(color: Colors.grey),
                                _buildInfoRow("Khoa", userInfo?.departmentId ?? 'Chưa bổ sung '),
                                const Divider(color: Colors.grey),
                                _buildInfoRow("Giới tính", userInfo?.gender ?? 'Chưa bổ sung '),
                                const Divider(color: Colors.grey),
                                _buildInfoRow("Điện thoại", userInfo?.phone ?? 'Chưa bổ sung'),
                                const Divider(color: Colors.grey),
                                _buildInfoRow("Lớp", userInfo?.classId ?? 'Chưa bổ sung'),
                                const Divider(color: Colors.grey),
                                _buildInfoRow("Email", userInfo?.email ?? 'Chưa bổ sung'),
                                const Divider(color: Colors.grey),
                                _buildInfoRow("Địa chỉ", userInfo?.address ?? 'Chưa bổ sung'),
                                const Divider(color: Colors.grey),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildInfoRow("Điểm rèn luyện", userInfo?.trainingPoint.isNotEmpty == true ? '' : 'Chưa bổ sung'),
                                ),
                                if (userInfo?.trainingPoint.isNotEmpty == true)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _buildTrainingPoints(userInfo!.trainingPoint),
                                  ),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditPersonalInfoScreen(
                                            role: role ?? 'Chưa bổ sung',
                                            token: token ?? '',
                                            fullName: userInfo?.fullName ?? 'Chưa bổ sung',
                                            gender: (userInfo?.gender == null || userInfo!.gender.isEmpty) ? 'Nam' : userInfo!.gender,
                                            phone: userInfo?.phone ?? 'Chưa bổ sung',
                                            classID: userInfo?.classId ?? 'Chưa bổ sung',
                                            email: userInfo?.email ?? 'Chưa bổ sung',
                                            address: userInfo?.address ?? 'Chưa bổ sung',
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
                                      maximumSize: const Size(double.infinity, 50),
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
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

  Widget _buildTrainingPoints(List<TrainingPoint> trainingPoints) {
    return Align(
      alignment: Alignment.topRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trainingPoints.map((tp) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 1:   ${tp.semesterOne}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 2:   ${tp.semesterTwo}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 3:   ${tp.semesterThree}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 4:   ${tp.semesterFour}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 5:   ${tp.semesterFive}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 6:   ${tp.semesterSix}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 7:   ${tp.semesterSeven}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text("Học kỳ 8:   ${tp.semesterEight}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
                const Divider(color: Colors.black54),
              ],
            ),
          );
        }).toList(),
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