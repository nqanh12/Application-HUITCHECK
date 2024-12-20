// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyD-DrmBNbgX1HHUz6Cb981zYwMoQqup39k",
      authDomain: "eventmanagement-bc931.firebaseapp.com",
      projectId: "eventmanagement-bc931",
      storageBucket: "eventmanagement-bc931.appspot.com",
      messagingSenderId: "436065911178",
      appId: "1:436065911178:web:f900b11cb52460feefc873",
      measurementId: "G-BP098VW0QX"
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCy2rk5rpoEVDbCCWru515fVJfMmHzYSmM',
    appId: '1:436065911178:android:8c8ed7418b03a06befc873',
    messagingSenderId: '436065911178',
    projectId: 'eventmanagement-bc931',
    storageBucket: 'eventmanagement-bc931.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBrkPpzskudakWl8AbyTV-gTGDmm95MPlk',
    appId: '1:436065911178:ios:81ae27993179d3d4efc873',
    messagingSenderId: '436065911178',
    projectId: 'eventmanagement-bc931',
    storageBucket: 'eventmanagement-bc931.appspot.com',
    iosBundleId: 'com.example.doan',
  );
}
