// File generated from google-services.json
// Project: inginiaapp

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZ1xaMoALHFfp1oW9GTH3xkzRdWgGud0Y',
    appId: '1:1042799065470:android:3d1c3ff21921ce0134db2f',
    messagingSenderId: '1042799065470',
    projectId: 'inginiaapp',
    storageBucket: 'inginiaapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAZ1xaMoALHFfp1oW9GTH3xkzRdWgGud0Y',
    appId: '1:1042799065470:ios:3d1c3ff21921ce0134db2f',
    messagingSenderId: '1042799065470',
    projectId: 'inginiaapp',
    storageBucket: 'inginiaapp.firebasestorage.app',
    iosBundleId: 'com.inginia.niger',
  );
}
