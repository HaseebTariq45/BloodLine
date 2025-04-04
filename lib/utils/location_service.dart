import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _locationEnabledKey = 'location_enabled';
  
  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  
  // Factory constructor
  factory LocationService() => _instance;
  
  // Private constructor
  LocationService._internal();
  
  // Get current location permission status
  Future<bool> isLocationEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool userPref = prefs.getBool(_locationEnabledKey) ?? false;
    
    // If user preference is false, return false without checking system settings
    if (!userPref) return false;
    
    // Check if location services are enabled at the system level
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    
    // Check permission status
    PermissionStatus status = await Permission.location.status;
    return status.isGranted;
  }
  
  // Set user preference for location services
  Future<void> setLocationEnabled(bool enabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, enabled);
  }
  
  // Request location permission
  Future<bool> requestLocationPermission() async {
    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    // Request permission
    PermissionStatus status = await Permission.location.request();
    
    // If granted, save preference
    if (status.isGranted) {
      await setLocationEnabled(true);
    }
    
    return status.isGranted;
  }
  
  // Disable location services in app
  Future<void> disableLocation() async {
    await setLocationEnabled(false);
  }
  
  // Get current position
  Future<Position?> getCurrentPosition() async {
    bool enabled = await isLocationEnabled();
    if (!enabled) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  
  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
  
  // Open app settings
  Future<bool> openApplicationSettings() async {
    return await openAppSettings();
  }
} 