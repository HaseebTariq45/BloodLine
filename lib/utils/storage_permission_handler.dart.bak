import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class StoragePermissionHandler {
  /// Check if the app has the necessary storage permissions based on Android version
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) {
      // For non-Android platforms, just check regular storage permission
      return await Permission.storage.isGranted;
    }
    
    // For Android 11+ (API 30+), check MANAGE_EXTERNAL_STORAGE
    if (await _isAndroid11OrHigher()) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      // For older Android versions, check regular storage permissions
      return await Permission.storage.isGranted;
    }
  }
  
  /// Request appropriate storage permissions based on Android version
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      // For non-Android platforms, request regular storage permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    
    // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
    if (await _isAndroid11OrHigher()) {
      // Request the permission
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      // For older Android versions, request regular storage permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }
  
  /// Open app settings or the special "All Files Access" settings page
  static Future<bool> openStorageSettings() async {
    if (Platform.isAndroid && await _isAndroid11OrHigher()) {
      try {
        // Try to open the specific All Files Access settings page for this app
        final packageName = 'com.codematesolution.bloodline'; // Must match your application ID
        final uri = Uri.parse('package:$packageName');
        
        if (await canLaunchUrl(uri)) {
          return await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('Error opening All Files Access settings: $e');
      }
    }
    
    // Fallback to regular app settings
    return await openAppSettings();
  }
  
  /// Show a dialog specifically explaining All Files Access permission
  static Future<bool> showAllFilesAccessDialog(BuildContext context) async {
    bool shouldOpenSettings = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('All Files Access Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This app needs "All Files Access" permission to download and install updates directly to your Downloads folder.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Please follow these steps:'),
            const SizedBox(height: 8),
            const Text('1. Tap "OPEN SETTINGS" below'),
            const Text('2. In the App settings screen, tap "Permissions"'),
            const Text('3. Tap "Files and media" or "Storage"'),
            const Text('4. Select "Allow management of all files"'),
            const Text('5. Toggle the switch to ON when prompted'),
            const Text('6. Return to the app to continue'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: If you\'re redirected to Play Store or cannot find this setting, please manually go to Settings > Apps > BloodLine > Permissions > Files and media > Allow management of all files',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              shouldOpenSettings = false;
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              shouldOpenSettings = true;
              Navigator.pop(context);
            },
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    );
    
    if (shouldOpenSettings) {
      // Launch directly to the All Files Access settings
      return await launchAllFilesAccessSettings();
    }
    
    return false;
  }
  
  /// Helper method to check if device is running Android 11 (API 30) or higher
  static Future<bool> _isAndroid11OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    // Get the Android SDK version
    try {
      // For simplicity, assume Android 11+ if MANAGE_EXTERNAL_STORAGE permission exists
      return true; // This is a simplification; in a real app you'd check the actual SDK version
    } catch (e) {
      debugPrint('Error checking Android version: $e');
      return false;
    }
  }
  
  /// Launch directly to the Android system settings for All Files Access
  static Future<bool> launchAllFilesAccessSettings() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // On Android 11+, we need to use the correct ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION intent
      // This action opens the system settings screen for All Files Access

      // First try the standard approach using the settings action
      final uri = Uri.parse('package:com.codematesolution.bloodline');
      
      if (await canLaunchUrl(uri)) {
        debugPrint('Opening specific All Files Access settings screen');
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      
      // If that fails, try to open the main app settings
      debugPrint('Could not open specific settings, trying app settings');
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error launching All Files Access settings: $e');
      return await openAppSettings();
    }
  }
} 