import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartcare/core/auth_service.dart';

/// HospitalService handles API communication for Hospital Management (Phase 4).
class HospitalService {
  static String get baseUrl => AuthService.baseUrl;

  /// Get list of hospitals authorized for the current user
  static Future<Map<String, dynamic>> getHospitals({
    String? verificationStatus,
    String? status,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    final queryParams = <String, String>{};
    if (verificationStatus != null) {
      queryParams['verification_status'] = verificationStatus;
    }
    if (status != null) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(
      '$baseUrl/hospitals',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to fetch hospitals',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Get details of a single hospital
  static Future<Map<String, dynamic>> getHospital(int hospitalId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hospitals/$hospitalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to fetch hospital details',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Create / register a new hospital (HOSPITAL_ADMIN / SYSTEM_ADMIN)
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
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hospitals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to create hospital',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Update hospital information (HOSPITAL_ADMIN / SYSTEM_ADMIN)
  static Future<Map<String, dynamic>> updateHospital(
    int hospitalId,
    Map<String, dynamic> updateData,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/hospitals/$hospitalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to update hospital',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Verify (Approve / Reject) a hospital (SYSTEM_ADMIN)
  static Future<Map<String, dynamic>> verifyHospital(
    int hospitalId,
    String verificationStatus,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/hospitals/$hospitalId/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'verification_status': verificationStatus}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to verify hospital',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Activate a hospital (SYSTEM_ADMIN)
  static Future<Map<String, dynamic>> activateHospital(int hospitalId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/hospitals/$hospitalId/activate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to activate hospital',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Suspend a hospital (SYSTEM_ADMIN)
  static Future<Map<String, dynamic>> suspendHospital(int hospitalId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/hospitals/$hospitalId/suspend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to suspend hospital',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  /// Delete/Deactivate a hospital (SYSTEM_ADMIN)
  static Future<Map<String, dynamic>> deleteHospital(int hospitalId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/hospitals/$hospitalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['detail'] ?? 'Failed to delete hospital',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }
}
