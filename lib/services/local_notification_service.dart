import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Singleton pattern
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();
  
  // Initialize notification settings
  Future<void> initialize(BuildContext? context) async {
    // Skip setup on web platform
    if (kIsWeb) {
      debugPrint('📱 [LocalNotification] Skipping local notification setup on web platform');
      return;
    }
    
    debugPrint('📱 [LocalNotification] Initializing local notification service');
    
    // Initialize timezone data without dependency on flutter_timezone
    await _configureLocalTimeZone();
    
    // Initialize local notifications
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
            // Handle iOS foreground notification - needed for older iOS versions
            debugPrint('📱 [LocalNotification] Received iOS foreground notification: $title');
          }
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        final payload = details.payload;
        if (payload != null && context != null) {
          _handleNotificationTap(payload, context);
        }
      },
    );
    
    // Request notification permissions for iOS
    if (!kIsWeb) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    debugPrint('📱 [LocalNotification] Local notification service initialized successfully');
  }
  
  // Configure local timezone without using flutter_timezone
  Future<void> _configureLocalTimeZone() async {
    try {
      tz_data.initializeTimeZones();
      // Use a default location (UTC) as fallback
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint('📱 [LocalNotification] Set default timezone to UTC');
    } catch (e) {
      debugPrint('📱 [LocalNotification] Error setting timezone: $e');
    }
  }
  
  // Show a local notification with title and body
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationImportance importance = NotificationImportance.high,
  }) async {
    if (kIsWeb) {
      debugPrint('📱 [LocalNotification] Skipping local notification on web platform');
      return;
    }
    
    // Create a unique id for each notification
    final int id = DateTime.now().millisecondsSinceEpoch % 100000;
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bloodline_app_channel',
      'BloodLine App Notifications',
      channelDescription: 'Notifications for the BloodLine app',
      importance: _getAndroidImportance(importance),
      priority: Priority.high,
      ticker: 'BloodLine notification',
      icon: '@mipmap/ic_launcher',
      color: Colors.red,
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    final DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    debugPrint('📱 [LocalNotification] Showing notification - Title: "$title", Body: "$body"');
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  // Show a notification for blood donation requests
  Future<void> showBloodRequestNotification({
    required String requesterName,
    required String bloodType,
    required String location,
    String? requestId,
  }) async {
    final Map<String, dynamic> payload = {
      'type': 'blood_request',
      'requestId': requestId,
    };
    
    await showNotification(
      title: 'Urgent Blood Needed',
      body: '$requesterName needs $bloodType blood in $location',
      payload: json.encode(payload),
      importance: NotificationImportance.critical,
    );
  }
  
  // Show a notification for donation reminders
  Future<void> showDonationReminderNotification({
    required String message,
    String? donationId,
  }) async {
    final Map<String, dynamic> payload = {
      'type': 'donation_reminder',
      'donationId': donationId,
    };
    
    await showNotification(
      title: 'Donation Reminder',
      body: message,
      payload: json.encode(payload),
      importance: NotificationImportance.high,
    );
  }
  
  // Show a notification for appointment reminders
  Future<void> showAppointmentReminderNotification({
    required String message,
    String? appointmentId,
    DateTime? appointmentTime,
  }) async {
    final Map<String, dynamic> payload = {
      'type': 'appointment_reminder',
      'appointmentId': appointmentId,
      'appointmentTime': appointmentTime?.toIso8601String(),
    };
    
    await showNotification(
      title: 'Appointment Reminder',
      body: message,
      payload: json.encode(payload),
      importance: NotificationImportance.high,
    );
  }
  
  // Show a general notification
  Future<void> showGeneralNotification({
    required String title,
    required String message,
    String? type,
    String? id,
  }) async {
    final Map<String, dynamic> payload = {
      'type': type ?? 'general',
      'id': id,
    };
    
    await showNotification(
      title: title,
      body: message,
      payload: json.encode(payload),
      importance: NotificationImportance.default_importance,
    );
  }
  
  // Handle notification tap based on payload
  void _handleNotificationTap(String payload, BuildContext context) {
    try {
      debugPrint('📱 [LocalNotification] Handling notification tap with payload: $payload');
      
      final data = json.decode(payload) as Map<String, dynamic>;
      final String type = data['type'] as String? ?? 'general';
      
      switch (type) {
        case 'blood_request':
          final String? requestId = data['requestId'] as String?;
          if (requestId != null) {
            Navigator.of(context).pushNamed('/blood_requests_list', arguments: {
              'initialTab': 0,
              'highlightRequestId': requestId,
            });
          }
          break;
          
        case 'donation_reminder':
          final String? donationId = data['donationId'] as String?;
          Navigator.of(context).pushNamed('/donation_tracking', arguments: {
            'initialIndex': 0,
          });
          break;
          
        case 'appointment_reminder':
          Navigator.of(context).pushNamed('/donation_tracking', arguments: {
            'initialIndex': 1,
          });
          break;
          
        case 'general':
        default:
          Navigator.of(context).pushNamed('/notifications');
          break;
      }
    } catch (e) {
      debugPrint('📱 [LocalNotification] Error handling notification tap: $e');
      // In case of error, navigate to notifications screen
      Navigator.of(context).pushNamed('/notifications');
    }
  }
  
  // Schedule a notification for the future
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationImportance importance = NotificationImportance.high,
  }) async {
    if (kIsWeb) return;
    
    final int id = DateTime.now().millisecondsSinceEpoch % 100000;
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bloodline_scheduled_channel',
      'BloodLine Scheduled Notifications',
      channelDescription: 'Scheduled notifications for the BloodLine app',
      importance: _getAndroidImportance(importance),
      priority: Priority.high,
    );

    final DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails, 
      iOS: iosDetails,
    );
    
    debugPrint('📱 [LocalNotification] Scheduling notification for ${scheduledTime.toIso8601String()}');
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  // Cancel all notifications
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('📱 [LocalNotification] All notifications canceled');
  }
  
  // Check notification permissions
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    
    final NotificationAppLaunchDetails? launchDetails = 
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    
    return launchDetails?.didNotificationLaunchApp ?? false;
  }
  
  // Helper to convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Use UTC as default timezone
    return tz.TZDateTime.from(dateTime, tz.UTC);
  }
  
  // Convert importance enum to AndroidNotificationImportance
  Importance _getAndroidImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.critical:
        return Importance.max;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.default_importance:
        return Importance.defaultImportance;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.min:
        return Importance.min;
    }
  }
}

// Enum for notification importance
enum NotificationImportance {
  critical,
  high,
  default_importance,
  low,
  min,
} 