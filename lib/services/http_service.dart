import 'dart:convert';
import 'package:http/http.dart' as http;
import 'service_locator.dart';

/// A service that handles all HTTP requests
/// and integrates with the network tracker for data usage monitoring
class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  
  HttpService._internal();
  
  /// Make a GET request and track data usage
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final uri = Uri.parse(url);
    return serviceLocator.networkTracker.get(uri, headers: headers);
  }
  
  /// Make a POST request and track data usage
  Future<http.Response> post(
    String url, 
    {Map<String, String>? headers, dynamic body}
  ) async {
    final uri = Uri.parse(url);
    
    // Convert body to JSON if it's a Map
    Object? encodedBody = body;
    if (body is Map) {
      encodedBody = jsonEncode(body);
      headers = {
        ...?headers,
        'Content-Type': 'application/json',
      };
    }
    
    return serviceLocator.networkTracker.post(
      uri, 
      headers: headers, 
      body: encodedBody
    );
  }
  
  /// Make a PUT request and track data usage
  Future<http.Response> put(
    String url, 
    {Map<String, String>? headers, dynamic body}
  ) async {
    final uri = Uri.parse(url);
    
    // First get the original resource to track data usage for the GET
    await serviceLocator.networkTracker.get(uri, headers: headers);
    
    // Convert body to JSON if it's a Map
    Object? encodedBody = body;
    if (body is Map) {
      encodedBody = jsonEncode(body);
      headers = {
        ...?headers,
        'Content-Type': 'application/json',
      };
    }
    
    // Then use the standard http client but track the request manually
    final response = await http.put(uri, headers: headers, body: encodedBody);
    
    // Calculate and track data usage
    int bytesUsed = response.bodyBytes.length;
    
    if (body is String) {
      bytesUsed += body.length;
    } else if (body is List<int>) {
      bytesUsed += body.length;
    } else if (encodedBody is String) {
      bytesUsed += encodedBody.length;
    }
    
    // Add headers to byte count (approximate)
    bytesUsed += uri.toString().length;
    headers?.forEach((key, value) {
      bytesUsed += key.length + value.length + 4;
    });
    
    response.headers.forEach((key, value) {
      bytesUsed += key.length + value.length + 4;
    });
    
    // Determine connection type and record usage
    serviceLocator.networkTracker.trackManualUsage(bytesUsed);
    
    return response;
  }
  
  /// Make a DELETE request and track data usage
  Future<http.Response> delete(
    String url, 
    {Map<String, String>? headers}
  ) async {
    final uri = Uri.parse(url);
    
    // First get the original resource to track data usage for the GET
    await serviceLocator.networkTracker.get(uri, headers: headers);
    
    // Then use the standard http client but track manually
    final response = await http.delete(uri, headers: headers);
    
    // Calculate and track data usage
    int bytesUsed = response.bodyBytes.length;
    
    // Add headers to byte count (approximate)
    bytesUsed += uri.toString().length;
    headers?.forEach((key, value) {
      bytesUsed += key.length + value.length + 4;
    });
    
    response.headers.forEach((key, value) {
      bytesUsed += key.length + value.length + 4;
    });
    
    // Record usage
    serviceLocator.networkTracker.trackManualUsage(bytesUsed);
    
    return response;
  }
}

// Global instance for easy access
final httpService = HttpService(); 