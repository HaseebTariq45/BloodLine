import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase with platform-specific options
      if (kIsWeb) {
        // Web platform initialization
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyBB_d0GchvHTiaaPqUpaqDU9GQe_ebxc0A",
            authDomain: "bloodline-2e8a4.firebaseapp.com",
            projectId: "bloodline-2e8a4",
            storageBucket: "bloodline-2e8a4.firebasestorage.app",
            messagingSenderId: "648078735490",
            appId: "1:648078735490:android:70e8994461418ec5cb9c9b",
          ),
        );
      } else {
        // Native platforms (Android, iOS, etc.)
        await Firebase.initializeApp();
      }

      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      rethrow;
    }
  }
}
