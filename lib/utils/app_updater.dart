import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_permission_handler.dart';
import 'package:open_file_manager/open_file_manager.dart';
import '../services/version_service.dart';
import '../services/service_locator.dart';

class AppUpdater {
  // Default version - now gets set from VersionService
  static String currentVersion = '1.0.0';
  static const String appName = 'BloodLine';
  
  // Firestore collection and document for app updates
  static const String updateCollection = 'app_updates';
  static const String updateDocument = 'latest_version';
  
  // Direct download link for APK on Google Drive (will be fetched from Firestore)
  static String latestApkUrl = '';
  
  // Indicates if an update is in progress
  static bool isUpdateInProgress = false;
  
  // Safe platform detection
  static bool get isAndroid {
    try {
      return io.Platform.isAndroid;
    } catch (e) {
      debugPrint('Platform detection error: $e');
      return false;
    }
  }
  
  static bool get isIOS {
    try {
      return io.Platform.isIOS;
    } catch (e) {
      debugPrint('Platform detection error: $e');
      return false;
    }
  }
  
  // Initialize by getting the current app version - now uses VersionService
  static Future<void> initialize() async {
    try {
      // Use VersionService if available
      final versionSvc = serviceLocator.versionService;
      await versionSvc.initialize();
      currentVersion = versionSvc.appVersion;
      debugPrint('AppUpdater using version from VersionService: $currentVersion');
    } catch (e) {
      // Fallback to package_info directly if VersionService is not available
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version.isNotEmpty 
            ? packageInfo.version 
            : '1.0.0'; // Ensure we never set an empty version
        debugPrint('AppUpdater fallback to PackageInfo: $currentVersion');
      } catch (e2) {
        // If there's an error, keep using the default version
        debugPrint('Error getting package info: $e2');
        // Ensure currentVersion is set to a valid value
        if (currentVersion.isEmpty) {
          currentVersion = '1.0.0';
        }
      }
    }
  }
  
  // Dropbox direct download handling
  static String _getProperDropboxUrl(String url) {
    if (url.isEmpty) return '';
    
    // Check if this is a Dropbox URL
    if (url.contains('dropbox.com')) {
      // Convert www.dropbox.com to dl.dropboxusercontent.com
      url = url.replaceAll('www.dropbox.com', 'dl.dropboxusercontent.com');
      
      // Remove the st parameter if present
      final uriObj = Uri.parse(url);
      final queryParams = Map<String, String>.from(uriObj.queryParameters);
      
      if (queryParams.containsKey('st')) {
        queryParams.remove('st');
      }
      
      // Set dl=1 to enable direct download
      queryParams['dl'] = '1';
      
      // Rebuild the URL with updated parameters
      final Uri newUri = Uri(
        scheme: uriObj.scheme,
        host: uriObj.host,
        path: uriObj.path,
        queryParameters: queryParams
      );
      
      return newUri.toString();
    }
    
    // Not a Dropbox URL, return original
    return url;
  }
  
  // Check for updates by comparing versions using Firestore
  static Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      // Make sure we have the current version
      try {
        await initialize();
      } catch (initError) {
        debugPrint('Error initializing AppUpdater: $initError');
        // Continue with default version
      }
      
      // Access Firestore to get update information
      try {
        final firestoreInstance = FirebaseFirestore.instance;
        final DocumentSnapshot updateDoc = await firestoreInstance
            .collection(updateCollection)
            .doc(updateDocument)
            .get();
        
        if (updateDoc.exists) {
          final data = updateDoc.data() as Map<String, dynamic>? ?? {};
          final latestVersion = data['latestVersion'] ?? '';
          final releaseNotes = data['releaseNotes'] ?? 'New features and bug fixes';
          final downloadUrl = data['downloadUrl'] ?? '';
          
          // Make sure we have a proper download URL for Dropbox
          String finalDownloadUrl = '';
          try {
            finalDownloadUrl = _getProperDropboxUrl(downloadUrl);
            debugPrint('Final download URL: $finalDownloadUrl');
          } catch (urlError) {
            debugPrint('Error processing download URL: $urlError');
            finalDownloadUrl = downloadUrl; // Fallback to original URL
          }
          
          // Save the latest APK URL for later use
          latestApkUrl = finalDownloadUrl;
          
          // Compare versions
          bool hasUpdate = false;
          try {
            hasUpdate = _isNewerVersion(latestVersion, currentVersion);
          } catch (versionError) {
            debugPrint('Error comparing versions: $versionError');
            // Default to no update if version comparison fails
          }
          
          return {
            'hasUpdate': hasUpdate,
            'latestVersion': latestVersion,
            'currentVersion': currentVersion,
            'releaseNotes': releaseNotes,
            'downloadUrl': finalDownloadUrl,
          };
        } else {
          debugPrint('Update document not found in Firestore');
          // If we can't fetch update info, return no update available
          return {
            'hasUpdate': false,
            'latestVersion': '',
            'currentVersion': currentVersion,
            'releaseNotes': '',
            'downloadUrl': '',
          };
        }
      } catch (firestoreError) {
        debugPrint('Error accessing Firestore: $firestoreError');
        return {
          'hasUpdate': false,
          'latestVersion': '',
          'currentVersion': currentVersion,
          'releaseNotes': '',
          'downloadUrl': '',
        };
      }
    } catch (e) {
      // If any error occurs, return no update available
      debugPrint('Error checking for updates: $e');
      return {
        'hasUpdate': false,
        'latestVersion': '',
        'currentVersion': currentVersion,
        'releaseNotes': '',
        'downloadUrl': '',
      };
    }
  }
  
  // Helper to compare semantic versions
  static bool _isNewerVersion(String newVersion, String currentVersion) {
    if (newVersion.isEmpty) return false;
    
    try {
      List<int> newParts = newVersion.split('.').map((part) => int.parse(part)).toList();
      List<int> currentParts = currentVersion.split('.').map((part) => int.parse(part)).toList();
      
      // Ensure lists are of equal length
      while (newParts.length < 3) newParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);
      
      // Compare major version
      if (newParts[0] > currentParts[0]) return true;
      if (newParts[0] < currentParts[0]) return false;
      
      // Compare minor version
      if (newParts[1] > currentParts[1]) return true;
      if (newParts[1] < currentParts[1]) return false;
      
      // Compare patch version
      return newParts[2] > currentParts[2];
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }
  
  // Download and install the update
  static Future<void> downloadUpdate(
    String url, 
    Function(double) onProgress, 
    Function(String) onComplete,
    Function(String) onError,
    {BuildContext? context}
  ) async {
    try {
      debugPrint('Starting download from URL: $url');
      isUpdateInProgress = true;
      
      // Request proper storage permissions based on Android version
      bool hasPermission = await StoragePermissionHandler.hasStoragePermission();
      
      if (!hasPermission) {
        if (context != null && context.mounted) {
          // If we have context, show the proper UI prompt
          debugPrint('Showing storage permission dialog');
          hasPermission = await StoragePermissionHandler.showAllFilesAccessDialog(context);
        } else {
          // Otherwise just try to request it directly
          debugPrint('Requesting storage permission without UI');
          hasPermission = await StoragePermissionHandler.requestStoragePermission();
        }
        
        if (!hasPermission) {
          debugPrint('Storage permission denied');
          isUpdateInProgress = false;
          onError('Storage permission required for downloading updates. Please grant permission in app settings.');
          return;
        }
      }
      
      // Save to Downloads folder instead of app-specific directory
      final fileName = 'bloodline_update.apk';
      String? savePath;
      
      if (isAndroid) {
        // Get the Downloads directory path on Android
        io.Directory? downloadsDir;
        try {
          // This is the path to the Downloads folder on most Android devices
          downloadsDir = io.Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            // Try alternative path
            downloadsDir = io.Directory('/storage/emulated/0/Downloads');
            if (!await downloadsDir.exists()) {
              // Fallback to app's external directory
              final appDir = await getExternalStorageDirectory();
              if (appDir != null) {
                downloadsDir = appDir;
              }
            }
          }
        } catch (e) {
          debugPrint('Error accessing Downloads directory: $e');
          // Fallback to app's external directory
          final appDir = await getExternalStorageDirectory();
          if (appDir != null) {
            downloadsDir = appDir;
          }
        }
        
        if (downloadsDir != null) {
          savePath = '${downloadsDir.path}/$fileName';
          debugPrint('Will save APK to Downloads folder: $savePath');
        } else {
          final errorMsg = 'Could not access Downloads directory';
          debugPrint(errorMsg);
          isUpdateInProgress = false;
          onError(errorMsg);
          return;
        }
      } else {
        // For iOS and other platforms
        final appDir = await getApplicationDocumentsDirectory();
        savePath = '${appDir.path}/$fileName';
      debugPrint('Will save APK to: $savePath');
      }
      
      try {
        // Handle Dropbox URL
        String downloadUrl = url;
        
        // Make sure we have a proper download URL for Dropbox
        if (url.contains('dropbox.com')) {
          debugPrint('Detected Dropbox URL, ensuring direct download...');
          downloadUrl = _getProperDropboxUrl(url);
          
          if (downloadUrl != url) {
            debugPrint('Using updated Dropbox URL: $downloadUrl');
          }
        }
        
        // Download the file with custom headers
        Map<String, String> headers = {};
        
        // Add browser-like headers for Dropbox to avoid any issues
        if (downloadUrl.contains('dropbox.com')) {
          headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/octet-stream, application/vnd.android.package-archive',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          };
          
          // Try a HEAD request first to check if we need to handle any redirects
          debugPrint('Sending HEAD request to check for redirects...');
          final redirectCheck = await http.head(Uri.parse(downloadUrl), headers: headers);
          debugPrint('HEAD response status: ${redirectCheck.statusCode}');
          
          if (redirectCheck.statusCode == 302 || redirectCheck.statusCode == 303) {
            final redirectUrl = redirectCheck.headers['location'];
            if (redirectUrl != null && redirectUrl.isNotEmpty) {
              downloadUrl = redirectUrl;
              debugPrint('Following redirect detected in HEAD request: $downloadUrl');
            }
          }
        }
        
        // Create a client that allows handling redirects manually if needed
        final client = http.Client();
        
        try {
          debugPrint('Sending download request to: $downloadUrl');
          debugPrint('Using headers: $headers');
          
          // Use http.Client().send() to get StreamedResponse for progress tracking
          final request = http.Request('GET', Uri.parse(downloadUrl));
          request.headers.addAll(headers);
          
          debugPrint('Sending HTTP request for file download...');
          final response = await client.send(request);
          
          // Log response details
          debugPrint('Response status code: ${response.statusCode}');
          debugPrint('Response headers: ${response.headers}');
          
          if (response.statusCode != 200) {
            final errorMsg = 'Download failed with status code: ${response.statusCode}';
            debugPrint(errorMsg);
            isUpdateInProgress = false;
            onError(errorMsg);
            return;
          }
          
          // Check content type - if it's HTML, we're likely getting an error page
          final contentType = response.headers['content-type'] ?? '';
          debugPrint('Content-Type: $contentType');
          
          if (contentType.contains('text/html') || contentType.contains('text/plain')) {
            debugPrint('Warning: Received content-type $contentType instead of application/octet-stream or application/vnd.android.package-archive');
            // Continue but monitor the download to check file type
          }
          
          final contentLength = response.contentLength ?? 0;
          debugPrint('Content length: $contentLength bytes');
          
          if (contentLength <= 0) {
            debugPrint('Warning: Content length is zero or not provided');
          }
          
          // Create the file and open a sink for writing
          final file = io.File(savePath!);
          final sink = file.openWrite();
          int receivedBytes = 0;
          
          debugPrint('Starting to receive file data...');
          await response.stream.forEach((chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            
            if (receivedBytes % 1000000 == 0) { // Log every ~1MB
              debugPrint('Received $receivedBytes / $contentLength bytes');
            }
            
            if (contentLength > 0) {
              final progress = receivedBytes / contentLength;
              onProgress(progress);
            } else {
              // If content length is unknown, show indeterminate progress
              onProgress(-1);
            }
          });
          
          await sink.flush();
          await sink.close();
          
          // Verify the file was created and has content
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint('File download complete. Size: $fileSize bytes');
            
            if (fileSize == 0) {
              final errorMsg = 'Downloaded file is empty (0 bytes)';
              debugPrint(errorMsg);
              isUpdateInProgress = false;
              onError(errorMsg);
              return;
            }
            
            // Check if it's actually an APK and not an HTML page
            final List<int> bytes = await file.openRead(0, min(50, fileSize.toInt())).fold<List<int>>(
              [],
              (List<int> previous, List<int> element) => previous..addAll(element),
            );
            final Uint8List firstBytes = Uint8List.fromList(bytes);
            
            // APK files start with the ZIP file signature (PK..)
            final bool isZipFile = firstBytes.length >= 4 && 
                                  firstBytes[0] == 0x50 && // P
                                  firstBytes[1] == 0x4B && // K
                                  firstBytes[2] == 0x03 && 
                                  firstBytes[3] == 0x04;
            
            // Log the first few bytes for debugging
            debugPrint('First 4 bytes of file: [${firstBytes.take(4).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}]');
            
            // Check if the file starts with HTML tags
            final String fileStart = String.fromCharCodes(firstBytes);
            debugPrint('File starts with: ${fileStart.substring(0, min(30, fileStart.length))}...');
            
            if (fileStart.contains('<!DOCTYPE html>') || fileStart.contains('<html')) {
              final errorMsg = 'Downloaded file is HTML, not an APK. Received a webpage instead of the APK file.';
              debugPrint(errorMsg);
              // Save the HTML content for debugging
              await io.File('${file.parent.path}/error_response.html').writeAsString(await file.readAsString());
              debugPrint('Saved HTML response to ${file.parent.path}/error_response.html for debugging');
              isUpdateInProgress = false;
              onError(errorMsg);
              return;
            }
            
            if (!isZipFile) {
              final errorMsg = 'Downloaded file is not a valid APK (ZIP) file.';
              debugPrint(errorMsg);
              isUpdateInProgress = false;
              onError(errorMsg);
              return;
            }
            
            debugPrint('APK file downloaded successfully and validated');
            
            // Just notify the user where the file was saved without trying to install
            if (isAndroid) {
              debugPrint('Download completed successfully');
              isUpdateInProgress = false;
              
              // Show message with file path
              onComplete('Update downloaded successfully to: $savePath\n\nYou can find the APK file in your Downloads folder.');
            } else {
              // On iOS or other platforms, share the file
              debugPrint('Download successful, sharing file on non-Android platform');
              await Share.shareXFiles([XFile(savePath)], text: 'Install $appName update');
              isUpdateInProgress = false;
              onComplete('Update downloaded. Please install the shared file.');
            }
          } else {
            final errorMsg = 'File was not created';
            debugPrint(errorMsg);
            isUpdateInProgress = false;
            onError(errorMsg);
            return;
          }
        } finally {
          client.close();
        }
      } catch (e) {
        final errorMsg = 'Network error during download: $e';
        debugPrint(errorMsg);
        isUpdateInProgress = false;
        onError(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Error downloading update: $e';
      debugPrint(errorMsg);
      isUpdateInProgress = false;
      onError(errorMsg);
    }
  }
  
  // Install the APK (Android only)
  static Future<void> installApk(String filePath) async {
    try {
      debugPrint('Installing APK from: $filePath');
      final file = io.File(filePath);
      
      if (await file.exists()) {
        debugPrint('APK file exists, proceeding with installation');
        
        // For Android, we need to use multiple approaches
        if (isAndroid) {
          // First try the most reliable approach - just share the file
          try {
            debugPrint('Trying to share the APK file for installation...');
            final result = await Share.shareXFiles(
              [XFile(filePath, mimeType: 'application/vnd.android.package-archive')], 
              text: 'Install $appName update',
            );
            debugPrint('Share result: $result');
            return;
          } catch (e) {
            debugPrint('Failed to share APK: $e. Trying direct installation methods...');
          }
          
          // Try using direct intent with MIME type
          try {
            final uri = Uri.file(filePath);
            debugPrint('Attempting to launch file directly with: $uri');
            
            if (await canLaunchUrl(uri)) {
              debugPrint('Launching with file URI...');
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              return;
            }
          } catch (e) {
            debugPrint('Error launching file URI: $e');
          }
          
          // Try using content URI as fallback
          try {
            final contentUri = Uri.parse('content://$filePath');
            debugPrint('Trying content URI: $contentUri');
            
            if (await canLaunchUrl(contentUri)) {
              await launchUrl(
                contentUri,
                mode: LaunchMode.externalApplication,
              );
              debugPrint('Launched with content URI');
              return;
            }
          } catch (e) {
            debugPrint('Error with content URI: $e');
          }
          
          // Final fallback - try opening with platform default
          try {
            debugPrint('Trying platform default opener...');
            await launchUrl(
              Uri.file(filePath),
              mode: LaunchMode.platformDefault,
            );
            return;
          } catch (e) {
            debugPrint('Failed with platform default: $e');
          }
          
          throw 'All installation methods failed. The APK is downloaded at: $filePath - please open it manually from your file manager.';
        } else {
          // For other platforms, try to open file
          if (await canLaunchUrl(Uri.file(filePath))) {
            await launchUrl(Uri.file(filePath), mode: LaunchMode.externalApplication);
            debugPrint('File opened for installation');
          } else {
            throw 'Could not launch $filePath';
          }
        }
      } else {
        debugPrint('APK file not found at: $filePath');
        throw 'APK file not found. Please try downloading again.';
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
      throw 'Error installing APK: $e';
    }
  }
  
  // For testing: Direct URL download method
  static Future<Map<String, dynamic>> useDirectApkUrl(String directApkUrl, String latestVersion) async {
    await initialize();
    
    final bool hasUpdate = _isNewerVersion(latestVersion, currentVersion);
    latestApkUrl = directApkUrl;
    
    return {
      'hasUpdate': hasUpdate,
      'latestVersion': latestVersion,
      'currentVersion': currentVersion,
      'releaseNotes': 'Update to the latest version of $appName',
      'downloadUrl': directApkUrl,
    };
  }
  
  // Try to download larger files using external browser
  static Future<bool> downloadWithBrowser(String url) async {
    try {
      debugPrint('Trying to download with external browser: $url');
      
      // For Dropbox URLs, ensure we have the direct download link
      if (url.contains('dropbox.com')) {
        url = _getProperDropboxUrl(url);
        debugPrint('Using modified Dropbox URL: $url');
      }
      
      // Launch URL in external browser
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('Successfully launched browser for download');
        return true;
      } else {
        debugPrint('Could not launch URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error launching browser for download: $e');
      return false;
    }
  }
  
  // Helper to check and request all required update permissions
  static Future<bool> checkAndRequestUpdatePermissions(BuildContext context) async {
    try {
      debugPrint('Checking all required permissions for app updates');
      
      // We need ALL_FILES_ACCESS permission for Android 11+
      // and regular storage permission for older versions
      final hasPermission = await StoragePermissionHandler.hasStoragePermission();
      
      if (hasPermission) {
        debugPrint('Already have required permissions for updates');
        return true;
      }
      
      // Request permissions with UI flow
      debugPrint('Requesting required permissions for updates');
      final permissionGranted = await StoragePermissionHandler.showAllFilesAccessDialog(context);
      
      return permissionGranted;
    } catch (e) {
      debugPrint('Error checking update permissions: $e');
      return false;
    }
  }
  
  // Open the device's Downloads folder
  static Future<bool> openDownloadsFolder() async {
    try {
      if (isAndroid) {
        debugPrint('Attempting to open Downloads folder in file manager');
        
        // Try to directly open file manager first with specific path for different manufacturers
        final List<Map<String, String>> fileManagerIntents = [
          // ColorOS/Realme/OPPO file manager
          {'package': 'com.coloros.filemanager', 'activity': '.FileManagerActivity'},
          {'package': 'com.oppo.filemanager', 'activity': '.FileManagerActivity'},
          {'package': 'com.realme.filemanager', 'activity': '.FileManagerActivity'},
          
          // Samsung file manager
          {'package': 'com.sec.android.app.myfiles', 'activity': '.common.MainActivity'},
          
          // Xiaomi file manager
          {'package': 'com.mi.android.globalFileexplorer', 'activity': '.FileExplorerTabActivity'},
          
          // Google Files app
          {'package': 'com.google.android.apps.nbu.files', 'activity': '.home.HomeActivity'},
          
          // Common file managers
          {'package': 'com.android.documentsui', 'activity': '.files.FilesActivity'},
          {'package': 'com.google.android.documentsui', 'activity': '.files.FilesActivity'},
        ];
        
        for (final fileManager in fileManagerIntents) {
          try {
            final packageName = fileManager['package']!;
            final activityName = fileManager['activity']!;
            final intentUri = Uri.parse('intent:#Intent;component=$packageName$activityName;end');
            
            if (await canLaunchUrl(intentUri)) {
              final bool result = await launchUrl(
                intentUri,
                mode: LaunchMode.externalApplication,
              );
              if (result) {
                debugPrint('Opened file manager directly: $packageName');
                return true;
              }
            }
          } catch (e) {
            debugPrint('Error opening file manager: $e');
          }
        }
        
        // Try using the open_file_manager package with 'other' folder type
        // which is more likely to open the actual file manager
        try {
          await openFileManager(
            androidConfig: AndroidConfig(
              folderType: AndroidFolderType.other,
              folderPath: '/storage/emulated/0/Download',
            ),
          );
          debugPrint('Opened file manager with specific Download path');
          return true;
        } catch (e) {
          debugPrint('Error opening specific Downloads path: $e');
          // Continue with fallback methods
        }
        
        // Try with standard methods that might open the file manager
        final List<Uri> fileManagerUris = [
          // Generic file explorer with primary storage
          Uri.parse('content://com.android.externalstorage.documents/root/primary'),
          
          // Documents provider with downloads path
          Uri.parse('content://com.android.externalstorage.documents/document/primary%3ADownload'),
          
          // File path to Downloads
          Uri.parse('file:///storage/emulated/0/Download'),
          
          // Alternative content URI
          Uri.parse('content://com.android.providers.media.documents/root/downloads'),
        ];
        
        for (final uri in fileManagerUris) {
          try {
            if (await canLaunchUrl(uri)) {
              final bool result = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (result) {
                debugPrint('Opened file manager using URI: $uri');
                return true;
              }
            }
          } catch (e) {
            debugPrint('Error with URI $uri: $e');
          }
        }
        
        // Try with ACTION_VIEW intent for directory mimetype
        try {
          final Uri uri = Uri.parse('content://com.android.externalstorage.documents/document/primary%3ADownload');
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            debugPrint('Opened file manager using document provider URI');
            return true;
          }
        } catch (e) {
          debugPrint('Error with document URI: $e');
        }
        
        // As a last resort, try to find a file manager in the Play Store
        try {
          final Uri marketUri = Uri.parse('market://search?q=file+manager&c=apps');
          if (await canLaunchUrl(marketUri)) {
            debugPrint('No file manager found, could open Play Store to install one');
            // We don't actually launch this automatically,
            // but could guide the user to install a file manager if needed
          }
        } catch (e) {
          debugPrint('Error checking for file manager in Play Store: $e');
        }
        
        debugPrint('All methods to open file manager failed');
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error opening Downloads folder: $e');
      return false;
    }
  }
  
  // Get a direct download URL for the APK
  static String getDirectDownloadUrl(String url) {
    if (url.isEmpty) return '';
    return _getProperDropboxUrl(url);
  }
  
  // Open Android settings for "All Files Access" permission
  static Future<bool> openAllFilesAccessSettings() async {
    try {
      if (isAndroid) {
        // For Android 11+ (API 30+), open the "All Files Access" permission screen directly if possible
        debugPrint('Opening All Files Access settings');
        
        // First try using the direct action if available
        if (await Permission.manageExternalStorage.status.isPermanentlyDenied) {
          return await openAppSettings();
        }
        
        // Alternative approach using intent
        const action = 'android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION';
        final packageName = 'com.codematesolution.bloodline';
        final uri = Uri.parse('package:$packageName');
        
        if (await canLaunchUrl(uri)) {
          return await launchUrl(
            uri, 
            mode: LaunchMode.externalApplication,
          );
        } else {
          // Fallback to regular app settings
          return await openAppSettings();
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error opening All Files Access settings: $e');
      // Fallback to regular app settings as a last resort
      try {
        return await openAppSettings();
      } catch (_) {
        return false;
      }
    }
  }
} 