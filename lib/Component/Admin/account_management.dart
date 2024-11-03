import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class User {
  String userName;
  String? password;
  String? fullName;
  String? classId;
  int? trainingPoint;
  String? email;
  String? phone;
  String? address;
  Set<String> roles;

  User({
    required this.userName,
    this.password,
    this.fullName,
    this.classId,
    this.trainingPoint,
    this.email,
    this.phone,
    this.address,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userName: json['userName'],
      fullName: json['full_Name'],
      classId: json['class_id'],
      trainingPoint: json['training_point'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      roles: json['roles'] != null ? Set<String>.from(json['roles']) : {},
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  final String role;
  final String token;
  const UserManagementScreen({super.key, required this.role, required this.token});

  @override
  UserManagementScreenState createState() => UserManagementScreenState();
}

class UserManagementScreenState extends State<UserManagementScreen> {
  List<User> users = [];
  List<User> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _updateUserRole(String userName, String newRole) async {
    final String url = '${baseUrl}api/users/updateRole/$userName';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'roles': [newRole]}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['code'] == 1000) {
        setState(() {
          final updatedUser = User.fromJson(jsonResponse['result']);
          final index = users.indexWhere((user) => user.userName == userName);
          if (index != -1) {
            users[index] = updatedUser;
            filteredUsers = users;
          }
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi quyền thành công')),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user role: ${jsonResponse['code']}')),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: ${response.statusCode}')),
      );
    }
  }

  Future<void> _fetchUsers() async {
    const String url = '${baseUrl}api/users/listUsers';
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
          users = (jsonResponse['result'] as List)
              .map((data) => User.fromJson(data))
              .toList();
          filteredUsers = users;
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: ${jsonResponse['code']}')),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: ${response.statusCode}')),
      );
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final lowerCaseQuery = query.toLowerCase();
          return user.fullName?.toLowerCase().contains(lowerCaseQuery) ?? false ||
              user.roles.any((role) => role.toLowerCase().contains(lowerCaseQuery));
        }).toList();
      }
    });
  }

  void _showUserForm({User? user}) {
    final isEditing = user != null;
    final userNameController = TextEditingController(text: isEditing ? user.userName : '');
    final passwordController = TextEditingController(text: isEditing ? user.password : '');
    String selectedRole = isEditing && user.roles.isNotEmpty ? user.roles.first : 'USER';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? "Sửa người dùng" : "Thêm người dùng"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(userNameController, "Tên đăng nhập"),
                const SizedBox(height: 10),
                _buildTextField(passwordController, "Mật khẩu"),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: "Quyền",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                  items: ['USER', 'MANAGER', 'ADMIN'].map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                if (isEditing) {
                  _updateUserRole(user.userName, selectedRole);
                  _fetchUsers();
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? "Sửa" : "Thêm"),
            ),
          ],
        );
      },
    );
  }


  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Tìm kiếm theo tên hoặc quyền",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(1),
                ),
                onChanged: (value) {
                  _filterUsers(value); // Filter users when search query changes
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchUsers, // Pull-to-refresh functionality
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 10,
                        margin: const EdgeInsets.only(bottom: 20), // Thêm margin-bottom
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color.fromARGB(255, 25, 117, 215),
                            child: Text(
                              user.fullName?.isNotEmpty == true ? user.fullName![0] : '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(user.fullName ?? 'Chưa cập nhật', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Aligns the children to the start (left)
                            children: [
                              Text(user.trainingPoint != null ? 'Điểm rèn luyện: ${user.trainingPoint}' : 'Chưa cập nhật', style: const TextStyle(fontFamily: 'Roboto')),
                              const SizedBox(width: 10),
                              Text(user.userName, style: const TextStyle(fontFamily: 'Roboto')),
                              const SizedBox(width: 10),
                              Text(user.classId ?? 'Chưa cập nhật', style: const TextStyle(fontFamily: 'Roboto')),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _showUserForm(user: user),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}