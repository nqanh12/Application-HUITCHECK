import 'package:huitcheck/Component/Admin/account_management.dart';
import 'package:huitcheck/Component/Admin/event_list_management.dart';
import 'package:huitcheck/Component/Admin/event_management.dart';
import 'package:huitcheck/Component/Home/login.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String role;
  final String token;
  const AdminDashboardScreen({super.key, required this.role, required this.token});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0; // Track the selected tab

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      UserManagementScreen(role: widget.role, token: widget.token), // Manage Users
      EventManagementScreen(role: widget.role, token: widget.token), // Manage Events
      EventListManagementScreen(role: widget.role, token: widget.token), // Manage Participants
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove the default back button
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00, // Điều chỉnh padding tiêu đề theo chiều cao màn hình
          ),
          child: Text(
            "Quản trị",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.06, // Điều chỉnh kích thước font theo tỷ lệ màn hình
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        leading: IconButton(
          icon: const Icon(Icons.logout_sharp, color: Colors.white),
          onPressed: () {
            _showLogoutDialog(context, const Login()); // Replace with your login screen
          },
      ),
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
        child: widgetOptions[_selectedIndex], // Display the selected screen
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Sự kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Danh Sách',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures the bar does not shift
        backgroundColor: Colors.white,
      ),
    );
  }
}