import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for PAWS.
///
/// Provide real values at build time with --dart-define, for example:
/// flutter build web --release --dart-define=FIREBASE_API_KEY=...
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: const String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'demo-api-key',
      ),
      appId: const String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '1:000000000000:web:paws',
      ),
      messagingSenderId: const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '000000000000',
      ),
      projectId: const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'paws-demo',
      ),
      authDomain: kIsWeb
          ? const String.fromEnvironment(
              'FIREBASE_AUTH_DOMAIN',
              defaultValue: 'paws-demo.firebaseapp.com',
            )
          : null,
      storageBucket: const String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
        defaultValue: 'paws-demo.appspot.com',
      ),
    );
  }
}
