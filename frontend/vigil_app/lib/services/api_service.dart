import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// API service for communicating with the Django backend.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configuration
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // static const String _baseUrl = 'http://localhost:8000/api'; // iOS simulator
  
  String? _accessToken;
  String? _refreshToken;

  // Headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Set auth tokens after login
  void setTokens({required String access, required String refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  /// Clear tokens on logout
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  bool get isAuthenticated => _accessToken != null;

  // === AUTH ===

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setTokens(
          access: data['tokens']['access'],
          refresh: data['tokens']['refresh'],
        );
        return data;
      }
      debugPrint('[Vigil API] Login failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[Vigil API] Login error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> register({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirm': password,
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setTokens(
          access: data['tokens']['access'],
          refresh: data['tokens']['refresh'],
        );
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('[Vigil API] Register error: $e');
      return null;
    }
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // === PROFILE & SETTINGS ===

  Future<Map<String, dynamic>?> getProfile() async {
    return _get('/auth/profile/');
  }

  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    final response = await _patch('/auth/settings/', settings);
    return response != null;
  }

  // === EMERGENCY CONTACTS ===

  Future<List<dynamic>> getContacts() async {
    final data = await _get('/contacts/');
    if (data != null && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>?> addContact(Map<String, dynamic> contact) async {
    return _post('/contacts/', contact);
  }

  Future<bool> deleteContact(int id) async {
    return _delete('/contacts/$id/');
  }

  // === ALERTS ===

  Future<int?> createAlert({
    required String triggerType,
    double? latitude,
    double? longitude,
    double? proximityValue,
    double? lightValue,
  }) async {
    final data = await _post('/alerts/', {
      'trigger_type': triggerType,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (proximityValue != null) 'proximity_value': proximityValue,
      if (lightValue != null) 'light_value': lightValue,
    });
    return data?['id'] as int?;
  }

  Future<bool> acknowledgeAlert(int alertId) async {
    final response = await _post('/alerts/$alertId/acknowledge/', {});
    return response != null;
  }

  Future<bool> resolveAlert(int alertId) async {
    final response = await _post('/alerts/$alertId/resolve/', {});
    return response != null;
  }

  Future<bool> uploadAlertPhoto({
    required int alertId,
    required File photoFile,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/alerts/$alertId/upload_photo/');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_accessToken';
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );
      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[Vigil API] Photo upload error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getAlertHistory() async {
    final data = await _get('/alerts/history/');
    if (data is List) return data;
    if (data != null && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<List<dynamic>> getActiveAlerts() async {
    final data = await _get('/alerts/active/');
    if (data is List) return data;
    return [];
  }

  // === LOCATION ===

  Future<bool> updateLocation(Map<String, dynamic> locationData) async {
    final response = await _post('/location/update/', locationData);
    return response != null;
  }

  Future<bool> bulkLocationUpdate(List<Map<String, dynamic>> locations) async {
    final response = await _post('/location/bulk/', {'locations': locations});
    return response != null;
  }

  // === DASHBOARD ===

  Future<Map<String, dynamic>?> getDashboard() async {
    return _get('/dashboard/');
  }

  // === PRIVATE HTTP HELPERS ===

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (response.statusCode == 401) {
        if (await refreshAccessToken()) {
          return _get(path); // Retry
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Vigil API] GET $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      if (response.statusCode == 401) {
        if (await refreshAccessToken()) {
          return _post(path, body);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Vigil API] POST $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _patch(
      String path, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (response.statusCode == 401) {
        if (await refreshAccessToken()) {
          return _patch(path, body);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Vigil API] PATCH $path error: $e');
      return null;
    }
  }

  Future<bool> _delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }
      if (response.statusCode == 401) {
        if (await refreshAccessToken()) {
          return _delete(path);
        }
      }
      return false;
    } catch (e) {
      debugPrint('[Vigil API] DELETE $path error: $e');
      return false;
    }
  }
}
