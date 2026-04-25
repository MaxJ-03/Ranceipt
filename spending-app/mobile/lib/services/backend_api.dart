import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRequiredException implements Exception {
  final String message;

  AuthRequiredException([this.message = 'Authentication required']);

  @override
  String toString() => message;
}

class BackendApi {
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String _sessionTokenKey = 'backend_session_token';
  static const String _demoSessionToken = 'demo-session-token';

  final http.Client _client;
  String? _sessionToken;
  bool _didLoadStoredToken = false;

  BackendApi({http.Client? client}) : _client = client ?? http.Client();

  bool get _isDemoSession => _sessionToken == _demoSessionToken;

  String _buildErrorMessage(http.Response response, String fallbackPrefix) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final detail = body['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          return '$fallbackPrefix: $detail';
        }
      }
    } catch (_) {}

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
    _sessionToken = token;
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

    if (_isDemoSession) {
      return true;
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

  Future<void> loginWithBunqSandbox() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/bunq/sandbox-login'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 400) {
        throw Exception(_buildErrorMessage(response, 'bunq sandbox login failed'));
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw Exception('Unexpected sandbox login response shape');
      }

      final token = body['session_token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('Missing session_token in sandbox login response');
      }

      await _persistSessionToken(token);
    } catch (_) {
      // Demo fallback: never block the UI on login.
      await _persistSessionToken(_demoSessionToken);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    await ensureSession();

    if (_isDemoSession) {
      return {
        'id': 0,
        'debug': 'demo-user',
      };
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'current user fetch failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected auth/me response shape');
    }

    return body;
  }

  Future<void> syncBunqTransactions() async {
    await ensureSession();

    if (_isDemoSession) {
      return;
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/bunq/transactions/sync'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'bunq transaction sync failed'));
    }
  }

  Future<List<Map<String, dynamic>>> getReceipts() async {
    await ensureSession();

    if (_isDemoSession) {
      return [];
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/receipts/'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'receipts fetch failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw Exception('Unexpected receipts response shape');
    }

    return body.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>> getReceiptDetail(int receiptId) async {
    await ensureSession();

    if (_isDemoSession) {
      throw Exception('Demo session has no backend receipt detail');
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/receipts/$receiptId/detail'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'receipt detail fetch failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected receipt detail response shape');
    }

    return body;
  }

  Future<Map<String, dynamic>> uploadReceiptAndParse(XFile image) async {
    await ensureSession();

    if (_isDemoSession) {
      throw Exception('Demo session has no backend parser');
    }

    final uri = Uri.parse('$_baseUrl/receipts/parse');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_sessionToken'
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: image.name,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'receipt parse failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected receipt parse response shape');
    }

    return body;
  }

  Future<Map<String, dynamic>> createManualReceipt({
    required String merchant,
    required double totalAmount,
    String currency = 'EUR',
  }) async {
    await ensureSession();

    if (_isDemoSession) {
      return {
        'id': DateTime.now().microsecondsSinceEpoch,
        'merchant': merchant,
        'total_amount': totalAmount,
        'currency': currency,
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/receipts/'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'merchant': merchant,
        'total_amount': totalAmount,
        'currency': currency,
        'items': <Map<String, dynamic>>[],
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'manual receipt create failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected manual receipt response shape');
    }

    return body;
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    await ensureSession();

    if (_isDemoSession) {
      return [];
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/goals/'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'goals fetch failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw Exception('Unexpected goals response shape');
    }

    return body.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>> createGoal({
    required double amountToSave,
    required DateTime targetDate,
    String currency = 'EUR',
  }) async {
    await ensureSession();

    if (_isDemoSession) {
      return {
        'id': DateTime.now().microsecondsSinceEpoch,
        'amount_to_save': amountToSave,
        'currency': currency,
        'target_date': targetDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/goals/'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount_to_save': amountToSave,
        'currency': currency,
        'target_date': targetDate.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'goal creation failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected create goal response shape');
    }

    return body;
  }

  Future<Map<String, dynamic>> getAiInsightsForCurrentUser() async {
    final user = await getCurrentUser();
    final userId = int.tryParse(user['id'].toString());

    if (userId == null) {
      throw Exception('Could not determine current user id for AI insights');
    }

    if (_isDemoSession) {
      return {
        'summary': 'Coffee and ready meals are your biggest saving opportunities this month.',
        'potential_savings': 38.0,
      };
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/personal-goals/$userId/insights'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
      },
    );

    if (response.statusCode >= 400) {
      throw Exception(_buildErrorMessage(response, 'AI insights fetch failed'));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected AI insights response shape');
    }

    return body;
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    await ensureSession();

    if (_isDemoSession) {
      return [];
    }

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