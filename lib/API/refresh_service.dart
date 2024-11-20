import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:huitcheck/API/constants.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RefreshService {
  final Logger _logger = Logger();

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> refreshCheckInStatus(String eventId, String userId) async {
    final String? token = await _getToken();
    if (token == null) {
      _logger.e('Token not found');
      return;
    }

    final String userUrl = '${baseUrl}api/users/refreshCheckInStatus/$eventId/$userId';
    final String eventUrl = '${baseUrl}api/events/refreshCheckIn/$eventId/$userId';

    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final responses = await Future.wait([
        http.put(Uri.parse(userUrl), headers: headers),
        http.put(Uri.parse(eventUrl), headers: headers),
      ]);

      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 1000) {
            // Handle successful response
            _logger.i('Success: ${data['result']}');
          } else {
            // Handle error in response
            _logger.e('Error: ${data['message']}');
          }
        } else {
          // Handle HTTP error
          _logger.e('HTTP Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Handle network or other errors
      _logger.e('Exception: $e');
    }
  }
  Future<void> refreshCheckOutStatus(String eventId, String userId) async {
    final String? token = await _getToken();
    if (token == null) {
      _logger.e('Token not found');
      return;
    }

    final String userUrl = '${baseUrl}api/users/refreshCheckOutStatus/$eventId/$userId';
    final String eventUrl = '${baseUrl}api/events/refreshCheckOut/$eventId/$userId';

    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final responses = await Future.wait([
        http.put(Uri.parse(userUrl), headers: headers),
        http.put(Uri.parse(eventUrl), headers: headers),
      ]);

      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 1000) {
            // Handle successful response
            _logger.i('Success: ${data['result']}');
          } else {
            // Handle error in response
            _logger.e('Error: ${data['message']}');
          }
        } else {
          // Handle HTTP error
          _logger.e('HTTP Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Handle network or other errors
      _logger.e('Exception: $e');
    }
  }
}