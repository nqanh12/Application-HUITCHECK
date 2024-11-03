import 'dart:convert';
import 'package:huitcheck/API/constants.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final Logger _logger = Logger();
class UserInfo {
  final String id;
  final String userName;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final List<String> roles;

  UserInfo({
    required this.id,
    required this.userName,
    this.fullName,
    this.email,
    this.phone,
    this.address,
    required this.roles,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['result']['id'],
      userName: json['result']['userName'],
      fullName: json['result']['full_Name'],
      email: json['result']['email'],
      phone: json['result']['phone'],
      address: json['result']['address'],
      roles: List<String>.from(json['result']['roles']),
    );
  }
}

Future<UserInfo?> getUserInfo(String token) async {
  final url = Uri.parse('${baseUrl}myInfo');
  final response = await http.get(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",  // Bearer Token
    },
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    if (jsonResponse['code'] == 1000) {
      return UserInfo.fromJson(jsonResponse);
    } else {
      _logger.e('Failed to fetch user info: ${jsonResponse['message']}');
    }
  } else {
    _logger.e('Failed to fetch user info: ${response.statusCode}');
  }
  return null;
}