import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smartcare/core/auth_service.dart';
import 'package:smartcare/core/api_config.dart';

/// HospitalService handles API communication for Hospital Management.
class HospitalService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  static Future<String?> _getToken() => AuthService.getToken();

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _handleError(dynamic e, String action) {
    if (kDebugMode) debugPrint('[HospitalService] $action error: $e');
    if (e is TimeoutException) {
      return {'success': false, 'error': 'Request timed out. Please try again.'};
    }
    return {'success': false, 'error': 'Network error during $action.'};
  }

  static String _extractError(dynamic body, String fallback) {
    try {
      if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['detail'] != null) {
          return decoded['detail'].toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  // ── Hospital CRUD ─────────────────────────────────────────────────────────

  /// Get list of hospitals for the current user (role-filtered by backend)
  static Future<Map<String, dynamic>> getHospitals({
    String? verificationStatus,
    String? hospitalStatus,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    final queryParams = <String, String>{};
    if (verificationStatus != null) {
      queryParams['verification_status'] = verificationStatus;
    }
    if (hospitalStatus != null) queryParams['status'] = hospitalStatus;

    final uri = Uri.parse('$baseUrl/hospitals')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http
          .get(uri, headers: _authHeaders(token))
          .timeout(_timeout);
      if (kDebugMode) {
        debugPrint('[HospitalService] GET /hospitals → ${response.statusCode}');
      }
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to fetch hospitals'),
      };
    } catch (e) {
      return _handleError(e, 'getHospitals');
    }
  }

  /// Get a single hospital by ID
  static Future<Map<String, dynamic>> getHospital(int hospitalId) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/hospitals/$hospitalId'),
              headers: _authHeaders(token))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to fetch hospital'),
      };
    } catch (e) {
      return _handleError(e, 'getHospital');
    }
  }

  /// Register / create a new hospital
  /// HOSPITAL_STAFF, HOSPITAL_ADMIN, and SYSTEM_ADMIN can call this.
  static Future<Map<String, dynamic>> createHospital({
    required String name,
    required String address,
    required String city,
    required String state,
    required String postalCode,
    required String phone,
    required String email,
    required double latitude,
    required double longitude,
    required bool emergencyAvailable,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/hospitals'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'name': name,
              'address': address,
              'city': city,
              'state': state,
              'postal_code': postalCode,
              'phone': phone,
              'email': email,
              'latitude': latitude,
              'longitude': longitude,
              'emergency_available': emergencyAvailable,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to create hospital'),
      };
    } catch (e) {
      return _handleError(e, 'createHospital');
    }
  }

  /// Update hospital information
  static Future<Map<String, dynamic>> updateHospital(
    int hospitalId,
    Map<String, dynamic> updateData,
  ) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/hospitals/$hospitalId'),
            headers: _authHeaders(token),
            body: jsonEncode(updateData),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to update hospital'),
      };
    } catch (e) {
      return _handleError(e, 'updateHospital');
    }
  }

  // ── Admin: Hospital Approval Workflow ─────────────────────────────────────

  /// SYSTEM_ADMIN: Get all pending hospitals
  static Future<Map<String, dynamic>> getPendingHospitals() async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/hospitals/pending'),
              headers: _authHeaders(token))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to fetch pending hospitals'),
      };
    } catch (e) {
      return _handleError(e, 'getPendingHospitals');
    }
  }

  /// SYSTEM_ADMIN: Get all hospitals (any status)
  static Future<Map<String, dynamic>> getAllHospitalsAdmin() async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/hospitals'),
              headers: _authHeaders(token))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to fetch hospitals'),
      };
    } catch (e) {
      return _handleError(e, 'getAllHospitalsAdmin');
    }
  }

  /// SYSTEM_ADMIN: Approve a hospital
  static Future<Map<String, dynamic>> approveHospital(int hospitalId) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/hospitals/$hospitalId/approve'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to approve hospital'),
      };
    } catch (e) {
      return _handleError(e, 'approveHospital');
    }
  }

  /// SYSTEM_ADMIN: Reject a hospital with optional reason
  static Future<Map<String, dynamic>> rejectHospital(
    int hospitalId, {
    String? reason,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/hospitals/$hospitalId/reject'),
            headers: _authHeaders(token),
            body: jsonEncode({'rejection_reason': reason}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to reject hospital'),
      };
    } catch (e) {
      return _handleError(e, 'rejectHospital');
    }
  }

  /// SYSTEM_ADMIN: Activate a hospital
  static Future<Map<String, dynamic>> activateHospital(int hospitalId) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/hospitals/$hospitalId/activate'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to activate hospital'),
      };
    } catch (e) {
      return _handleError(e, 'activateHospital');
    }
  }

  /// SYSTEM_ADMIN: Deactivate (suspend) a hospital
  static Future<Map<String, dynamic>> deactivateHospital(int hospitalId) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/hospitals/$hospitalId/deactivate'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to deactivate hospital'),
      };
    } catch (e) {
      return _handleError(e, 'deactivateHospital');
    }
  }

  // ── Beds ──────────────────────────────────────────────────────────────────

  /// Get beds for a hospital (all wards)
  static Future<Map<String, dynamic>> getHospitalBeds(
    int hospitalId, {
    String? status,
    int? wardId,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (wardId != null) params['ward_id'] = wardId.toString();

    final uri = Uri.parse('$baseUrl/hospitals/$hospitalId/beds')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    try {
      final response = await http
          .get(uri, headers: _authHeaders(token))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to fetch beds'),
      };
    } catch (e) {
      return _handleError(e, 'getHospitalBeds');
    }
  }

  /// Update bed status
  static Future<Map<String, dynamic>> updateBedStatus(
    int bedId,
    String newStatus, {
    String? notes,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/beds/$bedId/status'),
            headers: _authHeaders(token),
            body: jsonEncode({'status': newStatus, 'notes': notes}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to update bed status'),
      };
    } catch (e) {
      return _handleError(e, 'updateBedStatus');
    }
  }

  // ── Legacy / Backward Compatibility Methods ───────────────────────────────

  /// Legacy support for SystemAdminHospitalScreen
  static Future<Map<String, dynamic>> verifyHospital(
    int hospitalId,
    String verificationStatus,
  ) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/hospitals/$hospitalId/verify'),
            headers: _authHeaders(token),
            body: jsonEncode({'verification_status': verificationStatus}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to verify hospital'),
      };
    } catch (e) {
      return _handleError(e, 'verifyHospital');
    }
  }

  /// Legacy support for SystemAdminHospitalScreen
  static Future<Map<String, dynamic>> suspendHospital(int hospitalId) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'error': 'Not authenticated'};

    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/hospitals/$hospitalId/suspend'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': _extractError(response.body, 'Failed to suspend hospital'),
      };
    } catch (e) {
      return _handleError(e, 'suspendHospital');
    }
  }
}
