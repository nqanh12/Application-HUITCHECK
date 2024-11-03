import 'dart:convert';
import 'package:huitcheck/API/constants.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class AuthResponse {
  final String token;
  final bool authenticated;
  final String role;

  AuthResponse({
    required this.token,
    required this.authenticated,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['result']['token'],
      authenticated: json['result']['authenticated'],
      role: json['result']['role'],
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
          return AuthResponse.fromJson(jsonResponse);
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
}