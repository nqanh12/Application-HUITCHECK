import 'dart:convert';
import 'package:huitcheck/API/constants.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthResponse {
  final String token;
  final bool authenticated;
  final String role;
  final String departmentId;

  AuthResponse({
    required this.token,
    required this.authenticated,
    required this.role,
    required this.departmentId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['result']['token'],
      authenticated: json['result']['authenticated'],
      role: json['result']['role'],
      departmentId: json['result']['departmentId'],
    );
  }
}

class LoginService {
  final Logger _logger = Logger();

  Future<AuthResponse?> login(String username, String password) async {
    final url = Uri.parse('${baseUrl}auth/login'); // API URL
    final body = jsonEncode({
      'userName': username,
      'password': password,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['code'] == 1000) {
          AuthResponse authResponse = AuthResponse.fromJson(jsonResponse);

          // Save token, role, and departmentId to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', authResponse.token);
          await prefs.setString('role', authResponse.role);
          await prefs.setString('departmentId', authResponse.departmentId);

          return authResponse;
        } else {
          _logger.e('Error: ${jsonResponse['message']}');
        }
      } else {
        _logger.e('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Exception during login: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> logout(String token) async {
    final response = await http.post(
      Uri.parse('${baseUrl}auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['code'] == 1000) {
        // Remove token from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('role');
        await prefs.remove('departmentId');
      }
      return responseData;
    } else {
      throw Exception('Failed to logout: ${response.statusCode}');
    }
  }
}