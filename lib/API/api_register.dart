import 'dart:convert';
import 'package:huitcheck/API/constants.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class RegisterService {
  final Logger _logger = Logger();
  Future<bool> changePassword(String email, String userName, String password) async {
    const String url = '${baseUrl}api/users/getPassword';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userName': userName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['code'] == 1000) {
        return true;
      } else {
        return false;
      }
    } else {
      throw Exception('Failed to change password');
    }
  }
  Future<bool> checkMailAndUserName(String email, String userName) async {
    const String url = '${baseUrl}api/users/checkMailAndUserName';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userName': userName,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['code'] == 1000) {
        return true;
      } else {
        return false;
      }
    } else {
      throw Exception('Failed to check email and username');
    }
  }

  Future<bool> checkMailExist(String email) async {
    final url = Uri.parse('${baseUrl}api/users/checkMailExist');
    final body = jsonEncode({'email': email});

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['code'] == 1000) {
          return jsonResponse['result'];
        } else {
          _logger.e('Error: ${jsonResponse['message']}');
        }
      } else {
        _logger.e('Failed to check email: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Exception during email check: $e');
    }
    return false;
  }

  Future<AuthResponse?> register(String username, String password, String mail) async {
    final url = Uri.parse('${baseUrl}api/users/register');
    final body = jsonEncode({
      'userName': username,
      'password': password,
      'email': mail,
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
          return AuthResponse.fromJson(jsonResponse['result']);
        } else {
          _logger.e('Error: ${jsonResponse['message']}');
        }
      } else {
        _logger.e('Failed to register: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Exception during registration: $e');
    }
    return null;
  }
}

class AuthResponse {
  final String id;
  final String userName;
  final String? fullName;
  final String? gender;
  final String? classId;
  final int trainingPoint;
  final String email;
  final String? phone;
  final String? address;
  final List<String> eventsRegistered;
  final List<String> roles;

  AuthResponse({
    required this.id,
    required this.userName,
    this.fullName,
    this.gender,
    this.classId,
    required this.trainingPoint,
    required this.email,
    this.phone,
    this.address,
    required this.eventsRegistered,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      id: json['id'],
      userName: json['userName'],
      fullName: json['full_Name'],
      gender: json['gender'],
      classId: json['class_id'],
      trainingPoint: json['training_point'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      eventsRegistered: List<String>.from(json['eventsRegistered']),
      roles: List<String>.from(json['roles']),
    );
  }
}