import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService handles all backend communication for authentication,
/// JWT token management, and user session persistence.
class AuthService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'SMARTCARE_API_BASE_URL',
  );
  static const Duration _requestTimeout = Duration(seconds: 8);

  // Override with:
  // flutter run --dart-define=SMARTCARE_API_BASE_URL=http://<your-local-ip>:8000
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const String _tokenKey = 'smartcare_jwt_token';
  static const String _userKey = 'smartcare_user_data';

  static Map<String, dynamic> _decodeJsonMap(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Fall through to the generic response error below.
    }

    return <String, dynamic>{'detail': 'Unexpected server response'};
  }

  static String _errorFrom(Map<String, dynamic> data, String fallback) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail != null) return detail.toString();
    return fallback;
  }

  static Map<String, dynamic> _connectionFailure(String action) {
    return {
      'success': false,
      'error':
          'Unable to $action. Check that the backend is running and reachable.',
    };
  }

  // ---------- Token Management ----------

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

      final data = _decodeJsonMap(response);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error': _errorFrom(data, 'Registration failed'),
      };
    } on TimeoutException {
      return _connectionFailure('register');
    } catch (_) {
      return _connectionFailure('register');
    }
  }

  /// Login and receive JWT token
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

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

      return {'success': false, 'error': _errorFrom(data, 'Login failed')};
    } on TimeoutException {
      return _connectionFailure('sign in');
    } catch (_) {
      return _connectionFailure('sign in');
    }
  }

  /// Get current user profile using saved JWT token
  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_requestTimeout);

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
        'error': _errorFrom(data, 'Failed to fetch profile'),
      };
    } on TimeoutException {
      return _connectionFailure('check your saved session');
    } catch (_) {
      return _connectionFailure('check your saved session');
    }
  }
}
