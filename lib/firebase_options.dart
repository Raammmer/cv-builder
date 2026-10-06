import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated from your google-services.json for project `cv-builder-64e52`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeZq-8wAiZBZCJY8Hs9uEA9Yu84zuTXDU',
    appId: '1:773541196171:android:e8add38e11a476cb297f8e',
    messagingSenderId: '773541196171',
    projectId: 'cv-builder-64e52',
    storageBucket: 'cv-builder-64e52.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCeZq-8wAiZBZCJY8Hs9uEA9Yu84zuTXDU',
    appId: '1:773541196171:web:e8add38e11a476cb297f8e',
    messagingSenderId: '773541196171',
    projectId: 'cv-builder-64e52',
    storageBucket: 'cv-builder-64e52.firebasestorage.app',
  );
}
