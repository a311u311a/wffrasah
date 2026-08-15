import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBsK3Pi9_3tsBwVJRyAGL2_zeOxUpLXYJc',
    appId: '1:314843853869:web:66cbfb1794075edb4f74a4',
    messagingSenderId: '314843853869',
    projectId: 'coupon-d52b2',
    authDomain: 'coupon-d52b2.firebaseapp.com',
    databaseURL: 'https://coupon-d52b2-default-rtdb.firebaseio.com',
    storageBucket: 'coupon-d52b2.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBsK3Pi9_3tsBwVJRyAGL2_zeOxUpLXYJc',
    appId: '1:314843853869:android:6e313b8883c90b214f74a4',
    messagingSenderId: '314843853869',
    projectId: 'coupon-d52b2',
    databaseURL: 'https://coupon-d52b2-default-rtdb.firebaseio.com',
    storageBucket: 'coupon-d52b2.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBtRC28Gffuc-P9W1zDYTghFdb87hySlrk',
    appId: '1:314843853869:ios:88efec8fa83e86b14f74a4',
    messagingSenderId: '314843853869',
    projectId: 'coupon-d52b2',
    databaseURL: 'https://coupon-d52b2-default-rtdb.firebaseio.com',
    storageBucket: 'coupon-d52b2.appspot.com',
    iosBundleId: 'com.rbhan.app',
  );
}
