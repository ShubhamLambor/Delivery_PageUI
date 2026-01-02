
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyAzYxsIz4TgrM7lkbqOpetqeddK3LQMtR4',
    appId: '1:21623505552:web:aab500b3baf5bfc2510e15',
    messagingSenderId: '21623505552',
    projectId: 'tiffinity-f0fcb',
    authDomain: 'tiffinity-f0fcb.firebaseapp.com',
    storageBucket: 'tiffinity-f0fcb.firebasestorage.app',
    measurementId: 'G-36C3B8YZB7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD8nEKL7hmUxw7_dIsrXVIrJEjSg0Q3GjI',
    appId: '1:21623505552:android:f1784fd5d1abf50d510e15',
    messagingSenderId: '21623505552',
    projectId: 'tiffinity-f0fcb',
    storageBucket: 'tiffinity-f0fcb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDN71oU5gF4yfVQCY3CkVkeCS_BYdUZFdo',
    appId: '1:21623505552:ios:ef1d291161409f92510e15',
    messagingSenderId: '21623505552',
    projectId: 'tiffinity-f0fcb',
    storageBucket: 'tiffinity-f0fcb.firebasestorage.app',
    iosBundleId: 'com.example.deliveryui',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDN71oU5gF4yfVQCY3CkVkeCS_BYdUZFdo',
    appId: '1:21623505552:ios:ef1d291161409f92510e15',
    messagingSenderId: '21623505552',
    projectId: 'tiffinity-f0fcb',
    storageBucket: 'tiffinity-f0fcb.firebasestorage.app',
    iosBundleId: 'com.example.deliveryui',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAzYxsIz4TgrM7lkbqOpetqeddK3LQMtR4',
    appId: '1:21623505552:web:e8610ab2571b5d03510e15',
    messagingSenderId: '21623505552',
    projectId: 'tiffinity-f0fcb',
    authDomain: 'tiffinity-f0fcb.firebaseapp.com',
    storageBucket: 'tiffinity-f0fcb.firebasestorage.app',
    measurementId: 'G-769FMCHBNP',
  );
}
