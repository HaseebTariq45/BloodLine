import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

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
          final userDoc = await _firestore
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
              await _firestore
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

  // Add a notification to Firestore
  Future<NotificationModel> addNotification(
    NotificationModel notification,
  ) async {
    try {
      // Create a notification document in Firestore
      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());

      // Return the notification with the new ID
      return notification.copyWith(id: docRef.id);
    } catch (e) {
      print('Error adding notification: $e');
      // Return the original notification (without a valid Firestore ID)
      return notification;
    }
  }

  // Get notifications for the current user
  Future<List<NotificationModel>> getUserNotifications() async {
    try {
      if (_userId == null) {
        debugPrint('📢 [NotificationService] Cannot fetch notifications: User ID is null');
        return [];
      }

      debugPrint('📢 [NotificationService] Fetching notifications for user: $_userId');

      // Note: We're removing the orderBy clause that requires a composite index
      // Instead, we'll sort the results client-side
      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _userId)
              .get();

      debugPrint('📢 [NotificationService] Retrieved ${querySnapshot.docs.length} notifications from Firestore');

      final notifications =
          querySnapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();

      // Sort by createdAt descending
      notifications.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
        final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

      final unreadCount = notifications.where((n) => !n.read).length;
      debugPrint('📢 [NotificationService] Processed ${notifications.length} notifications, unread: $unreadCount');
      
      // Log a summary of notification types if there are any
      if (notifications.isNotEmpty) {
        final types = notifications.map((n) => n.type).toSet();
        debugPrint('📢 [NotificationService] Notification types: ${types.join(', ')}');
      }

      return notifications;
    } catch (e) {
      debugPrint('❌ [NotificationService] Error getting user notifications: $e');
      return [];
    }
  }

  // Get a stream of notifications for the current user
  Stream<List<NotificationModel>> getUserNotificationsStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    // Note: We're removing the orderBy clause that requires a composite index
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
          final notifications =
              snapshot.docs
                  .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
                  .toList();

          // Sort by createdAt descending
          notifications.sort((a, b) {
            final dateA = DateTime.tryParse(a.createdAt) ?? DateTime(1970);
            final dateB = DateTime.tryParse(b.createdAt) ?? DateTime(1970);
            return dateB.compareTo(dateA); // Descending order (newest first)
          });

          return notifications;
        });
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      if (_userId == null) {
        return;
      }

      final batch = _firestore.batch();

      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _userId)
              .where('read', isEqualTo: false)
              .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Check if user has unread notifications
  Future<bool> hasUnreadNotifications() async {
    try {
      if (_userId == null) {
        return false;
      }

      final querySnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _userId)
              .where('read', isEqualTo: false)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for unread notifications: $e');
      return false;
    }
  }
}
