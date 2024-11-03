import 'package:huitcheck/API/api_register.dart';
import 'package:huitcheck/Component/Home/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  RegisterState createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isPasswordVisible = false;
  final RegisterService _registerService = RegisterService();

  void _handleRegister() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final email = _emailController.text;

    // Check if email exists
    final emailExists = await _registerService.checkMailExist(email);
    if (emailExists) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email đã tồn tại')),
      );
      return;
    }

    // Validate the input
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản, mật khẩu và email không được để trống')),
      );
      return;
    }
    if(password.length < 8){
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu phải ít nhất 8 ký tự')),
      );
      return;
    }

    // Validate email format
    if (!email.endsWith('@gmail.com')) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sai định dạng')),
      );
      return;
    }

    // Call the register service
    final response = await _registerService.register(username, password, email);
    if (response != null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng kí thành công')),
      );
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => const Login(),
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng kí thất bại hoặc tài khoản đã tồn tại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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
          // Header with logo and text
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
              child: Column(
                children: [
                  Text(
                    'Đăng ký tài khoản',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontSize: MediaQuery.of(context).size.width * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/logo.png',
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
          ),
          // Registration form fields
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _usernameController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                      prefixIcon: const Icon(Icons.person, color: Color.fromARGB(255, 0, 0, 0)),
                      labelText: 'Tài khoản(MSSV)',
                      labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                      prefixIcon: const Icon(Icons.email, color: Color.fromARGB(255, 0, 0, 0)),
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                      prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 0, 0, 0)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      labelText: 'Mật khẩu',
                      labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _handleRegister();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: const Color.fromARGB(255, 0, 13, 254),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    child: const Text('Đăng ký'),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Bạn có tài khoản?',
                        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Login(),
                            ),
                          );
                        },
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 13, 254),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}