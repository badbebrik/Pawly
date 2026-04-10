import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for macOS.',
        ),
      TargetPlatform.windows => throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Windows.',
        ),
      TargetPlatform.linux => throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux.',
        ),
      TargetPlatform.fuchsia => throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Fuchsia.',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWNprY6fe1Lwq4qNIx4TKy0ijCZuTgxL4',
    appId: '1:897599900886:android:b10be94ecd700873becd77',
    messagingSenderId: '897599900886',
    projectId: 'pawly-6e5c5',
    storageBucket: 'pawly-6e5c5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDRxUe04m7J77xm5dc9sjGKi1xzh_7N87U',
    appId: '1:897599900886:ios:645d93947173cd8ebecd77',
    messagingSenderId: '897599900886',
    projectId: 'pawly-6e5c5',
    storageBucket: 'pawly-6e5c5.firebasestorage.app',
    iosBundleId: 'com.hse.pawly',
  );
}
