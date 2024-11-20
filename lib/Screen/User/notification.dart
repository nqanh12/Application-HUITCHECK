import 'package:flutter/material.dart';
import 'package:huitcheck/API/api_notification.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsPage> {
  late NotificationService notificationService;
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  String? _token;

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
      notificationService = NotificationService(_token!);
      _loadNotifications();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final fetchedNotifications = await notificationService.fetchNotifications();
      setState(() {
        notifications = fetchedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markNotificationAllAsRead() async {
    try {
      await notificationService.markAllAsRead();
      setState(() {
        for (var notification in notifications) {
          notification.isRead = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all notifications as read: $e')),
      );
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await notificationService.markAsRead(notificationId);
      setState(() {
        notifications.firstWhere((notification) => notification.notificationId == notificationId).isRead = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notification as read: $e')),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await notificationService.deleteNotification(notificationId);
      setState(() {
        notifications.removeWhere((notification) => notification.notificationId == notificationId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
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
            context.go('/home');
          },
        ),
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.00,
          ),
          child: Text(
            "Thông báo",
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.height * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 25, 117, 215),
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_as_unread),
            onPressed: _markNotificationAllAsRead,
          ),
          const SizedBox(width: 30),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 25, 117, 215),
              Color.fromARGB(255, 255, 255, 255),],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
            ? const Center(child: Text('Chưa có thông báo', style: TextStyle(fontSize: 24, color: Colors.black54)))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return Center(
              child: SizedBox(
                width: 700,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) async {
                      await _deleteNotification(notifications[index].notificationId);
                    },
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: notifications[index].isRead ? Colors.grey : Colors.blueAccent,
                          child: Icon(
                            notifications[index].isRead ? Icons.notifications_none : Icons.notifications_active,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          notifications[index].message,
                          style: TextStyle(
                            fontWeight: notifications[index].isRead ? FontWeight.normal : FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          _formatDateTime(notifications[index].createDate),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'Đánh dấu là đã đọc') {
                              _markNotificationAsRead(notifications[index].notificationId);
                            } else if (value == 'Xoá thông báo') {
                              _deleteNotification(notifications[index].notificationId);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return {'Đánh dấu là đã đọc', 'Xoá thông báo'}.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime).add(const Duration(hours: 7));
    final DateFormat formatter = DateFormat('dd/MM/yyyy - HH:mm a');
    return formatter.format(parsedDate);
  }
}