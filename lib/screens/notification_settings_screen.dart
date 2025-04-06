import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../services/local_notification_service.dart';
import '../services/service_locator.dart';
import '../services/firebase_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Check notification settings when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).checkNotificationSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Notification Settings',
        showNotificationIcon: false,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildMainToggle(appProvider),
              const SizedBox(height: 16),
              // Divider
              const Divider(),
              const SizedBox(height: 16),
              _buildNotificationTypeToggles(appProvider),
              const SizedBox(height: 24),
              _buildTestNotificationButton(appProvider),
              const SizedBox(height: 16),
              _buildTestLocalNotificationButton(appProvider),
              const SizedBox(height: 16),
              _buildSyncNotificationsButton(appProvider),
              const SizedBox(height: 16),
              // Test notification button
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sending test notification...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    
                    // Get the FirebaseNotificationService instance
                    final notificationService = FirebaseNotificationService();
                    
                    // Call the test notification method
                    await notificationService.testNotification();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: AppConstants.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enable notifications to stay informed about blood donation requests, appointment reminders, and more.',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToggle(AppProvider appProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.notifications),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enable Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Turn on or off all notifications',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Switch(
              value: appProvider.notificationsEnabled,
              onChanged: (value) async {
                await appProvider.toggleNotifications(value);
              },
              activeColor: AppConstants.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeToggles(AppProvider appProvider) {
    bool mainEnabled = appProvider.notificationsEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Notification Types',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Email notifications
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.email_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Receive notifications via email',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: appProvider.emailNotificationsEnabled,
                  onChanged:
                      mainEnabled
                          ? (value) async {
                            await appProvider.toggleEmailNotifications(value);
                          }
                          : null,
                  activeColor: AppConstants.primaryColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Push notifications
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Receive notifications on your device',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: appProvider.pushNotificationsEnabled,
                  onChanged:
                      mainEnabled
                          ? (value) async {
                            await appProvider.togglePushNotifications(value);
                          }
                          : null,
                  activeColor: AppConstants.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestNotificationButton(AppProvider appProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            appProvider.notificationsEnabled
                ? () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  await appProvider.sendTestNotification();
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Send Test Notification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTestLocalNotificationButton(AppProvider appProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Test Local Notification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Send a test local notification to your device. This will appear in your notification bar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Send Local Notification'),
                onPressed: appProvider.notificationsEnabled
                    ? () async {
                        // Show feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sending local notification...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        
                        // Get the local notification service
                        final localNotificationService = serviceLocator.localNotificationService;
                        
                        // Send a test notification
                        await localNotificationService.showNotification(
                          title: 'BloodLine Test Notification',
                          body: 'This is a test local notification from BloodLine app!',
                          importance: NotificationImportance.high,
                        );
                        
                        // Show success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Local notification sent successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncNotificationsButton(AppProvider appProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Sync Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manually sync your notifications with the server to ensure you have the latest updates.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Sync Now'),
                onPressed: appProvider.notificationsEnabled
                    ? () async {
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Syncing notifications...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        
                        // Refresh notifications
                        await appProvider.refreshNotifications();
                        
                        // Show success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications synced successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
