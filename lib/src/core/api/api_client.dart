import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient({
    required ApiConfig config,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _config = config,
       _httpClient = httpClient ?? http.Client();

  final ApiConfig _config;
  final http.Client _httpClient;
  final Duration timeout;

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> get(String path) async {
    return _send(() => _httpClient.get(_uri(path), headers: _headers));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send(
      () => _httpClient.post(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Uri _uri(String path) {
    final base = Uri.parse(_config.baseUrl);
    return base.resolve(path.startsWith('/') ? path.substring(1) : path);
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const RepositoryException('Request timed out.');
    } on http.ClientException {
      throw const RepositoryException('Network request failed.');
    }

    Map<String, dynamic> decoded;
    try {
      final body = response.body.trim();
      decoded = body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw const RepositoryException('Server returned malformed JSON.');
    } on TypeError {
      throw const RepositoryException('Server returned malformed JSON.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RepositoryException(_errorMessage(response.statusCode, decoded));
    }

    return decoded;
  }

  String _errorMessage(int statusCode, Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return switch (statusCode) {
      400 => 'Bad request.',
      403 => 'Access denied.',
      404 => 'Resource not found.',
      409 => 'Request conflict.',
      422 => 'Request validation failed.',
      >= 500 => 'Server error.',
      _ => 'Request failed.',
    };
  }
}
