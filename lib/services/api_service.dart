import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// എല്ലാ HTTP calls-ഉം ഇതിലൂടെ. Token സൂക്ഷിക്കൽ, Authorization header,
/// 401 വന്നാൽ auto refresh എന്നിവ ഇവിടെ.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _access;
  String? _refresh;

  /// Refresh-ഉം പരാജയപ്പെട്ടാൽ (session തീർന്നാൽ) വിളിക്കും
  void Function()? onSessionExpired;

  // ---------- Tokens ----------
  Future<void> loadTokens() async {
    _access = await _storage.read(key: 'access');
    _refresh = await _storage.read(key: 'refresh');
  }

  bool get hasToken => _access != null && _access!.isNotEmpty;

  Future<void> saveTokens({required String access, String? refresh}) async {
    _access = access;
    await _storage.write(key: 'access', value: access);
    if (refresh != null) {
      _refresh = refresh;
      await _storage.write(key: 'refresh', value: refresh);
    }
  }

  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }

  // ---------- Public helpers ----------
  Future<dynamic> get(
    String path, {
    Map<String, String?>? query,
    bool auth = true,
  }) => _request('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _request('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body}) =>
      _request('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _request('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  /// List response (pagination ഉണ്ടെങ്കിലും ഇല്ലെങ്കിലും)
  List<dynamic> asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) {
      return data['results'] as List;
    }
    return [];
  }

  // ---------- Core ----------
  Uri _uri(String path, Map<String, String?>? query) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.trim().isNotEmpty) q[k] = v.trim();
    });
    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String?>? query,
    Object? body,
    bool auth = true,
    bool retried = false,
  }) async {
    final uri = _uri(path, query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (auth && hasToken) 'Authorization': 'Bearer $_access',
    };
    final encoded = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      switch (method) {
        case 'POST':
          res = await http
              .post(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.timeout);
          break;
        case 'PUT':
          res = await http
              .put(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.timeout);
          break;
        case 'PATCH':
          res = await http
              .patch(uri, headers: headers, body: encoded)
              .timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          res = await http
              .delete(uri, headers: headers)
              .timeout(ApiConfig.timeout);
          break;
        default:
          res = await http
              .get(uri, headers: headers)
              .timeout(ApiConfig.timeout);
      }
    } on SocketException {
      throw ApiException(
        'Server-ലേക്ക് connect ചെയ്യാൻ കഴിഞ്ഞില്ല. Internet / server / IP പരിശോധിക്കുക.',
      );
    } on TimeoutException {
      throw ApiException('Server പ്രതികരിക്കുന്നില്ല. വീണ്ടും ശ്രമിക്കുക.');
    } on http.ClientException {
      throw ApiException('Network error. വീണ്ടും ശ്രമിക്കുക.');
    }

    // Token expire ആയാൽ refresh ചെയ്ത് ഒരു തവണ retry
    if (res.statusCode == 401 && auth && !retried) {
      final ok = await _refreshAccessToken();
      if (ok) {
        return _request(
          method,
          path,
          query: query,
          body: body,
          auth: auth,
          retried: true,
        );
      }
      onSessionExpired?.call();
      throw ApiException('Session expire ആയി. വീണ്ടും login ചെയ്യുക.', 401);
    }

    dynamic data;
    final text = utf8.decode(res.bodyBytes);
    if (text.trim().isNotEmpty) {
      try {
        data = jsonDecode(text);
      } catch (_) {
        data = text;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 403) {
      throw ApiException(
        _messageFrom(data) ?? 'ഇത് ചെയ്യാൻ നിങ്ങൾക്ക് അനുമതി ഇല്ല.',
        403,
      );
    }
    if (res.statusCode == 404) {
      throw ApiException('കണ്ടെത്താനായില്ല.', 404);
    }
    if (res.statusCode >= 500) {
      throw ApiException('Server error (${res.statusCode}).', res.statusCode);
    }
    throw ApiException(
      _messageFrom(data) ?? 'Request പരാജയപ്പെട്ടു (${res.statusCode}).',
      res.statusCode,
    );
  }

  Future<bool> _refreshAccessToken() async {
    if (_refresh == null || _refresh!.isEmpty) return false;
    try {
      final res = await http
          .post(
            _uri('/auth/refresh/', null),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': _refresh}),
          )
          .timeout(ApiConfig.timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        await saveTokens(
          access: data['access'].toString(),
          refresh: data['refresh']?.toString(),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ---------- Error message parsing ----------
  /// {"shop": ["This shop is not assigned to you."]} -> "shop: This shop is..."
  String? _messageFrom(dynamic data) {
    if (data == null) return null;
    if (data is String) return data.length > 200 ? null : data;
    final lines = <String>[];
    _flatten(data, null, lines);
    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  void _flatten(dynamic data, String? key, List<String> out) {
    if (data is Map) {
      data.forEach((k, v) {
        final isGeneric = k == 'detail' || k == 'non_field_errors';
        _flatten(v, isGeneric ? key : k.toString(), out);
      });
    } else if (data is List) {
      for (final e in data) {
        _flatten(e, key, out);
      }
    } else if (data != null) {
      out.add(key == null ? data.toString() : '$key: $data');
    }
  }
}
