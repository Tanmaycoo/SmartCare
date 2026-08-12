import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare/core/api_config.dart';

/// AuthService handles all backend communication for authentication,
/// JWT token management, and user session persistence.
class AuthService {
  /// Centralized API Base URL
  static String get baseUrl => ApiConfig.baseUrl;

  /// Timeout set to 45s to handle Render free-tier instance cold starts
  static const Duration _requestTimeout = Duration(seconds: 45);

  static const String _tokenKey = 'smartcare_jwt_token';
  static const String _userKey = 'smartcare_user_data';

  static Map<String, dynamic> _decodeJsonMap(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Fall through to the generic response error handling
    }

    return <String, dynamic>{'detail': 'Unexpected response format'};
  }

  static String _extractErrorMessage(
    http.Response response,
    Map<String, dynamic> data,
    String fallback,
  ) {
    if (response.statusCode == 401) {
      return 'Invalid email or password.';
    }
    if (response.statusCode == 404) {
      return 'Requested server endpoint was not found (404).';
    }
    if (response.statusCode >= 500) {
      return 'Server error (${response.statusCode}). Please try again later.';
    }

    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail != null) return detail.toString();
    return fallback;
  }

  static Map<String, dynamic> _handleNetworkException(
    dynamic error,
    String action,
  ) {
    if (kDebugMode) {
      debugPrint('[AuthService] Network error during $action: $error');
    }
    if (error is TimeoutException) {
      return {
        'success': false,
        'error':
            'Server is taking longer than expected to respond (Render cold start). Please try again in a moment.',
      };
    }
    return {
      'success': false,
      'error':
          'Unable to connect to SmartCare server. Please check your internet connection.',
    };
  }

  // ---------- Token & Session Persistence ----------

  /// Save JWT token to local storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get saved JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save user data as JSON string
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  /// Get saved user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear all auth data (logout)
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ---------- API Calls ----------

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[AuthService] POST $baseUrl/auth/register');
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'full_name': fullName,
              'phone': phone,
              'role': role,
            }),
          )
          .timeout(_requestTimeout);

      if (kDebugMode) {
        debugPrint(
          '[AuthService] POST /auth/register status: ${response.statusCode}',
        );
      }

      final data = _decodeJsonMap(response);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error': _extractErrorMessage(response, data, 'Registration failed'),
      };
    } catch (e) {
      return _handleNetworkException(e, 'registration');
    }
  }

  /// Login and receive JWT token
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[AuthService] POST $baseUrl/auth/login');
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

      if (kDebugMode) {
        debugPrint(
          '[AuthService] POST /auth/login status: ${response.statusCode}',
        );
      }

      final data = _decodeJsonMap(response);
      if (response.statusCode == 200) {
        final accessToken = data['access_token'];
        if (accessToken is! String || accessToken.isEmpty) {
          return {
            'success': false,
            'error': 'Login response did not include an access token',
          };
        }

        await saveToken(accessToken);
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error': _extractErrorMessage(response, data, 'Login failed'),
      };
    } catch (e) {
      return _handleNetworkException(e, 'sign in');
    }
  }

  /// Get current user profile using saved JWT token
  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      if (kDebugMode) {
        debugPrint('[AuthService] GET $baseUrl/auth/me');
      }
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

      if (kDebugMode) {
        debugPrint(
          '[AuthService] GET /auth/me status: ${response.statusCode}',
        );
      }

      final data = _decodeJsonMap(response);
      if (response.statusCode == 200) {
        await saveUserData(data);
        return {'success': true, 'data': data};
      }

      if (response.statusCode == 401) {
        await clearAuth();
      }

      return {
        'success': false,
        'error': _extractErrorMessage(
          response,
          data,
          'Failed to fetch profile',
        ),
      };
    } catch (e) {
      return _handleNetworkException(e, 'profile retrieval');
    }
  }
}
