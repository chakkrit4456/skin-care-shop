import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// Notifies listeners when the login token changes.
class ApiClient extends ChangeNotifier {
  ApiClient._();
  static final instance = ApiClient._();
  static const _tokenKey = 'auth_token';

  String? _token;
  bool get loggedIn => _token != null;

  Uri get _base => Uri.base.resolve(Config.apiUrl.endsWith('/') ? Config.apiUrl : '${Config.apiUrl}/');

  Future<void> init() async {
    _token = (await SharedPreferences.getInstance()).getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    token == null ? await prefs.remove(_tokenKey) : await prefs.setString(_tokenKey, token);
    notifyListeners();
  }

  /// Turns a stored path like /uploads/x.jpg into a full URL.
  String? resolveUrl(String? path) => path == null || path.isEmpty ? null : _base.resolve(path).toString();

  Uri liveUri() {
    final u = _uri('/live');
    return u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws');
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = _base.resolve(path.startsWith('/') ? path.substring(1) : path);
    return query == null ? u : u.replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _handle(http.Response r) async {
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode == 401 && _token != null) await setToken(null);
    if (r.statusCode >= 400) {
      throw ApiException(r.statusCode, body is Map && body['error'] != null ? '${body['error']}' : 'HTTP ${r.statusCode}');
    }
    return body;
  }

  Future<dynamic> get(String path, [Map<String, String>? query]) async =>
      _handle(await http.get(_uri(path, query), headers: _headers));
  Future<dynamic> post(String path, [Object? body]) async =>
      _handle(await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<dynamic> put(String path, Object body) async =>
      _handle(await http.put(_uri(path), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> patch(String path, Object body) async =>
      _handle(await http.patch(_uri(path), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> delete(String path) async => _handle(await http.delete(_uri(path), headers: _headers));

  /// Returns the stored path of the uploaded image.
  Future<String> uploadImage(Uint8List bytes, String filename) async =>
      (await uploadFile('/admin/upload', bytes, filename))['url'] as String;

  Future<dynamic> uploadFile(String path, Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'png' : ext == 'webp' ? 'webp' : 'jpeg';
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({if (_token != null) 'Authorization': 'Bearer $_token'})
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: MediaType('image', mime)));
    return _handle(await http.Response.fromStream(await req.send()));
  }
}

final api = ApiClient.instance;
