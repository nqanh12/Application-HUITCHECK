import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  final String role;
  final String token;
  final String fullName;
  final String gender;
  final String phone;
  final String classID;
  final String email;
  final String address;
  const EditPersonalInfoScreen({
    super.key,
    required this.role,
    required this.token,
    required this.fullName,
    required this.gender,
    required this.phone,
    required this.classID,
    required this.email,
    required this.address,
  });

  @override
  EditPersonalInfoScreenState createState() => EditPersonalInfoScreenState();
}

class EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedGender;
  bool _isEmailEnabled = false;

  @override
  void initState() {
    super.initState();
    // Prepopulate the controllers with data from the widget
    _nameController.text = widget.fullName;
    _selectedGender = widget.gender.isEmpty ? widget.gender : widget.gender;
    _phoneController.text = widget.phone;
    _classController.text = widget.classID;
    _emailController.text = widget.email;
    _addressController.text = widget.address;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _classController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final RegExp regex = RegExp(r'^[^@]+@gmail\.com$');
    return regex.hasMatch(email);
  }

  Future<void> _updateUserInfo() async {
    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không hợp lệ')),
      );
      return;
    }

    if (_phoneController.text.length <= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại phải lớn hơn 8 ký tự')),
      );
      return;
    }

    const String url = '${baseUrl}api/users/updateInfo';
    final Map<String, dynamic> requestBody = {
      'full_Name': _nameController.text,
      'gender': _selectedGender,
      'class_id': _classController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
    };

    if (_isEmailEnabled == true) {
      requestBody['email'] = _emailController.text;
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['code'] == 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user info: ${jsonResponse['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user info: ${response.statusCode}')),
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
          "Chỉnh sửa thông tin",
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/background.png', // Replace with your image asset path
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
              padding: const EdgeInsets.only(top: 75.0),
              child: Column(
                children: [
                  // Avatar and form
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    AssetImage('assets/avatar.png'), // Replace with avatar
                  ),
                  const SizedBox(height: 20),
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField("Họ và tên", _nameController, false),
                            _buildGenderField(),
                            _buildInputField("Điện thoại", _phoneController, false, TextInputType.number, [FilteringTextInputFormatter.digitsOnly]),
                            _buildInputField("Lớp", _classController, false),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isEmailEnabled,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isEmailEnabled = value ?? false;
                                    });
                                  },
                                ),
                                const Text("Cập nhật email"),
                              ],
                            ),
                            _buildInputField("Email", _emailController, false, TextInputType.emailAddress, null, _isEmailEnabled),
                            _buildInputField("Địa chỉ", _addressController, false),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: _updateUserInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Cập nhật thông tin',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildInputField(String label, TextEditingController controller, bool obscureText, [TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters, bool enabled = true]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.black.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Giới tính",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Row(
            children: [
              Radio<String>(
                value: "Nam",
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const Text("Nam"),
              Radio<String>(
                value: "Nữ",
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const Text("Nữ"),
            ],
          ),
        ],
      ),
    );
  }
}