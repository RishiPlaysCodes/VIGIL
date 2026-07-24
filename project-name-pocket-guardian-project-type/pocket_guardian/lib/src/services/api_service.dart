import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'logger_service.dart';

// ─── Exception Types ────────────────────────────────────────────────────────

/// Base exception for all API errors.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.originalError});

  final String message;
  final int? statusCode;
  final Object? originalError;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when the network is unavailable or the request times out.
class NetworkException extends ApiException {
  const NetworkException(super.message, {super.originalError});
}

/// Thrown when the server returns a 401 Unauthorized.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

/// Thrown when the server returns a 429 Too Many Requests.
class RateLimitException extends ApiException {
  const RateLimitException(super.message) : super(statusCode: 429);
}

/// Thrown when the server returns a 5xx error.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}

/// Thrown when input validation fails on the server.
class ValidationException extends ApiException {
  const ValidationException(super.message) : super(statusCode: 400);
}

// ─── API Service ────────────────────────────────────────────────────────────

class ApiService {
  ApiService({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final _logger = AppLogger.instance;

  String? token;

  Duration get _timeout => Duration(seconds: AppConfig.httpTimeoutSeconds);

  // ─── Auth ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signUp({
    required String username,
    required String password,
  }) {
    return _post(
      '/signup/',
      {'username': username, 'password': password},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) {
    return _post(
      '/login/',
      {'username': username, 'password': password},
      requiresAuth: false,
    );
  }

  // ─── Contacts ───────────────────────────────────────────────────────────

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

  // ─── Alerts ─────────────────────────────────────────────────────────────

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
    final uri = Uri.parse('$baseUrl/users/$userId/alerts/$alertId/photo/');
    _logger.info('Uploading photo to $uri', tag: 'API');

    try {
      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 400) {
        _logger.warning(
          'Photo upload failed: ${response.statusCode}',
          tag: 'API',
        );
        throw _mapStatusCodeToException(response.statusCode, response.body);
      }

      _logger.info('Photo uploaded successfully', tag: 'API');
    } on TimeoutException {
      throw const NetworkException('Upload timed out. Please try again.');
    } on SocketException catch (e) {
      throw NetworkException('Network unavailable: ${e.message}', originalError: e);
    }
  }

  // ─── Location ───────────────────────────────────────────────────────────

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
      retryOnFailure: false, // Location pings are fire-and-forget
    );
  }

  // ─── Core HTTP Methods ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    bool requiresAuth = true,
    bool retryOnFailure = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresAuth && token != null) 'Authorization': 'Token $token',
    };
    final body = jsonEncode(payload);

    int attempts = 0;
    final maxAttempts = retryOnFailure ? AppConfig.maxRetryAttempts : 1;

    while (true) {
      attempts++;
      try {
        _logger.debug('POST $path (attempt $attempts)', tag: 'API');

        final response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(_timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return decoded;
        }

        // Don't retry client errors (4xx) except 429
        if (response.statusCode < 500 && response.statusCode != 429) {
          throw _mapStatusCodeToException(response.statusCode, response.body);
        }

        // Retry server errors (5xx) and rate limits (429)
        if (attempts >= maxAttempts) {
          throw _mapStatusCodeToException(response.statusCode, response.body);
        }

        _logger.warning(
          'Request failed with ${response.statusCode}, retrying ($attempts/$maxAttempts)',
          tag: 'API',
        );

        // Exponential backoff: 1s, 2s, 4s...
        await Future.delayed(Duration(seconds: 1 << (attempts - 1)));
      } on TimeoutException {
        if (attempts >= maxAttempts) {
          throw const NetworkException(
            'Request timed out. Please check your connection.',
          );
        }
        await Future.delayed(Duration(seconds: 1 << (attempts - 1)));
      } on SocketException catch (e) {
        if (attempts >= maxAttempts) {
          throw NetworkException(
            'Unable to reach server. Check your internet connection.',
            originalError: e,
          );
        }
        await Future.delayed(Duration(seconds: 1 << (attempts - 1)));
      } on ApiException {
        rethrow;
      } catch (e) {
        if (attempts >= maxAttempts) {
          _logger.error('Unexpected API error', tag: 'API', error: e);
          throw ApiException(
            'An unexpected error occurred.',
            originalError: e,
          );
        }
        await Future.delayed(Duration(seconds: 1 << (attempts - 1)));
      }
    }
  }

  ApiException _mapStatusCodeToException(int statusCode, String body) {
    String message;
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      message = decoded['error'] as String? ?? 'Request failed';
    } catch (_) {
      message = 'Request failed';
    }

    return switch (statusCode) {
      400 => ValidationException(message),
      401 => UnauthorizedException(message),
      429 => RateLimitException(message),
      >= 500 => ServerException(message, statusCode: statusCode),
      _ => ApiException(message, statusCode: statusCode),
    };
  }

  /// Release resources when the service is no longer needed.
  void dispose() {
    _client.close();
  }
}
