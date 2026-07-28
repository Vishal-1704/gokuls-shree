// lib/config/supabase_service.dart
// Supabase service-role and user-context HTTP clients.
// Since there's no official Dart admin SDK, we use raw REST calls with the service key.

import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseService {
  static late String _supabaseUrl;
  static late String _serviceKey;
  static late String _anonKey;

  static void init({
    required String supabaseUrl,
    required String serviceKey,
    required String anonKey,
  }) {
    _supabaseUrl = supabaseUrl.replaceAll(RegExp(r'/$'), '');
    _serviceKey = serviceKey;
    _anonKey = anonKey;
  }

  // ── Headers ──────────────────────────────────────────────────────────────

  /// Service-role headers — bypasses RLS. ONLY for server-side admin operations.
  static Map<String, String> get _serviceHeaders => {
        'apikey': _serviceKey,
        'Authorization': 'Bearer $_serviceKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// User-context headers — respects RLS.
  static Map<String, String> _userHeaders(String accessToken) => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  // ── Auth Admin API ────────────────────────────────────────────────────────

  /// Validate a user's JWT. Returns the user object or null.
  static Future<Map<String, dynamic>?> getUser(String token) async {
    final res = await http.get(
      Uri.parse('$_supabaseUrl/auth/v1/user'),
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Create a new auth user (admin). Bypasses email confirmation.
  static Future<Map<String, dynamic>?> adminCreateUser({
    required String email,
    required String password,
    Map<String, dynamic>? userMetadata,
  }) async {
    final res = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/admin/users'),
      headers: _serviceHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        'email_confirm': true,
        if (userMetadata != null) 'user_metadata': userMetadata,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['msg'] ?? body['message'] ?? 'Failed to create user');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Delete an auth user by UUID.
  static Future<void> adminDeleteUser(String uid) async {
    await http.delete(
      Uri.parse('$_supabaseUrl/auth/v1/admin/users/$uid'),
      headers: _serviceHeaders,
    );
  }

  /// Update any user's password (super admin only).
  static Future<void> adminUpdateUserById(String uid, {required String password}) async {
    final res = await http.put(
      Uri.parse('$_supabaseUrl/auth/v1/admin/users/$uid'),
      headers: _serviceHeaders,
      body: jsonEncode({'password': password}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['msg'] ?? 'Failed to update password');
    }
  }

  /// Sign in with email + password.
  static Future<Map<String, dynamic>?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
      headers: {'apikey': _anonKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Send OTP to email.
  static Future<bool> sendOtp(String email) async {
    final res = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/otp'),
      headers: {'apikey': _anonKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'create_user': false}),
    );
    return res.statusCode == 200;
  }

  /// Verify OTP.
  static Future<Map<String, dynamic>?> verifyOtp({
    required String email,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/verify'),
      headers: {'apikey': _anonKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token, 'type': 'email'}),
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Refresh an access token.
  static Future<Map<String, dynamic>?> refreshSession(String refreshToken) async {
    final res = await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=refresh_token'),
      headers: {'apikey': _anonKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Sign out (invalidate token server-side).
  static Future<void> signOut(String accessToken) async {
    await http.post(
      Uri.parse('$_supabaseUrl/auth/v1/logout'),
      headers: {
        'apikey': _anonKey,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
  }

  // ── Database REST API (service role — bypasses RLS) ───────────────────────

  /// SELECT from a table with optional filters.
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    String? order,
    int? limit,
    int? offset,
    bool count = false,
  }) async {
    final params = <String, String>{'select': columns};
    if (order != null) params['order'] = order;
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
    if (filters != null) {
      for (final e in filters.entries) {
        params['${e.key}'] = 'eq.${e.value}';
      }
    }

    final headers = Map<String, String>.from(_serviceHeaders);
    if (count) headers['Prefer'] = 'count=exact,return=representation';

    final uri = Uri.parse('$_supabaseUrl/rest/v1/$table').replace(queryParameters: params);
    final res = await http.get(uri, headers: headers);

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Query failed on $table');
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  /// Flexible query builder — returns raw response for custom queries.
  static Future<http.Response> query(
    String table, {
    String method = 'GET',
    String columns = '*',
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    Object? body,
    String? accessToken,
  }) async {
    final params = <String, String>{'select': columns, ...?queryParams};
    final headers = accessToken != null
        ? _userHeaders(accessToken)
        : Map<String, String>.from(_serviceHeaders);
    if (extraHeaders != null) headers.addAll(extraHeaders);

    final uri = Uri.parse('$_supabaseUrl/rest/v1/$table').replace(queryParameters: params);

    switch (method.toUpperCase()) {
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body));
      case 'PATCH':
        return http.patch(uri, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return http.put(uri, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        return http.get(uri, headers: headers);
    }
  }

  /// INSERT a single row and return it.
  static Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_supabaseUrl/rest/v1/$table'),
      headers: _serviceHeaders,
      body: jsonEncode(data),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Insert failed on $table');
    }
    final result = jsonDecode(res.body);
    return result is List ? result.first : result as Map<String, dynamic>;
  }

  /// UPDATE rows matching filters and return updated rows.
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    final params = <String, String>{};
    for (final e in filters.entries) {
      params[e.key] = 'eq.${e.value}';
    }

    final uri = Uri.parse('$_supabaseUrl/rest/v1/$table').replace(queryParameters: params);
    final res = await http.patch(uri, headers: _serviceHeaders, body: jsonEncode(data));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Update failed on $table');
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  /// UPSERT rows.
  static Future<List<Map<String, dynamic>>> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    required String onConflict,
  }) async {
    final headers = Map<String, String>.from(_serviceHeaders);
    headers['Prefer'] = 'resolution=merge-duplicates,return=representation';
    headers['on_conflict'] = onConflict;

    final res = await http.post(
      Uri.parse('$_supabaseUrl/rest/v1/$table'),
      headers: headers,
      body: jsonEncode(rows),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Upsert failed on $table');
    }
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }
}
