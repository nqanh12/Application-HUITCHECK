import 'dart:async';

import 'package:huitcheck/API/constants.dart';
import 'package:huitcheck/Component/User/scannerqr.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ListEventCheck extends StatefulWidget {
  final String role;
  final String token;
  const ListEventCheck({super.key, required this.role, required this.token});

  @override
  EventListScreenState createState() => EventListScreenState();
}

class EventListScreenState extends State<ListEventCheck> {
  List<dynamic> _events = [];
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _timer;

  Future<void> _fetchEvents() async {
    const String url = '${baseUrl}api/events/listEvent';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> allEvents = json.decode(utf8.decode(response.bodyBytes))['result'];

      setState(() {
        _events = allEvents.where((event) {
          final DateFormat formatter = DateFormat('dd-MM-yyyy hh:mm a');
          final DateTime eventStartDate = DateTime.parse(event['dateStart']);
          final DateTime eventEndDate = DateTime.parse(event['dateEnd']);
          final DateTime now = DateTime.now();

          formatter.format(eventStartDate);
          formatter.format(eventEndDate);

          return
              (eventStartDate.isBefore(now) && eventEndDate.isAfter(now));
        }).toList();
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: ${response.statusCode}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchEvents();
    _startAutoReload();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoReload() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchEvents();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreEvents();
    }
  }

  void _loadMoreEvents() {
    // Load more events if needed
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  String _formatDateTime(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
    return formatter.format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          child: Text(
            "Điểm danh",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
      ),
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
              const SizedBox(height: 60),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchEvents,
                  child: _buildEventList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 20),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          hintText: "Tìm kiếm sự kiện...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final filteredEvents = _events
        .where((event) =>
        event['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          'Hiện tại không có sự kiện nào diễn ra',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 18,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(filteredEvents[index], index);
      },
    );
  }

  Widget _buildEventCard(dynamic event, int index) {
    final DateTime adjustedDateStart = DateTime.parse(event['dateStart']).add(const Duration(hours: 7));
    final DateTime adjustedDateEnd = DateTime.parse(event['dateEnd']).add(const Duration(hours: 7));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white.withOpacity(0.9),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListTile(
          contentPadding: const EdgeInsets.all(5),
          title: Text(
            event['name'],
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                "Ngày bắt đầu: ${_formatDateTime(adjustedDateStart.toIso8601String())} ",
                style: const TextStyle(color: Colors.black54),
              ),
              Text(
                "Ngày kết thúc: ${_formatDateTime(adjustedDateEnd.toIso8601String())} ",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          trailing: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 50),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRCodeScanScreen(token: widget.token, role: widget.role, eventId: event['eventId'], dateStart: event['dateStart'], dateEnd: event['dateEnd'], name: event['name']),
              ),
            ).then((_) {
              _fetchEvents(); // Reload data when returning from QRCodeScanScreen
            });
          },
        ),
      ),
    );
  }
}