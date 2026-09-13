import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Custom exception for API errors with user-friendly messages.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Centralized API client for communicating with the FastAPI backend.
/// Designed with timeouts, JWT injection, and graceful failure handling.
class ApiClient {
  final http.Client _httpClient;
  String? _authToken;

  ApiClient({http.Client? httpClient, String? authToken})
      : _httpClient = httpClient ?? http.Client(),
        _authToken = authToken;

  /// Returns the currently active authentication token, if any.
  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Perform a GET request.
  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final combinedHeaders = _buildHeaders()..addAll(headers ?? {});
      final response = await _httpClient
          .get(Uri.parse(url), headers: combinedHeaders)
          .timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check your connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiClient GET Error: $e');
      throw ApiException('Unable to connect to server: ${e.toString()}');
    }
  }

  /// Perform a POST request.
  Future<dynamic> post(String url, {dynamic body, Map<String, String>? headers}) async {
    try {
      final combinedHeaders = _buildHeaders()..addAll(headers ?? {});
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _httpClient
          .post(Uri.parse(url), headers: combinedHeaders, body: encodedBody)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check your connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiClient POST Error: $e');
      throw ApiException('Unable to connect to server: ${e.toString()}');
    }
  }

  /// Perform a PATCH request.
  Future<dynamic> patch(String url, {dynamic body, Map<String, String>? headers}) async {
    try {
      final combinedHeaders = _buildHeaders()..addAll(headers ?? {});
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _httpClient
          .patch(Uri.parse(url), headers: combinedHeaders, body: encodedBody)
          .timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out. Please check your connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiClient PATCH Error: $e');
      throw ApiException('Unable to connect to server: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        return response.body;
      }
    } else {
      String errorMessage = 'Server error (${response.statusCode})';
      try {
        final bodyJson = jsonDecode(utf8.decode(response.bodyBytes));
        if (bodyJson is Map && bodyJson.containsKey('detail')) {
          errorMessage = bodyJson['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  void close() {
    _httpClient.close();
  }
}
