import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiFile {
  final String field;
  final String path;
  const ApiFile(this.field, this.path);
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? token;

  Map<String, String> get headers =>
      token == null ? const {} : {'Authorization': 'Bearer $token'};

  static String absolute(String relative) =>
      relative.startsWith('http') ? relative : ApiEndpoints.url(relative);

  Future<Map<String, dynamic>> get(String endpoint,
      [Map<String, String>? query]) {
    final uri = Uri.parse(ApiEndpoints.url(endpoint))
        .replace(queryParameters: query?.isEmpty == true ? null : query);
    return _send(() => http.get(uri, headers: headers));
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) {
    final uri = Uri.parse(ApiEndpoints.url(endpoint));
    return _send(() => http.post(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ));
  }

  Future<Map<String, dynamic>> postForm(
    String endpoint,
    Map<String, String> fields, {
    List<ApiFile> files = const [],
  }) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse(ApiEndpoints.url(endpoint)))
      ..headers.addAll(headers)
      ..fields.addAll(fields);
    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath(f.field, f.path));
    }
    return _send(() async {
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }, timeout: const Duration(seconds: 40));
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() call, {
    Duration timeout = AppConfig.requestTimeout,
  }) async {
    http.Response res;
    try {
      res = await call().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(_offline);
    } on http.ClientException {
      throw const ApiException(_offline);
    } catch (_) {
      throw const ApiException(_offline);
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
          res.statusCode == 404
              ? 'Server files not found. Check that the php folder is in htdocs/autopieces/api.'
              : 'The server sent an unexpected answer (HTTP ${res.statusCode}).',
          res.statusCode);
    }
    if (data['ok'] != true) {
      throw ApiException(
          (data['error'] as String?) ?? 'Server error.', res.statusCode);
    }
    return data;
  }

  static const _offline =
      'Cannot reach the server. Start Apache and MySQL in XAMPP and check PHP_BASE_URL.';
}
