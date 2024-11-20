import 'package:huitcheck/API/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  FeedbackPageState createState() => FeedbackPageState();
}

class FeedbackPageState extends State<FeedbackPage> {
  List<Map<String, dynamic>> feedbacks = [];
  String? _token;
  Logger logger = Logger();
  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
    if (_token != null) {
      _fetchFeedbacksAndEventNames();
    }
  }

  Future<void> _fetchFeedbacksAndEventNames() async {
    if (_token == null) return;

    final feedbackResponse = await http.get(
      Uri.parse('${baseUrl}api/feedback/getMyFeedback'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (feedbackResponse.statusCode == 200) {
      final feedbackData = json.decode(utf8.decode(feedbackResponse.bodyBytes));
      final feedbackList = List<Map<String, dynamic>>.from(feedbackData['result']);

      for (var feedback in feedbackList) {
        final eventId = feedback['eventId'];
        final eventNameResponse = await http.get(
          Uri.parse('${baseUrl}api/events/getEventName/$eventId'),
          headers: {
            'Authorization': 'Bearer $_token',
          },
        );

        if (eventNameResponse.statusCode == 200) {
          final eventNameData = json.decode(utf8.decode(eventNameResponse.bodyBytes));
          feedback['eventName'] = eventNameData['result']['name'];
        } else {
          feedback['eventName'] = 'Unknown Event';
        }
      }

      setState(() {
        feedbacks = feedbackList;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load feedbacks: ${feedbackResponse.statusCode}')),
      );
      logger.e('Failed to load feedbacks: ${feedbackResponse.body}');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text(
          "Phản hồi",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        elevation: 0,
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
        child: feedbacks.isEmpty
            ? const Center(
          child: Text(
            'No feedbacks available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
        )
            : Center(
          child: SizedBox(
            width: 700,
            child: ListView.builder(
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final feedback = feedbacks[index];
                return _buildFeedbackCard(feedback);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final String formattedDate = formatter.format(DateTime.parse(feedback['createdDate']));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          title: Text(
            feedback['eventName'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                "${feedback['feedback']}",
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 5),
              Text(
                "Ngày gửi: $formattedDate",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 5),
            ],
          ),
          trailing: Icon(
            feedback['confirm'] ? Icons.check_circle : Icons.cancel,
            color: feedback['confirm'] ? Colors.green : Colors.red,
            size: 30,
          ),
        ),
      ),
    );
  }
}