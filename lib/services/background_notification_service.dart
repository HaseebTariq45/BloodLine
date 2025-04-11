import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Background task name constants
const String notificationSyncTaskName = "com.bloodline.notification_sync";
const String periodicBackgroundSyncTaskName = "com.bloodline.periodic_notification_sync";

// Task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 [BackgroundTask] Background task started: $task');
    
    // Initialize Firebase if necessary
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        debugPrint('🔄 [BackgroundTask] Firebase initialized in background task');
      }
    } catch (e) {
      debugPrint('❌ [BackgroundTask] Error initializing Firebase: $e');
      return false;
    }
    
    // Handle different task types
    try {
      switch (task) {
        case notificationSyncTaskName:
          await _syncNotificationsInBackground();
          break;
        case periodicBackgroundSyncTaskName:
          await _syncNotificationsInBackground();
          break;
        default:
          debugPrint('⚠️ [BackgroundTask] Unknown task: $task');
      }
      
      debugPrint('✅ [BackgroundTask] Background task completed: $task');
      return true;
    } catch (e) {
      debugPrint('❌ [BackgroundTask] Error executing background task: $e');
      return false;
    }
  });
}

// Sync notifications in background
Future<void> _syncNotificationsInBackground() async {
  debugPrint('🔄 [BackgroundSync] Starting background notification sync');
  
  try {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('⚠️ [BackgroundSync] No user logged in, skipping sync');
      return;
    }
    
    // Get user ID
    final userId = currentUser.uid;
    debugPrint('🔄 [BackgroundSync] Syncing notifications for user: $userId');
    
    // Initialize local notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    // Set up local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'blood_donation_channel',
      'Blood Donation Notifications',
      description: 'Notifications for blood donation app',
      importance: Importance.high,
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    // Get timestamp of last notification check
    final prefs = await SharedPreferences.getInstance();
    final lastCheckTimestamp = prefs.getString('last_notification_check') ?? '';
    DateTime? lastCheckTime;
    
    if (lastCheckTimestamp.isNotEmpty) {
      try {
        lastCheckTime = DateTime.parse(lastCheckTimestamp);
        debugPrint('🔄 [BackgroundSync] Last check time: $lastCheckTime');
      } catch (e) {
        debugPrint('⚠️ [BackgroundSync] Error parsing last check time: $e');
        lastCheckTime = null;
      }
    }
    
    // Query for new notifications
    Query notificationsQuery = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true);
    
    // Add timestamp filter if we have a last check time
    if (lastCheckTime != null) {
      notificationsQuery = notificationsQuery.where(
        'createdAt', 
        isGreaterThan: lastCheckTime,
      );
    }
    
    // Limit to 10 most recent notifications
    notificationsQuery = notificationsQuery.limit(10);
    
    // Execute query
    final querySnapshot = await notificationsQuery.get();
    
    debugPrint('🔄 [BackgroundSync] Found ${querySnapshot.docs.length} new notifications');
    
    // Process and display notifications
    for (var doc in querySnapshot.docs) {
      final notificationData = doc.data() as Map<String, dynamic>;
      
      debugPrint('🔄 [BackgroundSync] Processing notification: ${doc.id}');
      
      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        doc.id.hashCode, // Use document ID hash as notification ID
        notificationData['title'] ?? 'BloodLine Notification',
        notificationData['body'] ?? 'You have a new notification',
        details,
        payload: json.encode({
          'id': doc.id,
          'type': notificationData['type'],
          'metadata': notificationData['metadata'] ?? {},
        }),
      );
      
      debugPrint('✅ [BackgroundSync] Displayed notification: ${doc.id}');
    }
    
    // Update last check timestamp
    await prefs.setString(
      'last_notification_check', 
      DateTime.now().toIso8601String(),
    );
    
    debugPrint('✅ [BackgroundSync] Background notification sync completed');
  } catch (e) {
    debugPrint('❌ [BackgroundSync] Error during background sync: $e');
  }
}

class BackgroundNotificationService {
  // Initialize the background service
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('⚠️ [BackgroundService] Background tasks not supported on web');
      return;
    }
    
    debugPrint('🔄 [BackgroundService] Initializing background notification service');
    
    try {
      // Initialize Workmanager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      
      // Register one-time task for immediate check
      await Workmanager().registerOneOffTask(
        'initial_sync_${DateTime.now().millisecondsSinceEpoch}',
        notificationSyncTaskName,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      // Register periodic task for ongoing checks
      await Workmanager().registerPeriodicTask(
        periodicBackgroundSyncTaskName,
        periodicBackgroundSyncTaskName,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      debugPrint('✅ [BackgroundService] Background notification service initialized');
    } catch (e) {
      debugPrint('❌ [BackgroundService] Error initializing background service: $e');
    }
  }
  
  // Force an immediate sync
  static Future<void> syncNow() async {
    if (kIsWeb) return;
    
    try {
      await Workmanager().registerOneOffTask(
        'manual_sync_${DateTime.now().millisecondsSinceEpoch}',
        notificationSyncTaskName,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      
      debugPrint('✅ [BackgroundService] Manual sync task registered');
    } catch (e) {
      debugPrint('❌ [BackgroundService] Error registering manual sync task: $e');
    }
  }
  
  // Cancel all background tasks
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    
    try {
      await Workmanager().cancelAll();
      debugPrint('✅ [BackgroundService] All background tasks canceled');
    } catch (e) {
      debugPrint('❌ [BackgroundService] Error canceling background tasks: $e');
    }
  }
} 