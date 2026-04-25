import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRequiredException implements Exception {
  final String message;

  AuthRequiredException([this.message = 'Authentication required']);

  @override
  String toString() => message;
}

class BunqAuthStartResponse {
  final String state;
  final String authorizationUrl;

  BunqAuthStartResponse({required this.state, required this.authorizationUrl});
}

class BackendApi {
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String _sessionTokenKey = 'backend_session_token';

  final http.Client _client;
  String? _sessionToken;
  bool _didLoadStoredToken = false;

  BackendApi({http.Client? client}) : _client = client ?? http.Client();

  String _buildErrorMessage(http.Response response, String fallbackPrefix) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          return '$fallbackPrefix: $detail';
        }
      }
    } catch (_) {
      // Ignore parse failures and fall back to status-only message.
    }

    return '$fallbackPrefix (${response.statusCode})';
  }

  Future<void> _loadStoredTokenIfNeeded() async {
    if (_didLoadStoredToken) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString(_sessionTokenKey);
    _didLoadStoredToken = true;
  }

  Future<void> _persistSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
  }

  Future<void> _clearStoredSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    _sessionToken = null;
  }

  Future<bool> _isSessionValid() async {
    if (_sessionToken == null) {
      return false;
    }

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $_sessionToken',
        },
      );

      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureSession() async {
    await _loadStoredTokenIfNeeded();

    if (await _isSessionValid()) {
      return;
    }

    if (_sessionToken != null) {
      await _clearStoredSessionToken();
    }

    throw AuthRequiredException('No valid session. Continue with bunq.');
  }

  Future<bool> hasValidSession() async {
    await _loadStoredTokenIfNeeded();
    return _isSessionValid();
  }

  Future<void> clearSession() async {
    await _clearStoredSessionToken();
  }

  Future<BunqAuthStartResponse> startBunqOAuth() async {
    final response = await _client.get(Uri.parse('$_baseUrl/auth/bunq/start'));
    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'bunq OAuth start failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected bunq start response shape');
    }

    final state = body['state']?.toString();
    final authorizationUrl = body['authorization_url']?.toString();
    if (state == null || state.isEmpty || authorizationUrl == null || authorizationUrl.isEmpty) {
      throw Exception('Missing OAuth start payload');
    }

    return BunqAuthStartResponse(
      state: state,
      authorizationUrl: authorizationUrl,
    );
  }

  Future<void> completeBunqOAuth({
    required String state,
    required String bunqUserApiKeyId,
    required String bunqAccessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/bunq/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'state': state,
        'bunq_user_api_key_id': bunqUserApiKeyId,
        'bunq_access_token': bunqAccessToken,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'bunq OAuth completion failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected bunq completion response shape');
    }

    final token = body['session_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Missing session_token in bunq completion response');
    }

    _sessionToken = token;
    await _persistSessionToken(token);
  }

  Future<void> completeBunqOAuthWithCode({
    required String state,
    required String code,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/bunq/complete-with-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'state': state,
        'code': code,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'bunq OAuth code completion failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected bunq code completion response shape');
    }

    final token = body['session_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Missing session_token in bunq code completion response');
    }

    _sessionToken = token;
    await _persistSessionToken(token);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    await ensureSession();

    final response = await _client.get(
      Uri.parse('$_baseUrl/transactions/'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'transactions fetch failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw Exception('Unexpected transactions response shape');
    }

    return body.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}