import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB0xTKR6q_I8Z8Q_Z8Q_Z8Q',
    appId: '1:123456789:web:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'test-project-12345',
    authDomain: 'test-project-12345.firebaseapp.com',
    databaseURL: 'https://test-project-12345.firebaseio.com',
    storageBucket: 'test-project-12345.appspot.com',
    measurementId: 'G-ABC123XYZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqh5tXxV5fqMmQuSjBKlsb-UzWRvn0Hhg',
    appId: '1:53820116759:android:a981a4b3005866ea943152',
    messagingSenderId: '53820116759',
    projectId: 'strm-3e0a7',
    databaseURL: 'https://strm-3e0a7.firebaseio.com',
    storageBucket: 'strm-3e0a7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0xTKR6q_I8Z8Q_Z8Q_Z8Q',
    appId: '1:123456789:ios:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'test-project-12345',
    databaseURL: 'https://test-project-12345.firebaseio.com',
    storageBucket: 'test-project-12345.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB0xTKR6q_I8Z8Q_Z8Q_Z8Q',
    appId: '1:123456789:macos:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'test-project-12345',
    databaseURL: 'https://test-project-12345.firebaseio.com',
    storageBucket: 'test-project-12345.appspot.com',
  );
}
