import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration for the platforms used by this Flutter app.
/// These identifiers are public client configuration, not service credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'Firebase has not been configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAGmHeeJJqGw1Nl4_v8YMYPz2Z73b9gkks',
    appId: '1:959986148667:android:8ee46615a1f2ceb0bac31e',
    messagingSenderId: '959986148667',
    projectId: 'demointurn',
    storageBucket: 'demointurn.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAsQEFKeetDEg5W3z-XiJHb3Fb7_2y4cc0',
    appId: '1:959986148667:web:ef2adf59c1a915b6bac31e',
    authDomain: 'demointurn.firebaseapp.com',
    messagingSenderId: '959986148667',
    projectId: 'demointurn',
    storageBucket: 'demointurn.firebasestorage.app',
    measurementId: 'G-D2EKT5V122',
  );

  // Firebase's FlutterFire Windows setup uses the project's Web app options.
  static const FirebaseOptions windows = web;
}
