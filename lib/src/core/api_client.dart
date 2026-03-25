import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Cliente HTTP deliberadamente chico.
///
/// La idea es mantener la app lo más vanilla posible: sin Retrofit, sin Dio y
/// sin generación de código. Todas las requests salen por acá y comparten el
/// manejo de headers, token, parsing y errores 4xx/5xx.
class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;
  String? _authToken;

  set authToken(String? value) => _authToken = value;

  Future<Map<String, dynamic>> getJsonMap(String path) async {
    final response = await http.get(_buildUri(path), headers: _headers());
    final decoded = _decodeBody(response.body);

    _throwIfNeeded(response, decoded);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    Map<String, String> fields = const <String, String>{},
    List<ApiFilePart> files = const <ApiFilePart>[],
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path));
    request.headers.addAll(_headers());
    request.fields.addAll(fields);

    for (final part in files) {
      if (part.file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            part.fieldName,
            part.file.bytes!,
            filename: part.file.fileName,
          ),
        );
        continue;
      }

      if (part.file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            part.fieldName,
            part.file.path!,
            filename: part.file.fileName,
          ),
        );
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = _decodeBody(response.body);

    _throwIfNeeded(response, decoded);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  Map<String, String> _headers() {
    return <String, String>{
      'Accept': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
  }

  dynamic _decodeBody(String body) {
    final trimmed = body.trim();

    if (trimmed.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return <String, dynamic>{'message': trimmed};
    }
  }

  void _throwIfNeeded(http.Response response, dynamic decoded) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'message': response.reasonPhrase};

    final rawErrors =
        body['errors'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final fieldErrors = rawErrors.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList(),
      ),
    );

    throw ApiException(
      statusCode: response.statusCode,
      message:
          (body['message'] ??
                  body['detail'] ??
                  body['title'] ??
                  body['error_description'] ??
                  body['error'] ??
                  response.reasonPhrase ??
                  'La solicitud falló (HTTP ${response.statusCode}).')
              .toString(),
      fieldErrors: fieldErrors,
    );
  }
}
