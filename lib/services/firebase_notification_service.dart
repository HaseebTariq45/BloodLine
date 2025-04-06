import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';
import '../widgets/blood_response_notification_dialog.dart';
import '../widgets/donation_request_notification_dialog.dart';
import '../widgets/blood_request_notification_dialog.dart';
import '../models/notification_model.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() => _instance;

  FirebaseNotificationService._internal();

  // Initialize notification settings
  Future<void> initialize(BuildContext? context) async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'User notification permission status: ${settings.authorizationStatus}',
    );

    // Skip local notifications setup on web platform
    if (!kIsWeb) {
      // Initialize local notifications
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) async {
          final payload = details.payload;
          if (payload != null && context != null) {
            try {
              final data = json.decode(payload);
              await _handleNotificationTap(data, context);
            } catch (e) {
              debugPrint('Error parsing notification payload: $e');
            }
          }
        },
      );
    }

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      _showLocalNotification(message);
      
      // Print notification info instead
      if (message.notification != null) {
        debugPrint('Notification Title: ${message.notification?.title}');
        debugPrint('Notification Body: ${message.notification?.body}');
      }
    });

    // Only setup app-level notification handling if context is available
    if (context != null) {
      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) async {
        debugPrint('Message opened from background state!');
        await _handleNotificationTap(message.data, context);
      });

      // Check for initial notification (app was terminated)
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await _handleNotificationTap(initialMessage.data, context);
      }
    }

    // Subscribe to topics
    await _subscribeToTopics();

    // Save the device token to Firestore
    await _saveDeviceToken();
  }

  // Save device token to user's document
  Future<void> _saveDeviceToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('📱 [TokenSync] Getting FCM token for user ${currentUser.uid}');
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('📱 [TokenSync] FCM Token retrieved: ${token.substring(0, 10)}...');
          
          // Check if the token has changed by getting the user's document first
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
              
          if (userDoc.exists) {
            final userData = userDoc.data();
            final List<dynamic> existingTokens = userData?['deviceTokens'] ?? [];
            
            if (existingTokens.contains(token)) {
              debugPrint('📱 [TokenSync] Token already exists in user document, no update needed');
            } else {
              debugPrint('📱 [TokenSync] Saving new token to user document');
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .update({
                    'deviceTokens': FieldValue.arrayUnion([token]),
                    'lastTokenUpdate': DateTime.now().toIso8601String(),
                  });
              debugPrint('✅ [TokenSync] FCM Token saved successfully');
            }
          } else {
            debugPrint('⚠️ [TokenSync] User document does not exist, cannot save token');
          }
        } else {
          debugPrint('⚠️ [TokenSync] Could not retrieve FCM token');
        }
      } else {
        debugPrint('⚠️ [TokenSync] No authenticated user found, skipping token save');
      }
    } catch (e) {
      debugPrint('❌ [TokenSync] Error saving device token: $e');
    }
  }

  // Public method to save device token
  Future<void> saveDeviceToken() async {
    debugPrint('📱 [TokenSync] saveDeviceToken method called');
    await _saveDeviceToken();
  }

  // Show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Skip showing local notifications on web platform
    if (kIsWeb) return;
    
    // Create the notification channel FIRST for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'blood_donation_channel',
      'Blood Donation Notifications',
      description: 'Notifications for blood donation app',
      importance: Importance.high,
    );
    
    // Create the channel
    await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
    
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

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        notification.title ?? 'BloodLine Notification',
        notification.body ?? 'You have a new notification',
        details,
        payload: json.encode(data),
      );
    }
  }

  // Test notification method to verify notification drawer functionality
  Future<void> testNotification() async {
    try {
      // Skip on web platform
      if (kIsWeb) {
        debugPrint('📱 [LocalNotification] Test notification skipped on web platform');
        return;
      }
      
      debugPrint('📱 [LocalNotification] Sending test notification to drawer');
      
      // Create the notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'blood_donation_channel',
        'Blood Donation Notifications',
        description: 'Notifications for blood donation app',
        importance: Importance.max,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
          
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        'Test Notification',
        'This is a test notification that should appear in your drawer',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      debugPrint('📱 [LocalNotification] Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ [LocalNotification] Error showing test notification: $e');
    }
  }

  // Subscribe to relevant notification topics
  Future<void> _subscribeToTopics() async {
    try {
      // Skip topic subscription on web platforms
      if (kIsWeb) {
        debugPrint('Topic subscription skipped on web platform');
        return;
      }
      
      // Subscribe to general topic
      await _firebaseMessaging.subscribeToTopic('all_users');
      
      // Get user's blood type to subscribe to blood type specific topics
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData.containsKey('bloodType')) {
            final bloodType = userData['bloodType'] as String?;
            if (bloodType != null && bloodType.isNotEmpty) {
              // Subscribe to blood type specific topic
              final sanitizedBloodType = bloodType.replaceAll('+', '_plus').replaceAll('-', '_minus');
              await _firebaseMessaging.subscribeToTopic('blood_type_$sanitizedBloodType');
              debugPrint('Subscribed to blood type topic: blood_type_$sanitizedBloodType');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    // Skip processing if context is no longer valid
    if (!context.mounted) return;

    // Check notification type
    final String? notificationType = data['type'];

    if (notificationType == 'blood_request_response') {
      // Get basic notification fields
      final String? notificationId = data['id'];
      final String? userId = data['userId'];
      final String? recipientId = data['recipientId'];

      // Get the metadata field which might contain the responder information
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

      // Try to get data from both direct fields and metadata
      final String? requestId = metadata['requestId'] ?? data['requestId'];
      final String? responderName =
          metadata['responderName'] ?? data['responderName'];
      final String? responderPhone =
          metadata['responderPhone'] ?? data['responderPhone'];
      final String? bloodType = metadata['bloodType'] ?? data['bloodType'];
      final String? responderId =
          metadata['responderId'] ?? data['responderId'];

      debugPrint(
        'Blood request response - notification type: $notificationType',
      );
      debugPrint(
        'Blood request response - userId: $userId, recipientId: $recipientId',
      );
      debugPrint('Blood request response - data keys: ${data.keys.toList()}');
      debugPrint('Blood request response - data: $data');
      debugPrint('Blood request response - metadata: $metadata');
      debugPrint('Blood request response - requestId: $requestId');
      debugPrint('Blood request response - responderName: $responderName');
      debugPrint('Blood request response - responderPhone: $responderPhone');
      debugPrint('Blood request response - bloodType: $bloodType');
      debugPrint('Blood request response - responderId: $responderId');

      if (requestId != null &&
          responderName != null &&
          responderPhone != null &&
          responderId != null &&
          responderId.isNotEmpty) {
        // Show response dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => BloodResponseNotificationDialog(
                responderName: responderName,
                responderPhone: responderPhone,
                bloodType: bloodType ?? 'Unknown',
                requestId: requestId,
                responderId: responderId,
                onViewRequest: () {
                  Navigator.of(context, rootNavigator: true).pushNamed(
                    '/blood_requests_list',
                    arguments: {
                      'initialTab': 3,
                      'highlightRequestId': requestId,
                    },
                  );
                },
              ),
        );
      } else {
        // Notify user about missing responder information
        if (responderId == null || responderId.isEmpty) {
          debugPrint('Error: Missing responderId in notification data');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not show details: Missing responder information',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Fallback - navigate to blood requests list if requestId is available
        if (requestId != null) {
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/blood_requests_list',
            arguments: {'initialTab': 3, 'highlightRequestId': requestId},
          );
        }
      }
    } else if (notificationType == 'blood_request_accepted') {
      // Get basic notification fields
      final String? notificationId = data['id'];
      final String? userId = data['userId'];
      
      // Get the metadata field which might contain the responder information
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

      // Try to get data from both direct fields and metadata
      final String? requestId = metadata['requestId'] ?? data['requestId'];
      final String? responderName = metadata['responderName'] ?? data['responderName'];
      final String? responderPhone = metadata['responderPhone'] ?? data['responderPhone'];
      final String? bloodType = metadata['bloodType'] ?? data['bloodType'];
      final String? responderId = metadata['responderId'] ?? data['responderId'];

      debugPrint(
        'Blood request accepted - notification type: $notificationType',
      );
      debugPrint('Blood request accepted - userId: $userId');
      debugPrint('Blood request accepted - data keys: ${data.keys.toList()}');
      debugPrint('Blood request accepted - data: $data');
      debugPrint('Blood request accepted - metadata: $metadata');
      
      // Show a success message and navigate to the donation tracking screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            responderName != null 
                ? '$responderName has accepted your blood request' 
                : 'Your blood request has been accepted',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () {
              if (requestId != null) {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  '/donation_tracking',
                  arguments: {'initialTab': 0, 'requestId': requestId},
                );
              }
            },
            textColor: Colors.white,
          ),
        ),
      );
      
      // Navigate to donation tracking screen to show the accepted request
      if (requestId != null) {
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/donation_tracking',
          arguments: {'initialTab': 0, 'requestId': requestId},
        );
      }
    } else if (notificationType == 'donation_request') {
      // Get basic notification fields
      final String? notificationId = data['id'];
      final String? userId = data['userId'];
      final String? recipientId = data['recipientId'];

      // Get the metadata field which contains all the requester information
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

      // Debug info
      debugPrint('Donation request - notification type: $notificationType');
      debugPrint('Donation request - userId: $userId, recipientId: $recipientId');
      debugPrint('Donation request - data keys: ${data.keys.toList()}');
      debugPrint('Donation request - data: $data');
      debugPrint('Donation request - metadata: $metadata');

      if (metadata.isEmpty) {
        debugPrint('ERROR: Empty metadata in donation request notification');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not show details: Missing essential requester information',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Check if the donation request has already been accepted
      final String requestId = metadata['requestId'] ?? notificationId ?? '';
      bool isAlreadyAccepted = false;
      
      try {
        if (requestId.isNotEmpty) {
          final donationDoc = await FirebaseFirestore.instance
              .collection('donation_requests')
              .doc(requestId)
              .get();
          
          if (donationDoc.exists && donationDoc.data() != null) {
            final donationData = donationDoc.data()!;
            isAlreadyAccepted = donationData['status'] == 'Accepted';
            debugPrint('Donation request status: ${donationData['status']}, isAlreadyAccepted: $isAlreadyAccepted');
          }
        }
      } catch (e) {
        debugPrint('Error checking donation request status: $e');
        // Continue with default value (false) if there's an error
      }

      // Handle donation request notification - show dialog to accept or reject
      showDialog(
        context: context,
        builder:
            (context) => DonationRequestNotificationDialog(
              // Use the notification's id as the requestId if not provided in metadata
              requestId: requestId,
              requesterId: metadata['requesterId'] ?? '',
              requesterName: metadata['requesterName'] ?? '',
              requesterPhone: metadata['requesterPhone'] ?? '',
              requesterEmail: metadata['requesterEmail'] ?? '',
              requesterBloodType:
                  metadata['bloodType'] ?? metadata['requesterBloodType'] ?? '',
              requesterAddress:
                  metadata['requesterAddress'] ?? metadata['location'] ?? '',
              isAlreadyAccepted: false, // Force to false to ensure Accept button appears
            ),
      );
    } else if (notificationType == 'blood_request') {
      // Get basic notification fields
      final String? notificationId = data['id'];
      final String? userId = data['userId'];
      final String? recipientId = data['recipientId'];

      // Get the metadata field which contains all the requester information
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

      // Debug info
      debugPrint('Blood request - notification type: $notificationType');
      debugPrint('Blood request - userId: $userId, recipientId: $recipientId');
      debugPrint('Blood request - data keys: ${data.keys.toList()}');
      debugPrint('Blood request - data: $data');
      debugPrint('Blood request - metadata: $metadata');

      if (metadata.isEmpty) {
        debugPrint('ERROR: Empty metadata in blood request notification');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not show details: Missing essential requester information',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Handle blood request notification - show dialog to accept or decline the request
      showDialog(
        context: context,
        builder:
            (context) => BloodRequestNotificationDialog(
              requestId:
                  metadata['requestId'] ??
                  data['requestId'] ??
                  notificationId ??
                  '',
              requesterId: metadata['requesterId'] ?? data['requesterId'] ?? '',
              requesterName:
                  metadata['requesterName'] ?? data['requesterName'] ?? '',
              requesterPhone:
                  metadata['requesterPhone'] ?? data['requesterPhone'] ?? '',
              bloodType: metadata['bloodType'] ?? data['bloodType'] ?? '',
              location: metadata['location'] ?? data['location'] ?? '',
              urgency: metadata['urgency'] ?? data['urgency'] ?? 'Normal',
              notes: metadata['notes'] ?? data['notes'] ?? '',
              requestDate:
                  metadata['requestDate'] ??
                  data['requestDate'] ??
                  DateTime.now().toIso8601String(),
            ),
      );
    }
  }

  // Send a notification when someone responds to a blood request
  Future<void> sendBloodRequestResponseNotification({
    required String requesterId,
    required String requesterName,
    required String requestId,
    required String responderName,
    required String responderPhone,
    required String bloodType,
  }) async {
    try {
      // 1. Get requester's device tokens from Firestore
      final requesterDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(requesterId)
              .get();

      if (!requesterDoc.exists) {
        debugPrint('Requester document not found');
        return;
      }

      final requesterData = requesterDoc.data();
      if (requesterData == null) return;

      final deviceTokens = requesterData['deviceTokens'];
      if (deviceTokens == null ||
          (deviceTokens is List && deviceTokens.isEmpty)) {
        debugPrint('No device tokens found for requester');
        return;
      }

      // 2. Create the notification in Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': requesterId,
        'title': 'Response to Your Blood Request',
        'body': '$responderName has responded to your blood request',
        'type': 'blood_request_response',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'requestId': requestId,
          'responderName': responderName,
          'responderPhone': responderPhone,
          'bloodType': bloodType,
        },
      });

      debugPrint('Blood request response notification created');

      // Note: For actual push notifications, you would need a server-side component
      // with Firebase Cloud Messaging (FCM) to send the notifications to the device tokens.
      // This would typically be done with a Cloud Function or a backend server.

      // For this implementation, we'll rely on Firestore triggers (which you'd implement separately)
      // or the app checking the notifications collection when it opens.
    } catch (e) {
      debugPrint('Error sending blood request response notification: $e');
    }
  }

  // Send notification when new blood request is created
  Future<void> sendBloodRequestNotification({
    required String requesterId,
    required String requesterName,
    required String requesterPhone,
    required String bloodType,
    required String location,
    required String city,
    required String urgency,
    required String notes,
    required String requestId,
    required List<String> recipientIds,
  }) async {
    try {
      debugPrint(
        'Sending blood request notification to ${recipientIds.length} recipients',
      );
      final batch = FirebaseFirestore.instance.batch();
      final requestDate = DateTime.now().toIso8601String();

      for (String recipientId in recipientIds) {
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();

        // Create notification document
        final notification = {
          'id': notificationRef.id,
          'userId': recipientId,  // The user who should see this notification
          'senderId': requesterId,
          'title': 'Blood Donation Request',
          'body':
              '$requesterName needs $bloodType blood type ${urgency == 'Urgent' ? '(URGENT)' : ''}',
          'type': 'blood_request',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'requestId': requestId,
            'requesterId': requesterId,
            'requesterName': requesterName,
            'requesterPhone': requesterPhone,
            'bloodType': bloodType,
            'location': location,
            'city': city,
            'urgency': urgency,
            'notes': notes,
            'requestDate': requestDate,
            'recipientId': recipientId, // Keep this in metadata for reference
          },
        };

        batch.set(notificationRef, notification);
      }

      await batch.commit();
      debugPrint('Blood request notifications sent successfully');
    } catch (e) {
      debugPrint('Error sending blood request notifications: $e');
      rethrow;
    }
  }

  // Fetch full notification data from Firestore if necessary
  Future<Map<String, dynamic>?> _fetchFullNotificationData(
    String notificationId,
  ) async {
    try {
      debugPrint(
        'Attempting to fetch full notification data for ID: $notificationId',
      );

      if (notificationId.isEmpty) {
        debugPrint('Cannot fetch notification: Empty notification ID');
        return null;
      }

      final notificationDoc =
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notificationId)
              .get();

      if (!notificationDoc.exists) {
        debugPrint('Notification document not found in Firestore');
        return null;
      }

      final data = notificationDoc.data();
      debugPrint('Retrieved notification data from Firestore: $data');
      return data;
    } catch (e) {
      debugPrint('Error fetching notification data: $e');
      return null;
    }
  }

  // Send notification for donation request
  Future<String> sendDonationRequestNotification({
    required String requesterId,
    required String requesterName,
    required String requesterPhone,
    required String requesterEmail,
    required String requesterBloodType,
    required String requesterAddress,
    required String recipientId,
  }) async {
    try {
      debugPrint(
        'Sending donation request notification to recipient: $recipientId',
      );

      // Create a unique request ID
      final requestId =
          'donation_${DateTime.now().millisecondsSinceEpoch}_${requesterId.substring(0, min(5, requesterId.length))}';

      // Create notification document
      final notificationRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      final notification = {
        'id': notificationRef.id,
        'userId': recipientId,  // The user who should see this notification
        'senderId': requesterId,
        'title': 'Request for Your Blood Donation',
        'body': '$requesterName needs your blood donation assistance',
        'type': 'donation_request',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'requestId': requestId,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'requesterPhone': requesterPhone,
          'requesterEmail': requesterEmail,
          'requesterBloodType': requesterBloodType,
          'requesterAddress': requesterAddress,
        },
      };

      await notificationRef.set(notification);
      debugPrint(
        'Donation request notification created with ID: ${notificationRef.id}',
      );

      // Also create a record in the donation_requests collection
      await FirebaseFirestore.instance
          .collection('donation_requests')
          .doc(requestId)
          .set({
            'id': requestId,
            'donorId': requesterId,
            'donorName': requesterName,
            'recipientId': recipientId,
            'status': 'Pending',
            'bloodType': requesterBloodType,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return notificationRef.id;
    } catch (e) {
      debugPrint('Error sending donation request notification: $e');
      rethrow;
    }
  }

  // Add a notification to Firestore
  Future<NotificationModel> addNotification(NotificationModel notification) async {
    try {
      // Add the notification to Firestore
      final documentReference = FirebaseFirestore.instance
          .collection('notifications')
          .doc();
      
      // Create a copy with the generated ID
      final notificationWithId = notification.copyWith(id: documentReference.id);
      
      // Save to Firestore
      await documentReference.set(notificationWithId.toMap());
      
      // Get user's device tokens to send push notification
      await _sendPushNotificationToUser(
        userId: notification.userId,
        title: notification.title,
        body: notification.body,
        data: {
          'notificationId': documentReference.id,
          'type': notification.type,
          'metadata': notification.metadata,
        },
      );
      
      debugPrint('Notification added to Firestore and push notification sent');
      return notificationWithId;
    } catch (e) {
      debugPrint('Error adding notification: $e');
      rethrow;
    }
  }
  
  // Send a cloud message to a user's device(s)
  Future<void> _sendPushNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's device tokens
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('User document not found, cannot send push notification');
        return;
      }
      
      final userData = userDoc.data();
      if (userData == null) {
        debugPrint('User data is null, cannot send push notification');
        return;
      }
      
      final List<dynamic> deviceTokens = userData['deviceTokens'] ?? [];
      
      if (deviceTokens.isEmpty) {
        debugPrint('No device tokens found for user, cannot send push notification');
        return;
      }
      
      // Log what would be sent
      debugPrint('📲 Would send push notification to ${deviceTokens.length} devices:');
      debugPrint('📲 Title: $title');
      debugPrint('📲 Body: $body');
      debugPrint('📲 Data: $data');
      
      // Instead of using Firebase Functions directly, add a message to a Firestore collection
      // that will trigger a Cloud Function (if configured)
      try {
        await FirebaseFirestore.instance.collection('push_notifications').add({
          'tokens': deviceTokens,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Push notification request added to Firestore for Cloud Function processing');
      } catch (e) {
        debugPrint('Error adding push notification request to Firestore: $e');
        debugPrint('You need to implement a server-side component to send push notifications');
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
