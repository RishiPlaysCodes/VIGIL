import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({
    this.baseUrl = const String.fromEnvironment(
      'POCKET_GUARDIAN_API_URL',
      defaultValue: 'http://10.0.2.2:8000/api',
    ),
  });

  final String baseUrl;
  String? token;

  Future<Map<String, dynamic>> signUp({
    required String username,
    required String password,
  }) {
    return _post(
      '/signup/',
      {'username': username, 'password': password},
    );
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) {
    return _post(
      '/login/',
      {'username': username, 'password': password},
    );
  }

  Future<void> syncContact({
    required int userId,
    required String name,
    required String phone,
    required String email,
  }) async {
    await _post(
      '/users/$userId/contacts/',
      {
        'name': name,
        'phone_number': phone,
        'email': email,
        'relationship': 'Primary contact',
        'is_primary': true,
      },
    );
  }

  Future<Map<String, dynamic>> syncAlert({
    required int userId,
    required String reason,
    required String status,
    required DateTime occurredAt,
    required double? latitude,
    required double? longitude,
    required String photoPath,
  }) async {
    return _post(
      '/users/$userId/alerts/',
      {
        'reason': reason,
        'status': status,
        'occurred_at': occurredAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'photo_path': photoPath,
      },
    );
  }

  Future<void> uploadAlertPhoto({
    required int userId,
    required int alertId,
    required String filePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/$userId/alerts/$alertId/photo/'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Token $token';
    }
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));
    final response = await request.send();
    if (response.statusCode >= 400) {
      throw Exception('Photo upload failed');
    }
  }

  Future<void> syncLocation({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    await _post(
      '/users/$userId/location/',
      {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
      body: jsonEncode(payload),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['error'] ?? 'Request failed');
    }
    return body;
  }
}
