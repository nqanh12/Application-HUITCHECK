import 'package:huitcheck/Component/Home/login.dart';
// import 'package:doan/Component/User/language_setting.dart';
import 'package:huitcheck/Component/User/notification_setting.dart';
import 'package:huitcheck/Component/User/information_personal.dart';
import 'package:flutter/material.dart';
import 'package:huitcheck/Component/User/change_password.dart';

class SettingsScreen extends StatelessWidget {
  final String token;
  final String role;
  const SettingsScreen({super.key, required this.token, required this.role});

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
            "Cài đặt",
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
          padding: const EdgeInsets.only(top: 80.0), // Adjust padding for AppBar
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSettingsOption(
                  context,
                  "Thay đổi mật khẩu",
                  Icons.lock,
                   ChangePasswordScreen(token : token)
              ),
              const SizedBox(height: 20),
              _buildSettingsOption(
                  context,
                  "Cập nhật thông tin cá nhân",
                  Icons.person,
                  UpdatePersonalScreen(token: token, role: role)
              ),
              // const SizedBox(height: 20),
              // _buildSettingsOption(
              //     context,
              //     "Cài đặt ngôn ngữ",
              //     Icons.language,
              //     const LanguageSettingsScreen()
              // ),
              const SizedBox(height: 20),
              _buildSettingsOption(
                  context,
                  "Cài đặt thông báo",
                  Icons.notifications,
                  const NotificationSettingsScreen()
              ),
              const SizedBox(height: 20),
              _buildSettingsOption(
                  context,
                  "Đăng xuất",
                  Icons.logout,
                  const Login()
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context, String title, IconData icon, Widget screen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 25, 117, 215), size: 30),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black87, size: 20),
        onTap: () {
          if (title == "Đăng xuất") {
            _showLogoutDialog(context, screen);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, Widget screen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Xác nhận đăng xuất",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Không",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                ); // Navigate to the login screen
              },
              child: const Text(
                "Có",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}
