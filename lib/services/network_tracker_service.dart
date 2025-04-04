import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/app_provider.dart';

/// A service that tracks network usage by intercepting HTTP requests
class NetworkTrackerService {
  final AppProvider appProvider;
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _lastConnectivityResult = ConnectivityResult.none;
  bool _connectivityAvailable = true;

  NetworkTrackerService(this.appProvider) {
    // Initialize connectivity monitoring
    _initConnectivity();
  }

  // Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      // Check if we're on a platform where connectivity_plus is fully supported
      if (!kIsWeb &&
          (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        _lastConnectivityResult = await _connectivity.checkConnectivity();

        // Listen for connectivity changes
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
          _lastConnectivityResult = result;
        });
      } else {
        // On platforms where connectivity checking might not be supported (like Windows)
        _connectivityAvailable = false;
        debugPrint(
          'Connectivity monitoring not fully supported on this platform. Will assume WiFi connection.',
        );
      }
    } catch (e) {
      _connectivityAvailable = false;
      debugPrint('Could not initialize connectivity monitoring: $e');
      debugPrint('Will assume WiFi connection for data usage tracking.');
    }
  }

  // Check if connection is WiFi
  Future<bool> _isWifiConnection() async {
    // If connectivity checking is not available, assume WiFi
    if (!_connectivityAvailable) {
      return true;
    }

    try {
      // If we already have a stored result, use it
      if (_lastConnectivityResult != ConnectivityResult.none) {
        return _lastConnectivityResult == ConnectivityResult.wifi;
      }

      // Otherwise check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _lastConnectivityResult = connectivityResult;
      return connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      // Default to WiFi if we can't determine
      return true;
    }
  }

  /// Track data usage manually
  Future<void> trackManualUsage(int bytesUsed) async {
    final isWifi = await _isWifiConnection();
    appProvider.recordDataUsage(bytesUsed, isWifi);
  }

  /// Get the latest data from shared preferences
  Future<void> refreshDataUsage() async {
    await appProvider.refreshDataUsage();
  }

  /// Custom HTTP client that tracks data usage
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    // Check if WiFi or mobile before making the request
    final isWifi = await _isWifiConnection();

    // Make the request and track response size
    final response = await http.get(url, headers: headers);

    // Calculate bytes used (headers + body)
    int bytesUsed = 0;

    // Add response body size
    bytesUsed += response.bodyBytes.length;

    // Add approximate header size
    response.headers.forEach((key, value) {
      bytesUsed += key.length + value.length + 4; // +4 for ': ' and '\r\n'
    });

    // Add request URL and headers size (approximate)
    bytesUsed += url.toString().length;
    headers?.forEach((key, value) {
      bytesUsed += key.length + value.length + 4;
    });

    // Record the usage in the provider
    appProvider.recordDataUsage(bytesUsed, isWifi);

    return response;
  }

  /// Custom HTTP client for POST requests that tracks data usage
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    // Check if WiFi or mobile before making the request
    final isWifi = await _isWifiConnection();

    // Calculate request body size
    int requestSize = 0;
    if (body is String) {
      requestSize = body.length;
    } else if (body is List<int>) {
      requestSize = body.length;
    }

    // Make the request
    final response = await http.post(url, headers: headers, body: body);

    // Calculate total bytes used
    int bytesUsed = requestSize + response.bodyBytes.length;

    // Add approximate header sizes
    response.headers.forEach((key, value) {
      bytesUsed += key.length + value.length + 4;
    });

    headers?.forEach((key, value) {
      bytesUsed += key.length + value.length + 4;
    });

    // Add request URL size
    bytesUsed += url.toString().length;

    // Record the usage in the provider
    appProvider.recordDataUsage(bytesUsed, isWifi);

    return response;
  }
}
