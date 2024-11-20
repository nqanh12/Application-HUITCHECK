import 'package:flutter/material.dart';
import 'package:huitcheck/Screen/Home/login_template.dart';
import 'package:huitcheck/Screen/User/detail_event.dart';
import 'package:huitcheck/Screen/User/feedback.dart';
import 'package:huitcheck/Screen/User/list_event.dart';
import 'package:huitcheck/Screen/User/list_event_check.dart';
import 'package:huitcheck/Screen/User/notification.dart';
import 'package:huitcheck/Screen/User/setting.dart';
import 'package:huitcheck/Screen/User/history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huitcheck/Screen/Home/login.dart';
import 'package:huitcheck/Screen/Home/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final Logger logger = Logger();
  logger.e('Handling a background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final Logger logger = Logger();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.e('Received a foreground message: ${message.messageId}');
    if (message.notification != null) {
      logger.e('Notification Title: ${message.notification!.title}');
      logger.e('Notification Body: ${message.notification!.body}');
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    logger.e('Notification clicked! Message ID: ${message.messageId}');
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? role = prefs.getString('role');


  runApp(MyApp(token: token, role: role));
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? role;

  const MyApp({super.key, this.token, this.role});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: (token != null && role != null)
          ? (role!.contains('MANAGER_DEPARTMENT') || role!.contains('MANAGER_ENTIRE') ? '/listEventCheck' : '/home')
          : '/login_page',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const Login(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => Home(),
        ),
        GoRoute(
          path: '/eventlist',
          builder: (context, state) => const ListEvent(),
        ),
        GoRoute(
          path: '/eventdetails/:eventId',
          builder: (context, state) => EventDetailsScreen(eventId: state.pathParameters['eventId']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => NotificationsPage(),
        ),
        GoRoute(
          path: '/setting',
          builder: (context, state) => SettingsScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => CheckInOutStatusScreen(),
        ),
        GoRoute(
          path: '/listEventCheck',
          builder: (context, state) => ListEventCheck(),
        ),
        GoRoute(
          path: '/feedback',
          builder: (context, state) => FeedbackPage(),
        ),
        GoRoute(
          path: '/login_page',
          builder: (context, state) => LoginPage(),
        ),
      ],
    );
    return MaterialApp.router(
      title: 'HUITCHECK',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}