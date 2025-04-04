import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Utility class for safely accessing environment variables
class EnvUtils {
  /// Get a string value from environment variables with a fallback
  static String getString(String key, {String defaultValue = ''}) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Get the Google Maps API key
  static String get googleMapsApiKey => 
    getString('GOOGLE_MAPS_API_KEY', defaultValue: 'YOUR_API_KEY_HERE');
    
  /// Get the API base URL
  static String get apiBaseUrl => 
    getString('API_BASE_URL', defaultValue: 'https://example-api.com/v1');
} 