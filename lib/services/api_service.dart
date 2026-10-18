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

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _access;
  String? _refresh;

  void Function()? onSessionExpired;

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

  List<dynamic> asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) {
      return data['results'] as List;
    }
    return [];
  }

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
        'Unable to connect to the server. Please check your internet connection, server status, and IP address..',
      );
    } on TimeoutException {
      throw ApiException('The server is not responding. Please try again.');
    } on http.ClientException {
      throw ApiException('Network error. Please try again.');
    }

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
      throw ApiException(
        'Your session has expired. Please log in again..',
        401,
      );
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
        _messageFrom(data) ??
            'You do not have permission to perform this action..',
        403,
      );
    }
    if (res.statusCode == 404) {
      throw ApiException('Not found.', 404);
    }
    if (res.statusCode >= 500) {
      throw ApiException('Server error (${res.statusCode}).', res.statusCode);
    }
    throw ApiException(
      _messageFrom(data) ?? 'Request failed.(${res.statusCode}).',
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
