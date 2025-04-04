import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Preferences keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _emailNotificationsKey = 'email_notifications_enabled';
  static const String _pushNotificationsKey = 'push_notifications_enabled';
  
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  
  // Factory constructor
  factory NotificationService() => _instance;
  
  // Private constructor
  NotificationService._internal();
  
  // Get notification settings
  Future<bool> areNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }
  
  Future<bool> areEmailNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool mainSetting = prefs.getBool(_notificationsEnabledKey) ?? false;
    if (!mainSetting) return false;
    
    return prefs.getBool(_emailNotificationsKey) ?? false;
  }
  
  Future<bool> arePushNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool mainSetting = prefs.getBool(_notificationsEnabledKey) ?? false;
    if (!mainSetting) return false;
    
    return prefs.getBool(_pushNotificationsKey) ?? false;
  }
  
  // Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    
    // If main setting is disabled, ensure all sub-settings are disabled too
    if (!enabled) {
      await prefs.setBool(_emailNotificationsKey, false);
      await prefs.setBool(_pushNotificationsKey, false);
    }
  }
  
  Future<void> setEmailNotificationsEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, enabled);
  }
  
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, enabled);
  }
  
  // Mock methods to simulate notification behavior
  
  // Send test notification
  Future<bool> sendTestNotification() async {
    // In a real app, this would connect to a notification service
    print('Sending test notification...');
    return true;
  }
  
  // Send email notification
  Future<bool> sendEmailNotification(String email, String subject, String body) async {
    // In a real app, this would connect to an email service
    print('Sending email notification to $email: $subject');
    return true;
  }
  
  // Send push notification
  Future<bool> sendPushNotification(String userId, String title, String body) async {
    // In a real app, this would connect to FCM or another push service
    print('Sending push notification to $userId: $title');
    return true;
  }
  
  // Initialize notification service - would set up Firebase, etc. in a real app
  Future<void> initialize() async {
    print('Initializing notification service...');
    // In a real app with Firebase, we would do something like:
    // await Firebase.initializeApp();
    // await FirebaseMessaging.instance.requestPermission();
  }
} 