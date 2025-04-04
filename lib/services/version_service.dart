import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A service that manages the app version information
class VersionService {
  // Singleton pattern
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  // App version details
  String _appVersion = '1.0.0'; // Default version
  String _buildNumber = '1';
  String _packageName = '';
  String _appName = '';

  // Getters
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;
  String get packageName => _packageName;
  String get appName => _appName;
  
  // Full version with build number
  String get fullVersion => '$_appVersion+$_buildNumber';

  /// Initialize the version service by reading from package info
  Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      _appVersion = packageInfo.version.isNotEmpty 
          ? packageInfo.version 
          : '1.0.0'; // Default if empty
          
      _buildNumber = packageInfo.buildNumber.isNotEmpty
          ? packageInfo.buildNumber
          : '1'; // Default if empty
          
      _packageName = packageInfo.packageName;
      _appName = packageInfo.appName;
      
      debugPrint('VersionService initialized: v$_appVersion+$_buildNumber');
    } catch (e) {
      debugPrint('Error initializing VersionService: $e');
      // Keep default values if there's an error
    }
  }
}

// Global instance for easy access
final versionService = VersionService(); 