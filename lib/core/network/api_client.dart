import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_environment.dart';
import '../errors/app_failure.dart';
import '../services/pilot_local_store.dart';

class ApiResponse {
  final int statusCode;
  final Object? data;
  final Map<String, String> headers;

  const ApiResponse(this.statusCode, this.data, this.headers);

  Map<String, dynamic> get object {
    final value = data;
    if (value is Map<String, dynamic>) return value;
    throw const AppFailure(
      'El servidor devolvió una respuesta inesperada.',
      code: 'invalid_response',
    );
  }
}

class ApiClient {
  final http.Client _http;
  final String baseUrl;
  Future<bool>? _refreshInProgress;

  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      baseUrl = (baseUrl ?? AppEnvironment.apiBaseUrl).replaceAll(
        RegExp(r'/$'),
        '',
      );

  Future<ApiResponse> get(String path, {bool authenticated = true}) =>
      request('GET', path, authenticated: authenticated);

  Future<ApiResponse> post(
    String path, {
    Object? body,
    bool authenticated = true,
    Map<String, String> headers = const {},
  }) => request(
    'POST',
    path,
    body: body,
    authenticated: authenticated,
    headers: headers,
  );

  Future<ApiResponse> put(
    String path, {
    Object? body,
    bool authenticated = true,
    Map<String, String> headers = const {},
  }) => request(
    'PUT',
    path,
    body: body,
    authenticated: authenticated,
    headers: headers,
  );

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => request('PATCH', path, body: body, headers: headers);

  Future<ApiResponse> delete(
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => request('DELETE', path, body: body, headers: headers);

  Future<ApiResponse> multipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
    Map<String, String> headers = const {},
    bool retryAfterRefresh = true,
  }) async {
    final token = await PilotLocalStore.readAccessToken();
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...headers,
      })
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    late http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 30)),
      );
    } catch (_) {
      throw const AppFailure(
        'No se pudo cargar el archivo.',
        code: 'network_error',
      );
    }
    if (response.statusCode == 401 &&
        retryAfterRefresh &&
        await _refreshSession()) {
      return multipart(
        path,
        fields: fields,
        fileField: fileField,
        fileBytes: fileBytes,
        fileName: fileName,
        mimeType: mimeType,
        headers: headers,
        retryAfterRefresh: false,
      );
    }
    return _response(response);
  }

  Future<Uint8List> downloadBytes(String url) async {
    try {
      final response = await _http
          .get(_uri(url), headers: {'Accept': 'application/octet-stream'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppFailure(
          'No se pudo descargar el archivo.',
          code: 'http_${response.statusCode}',
        );
      }
      return response.bodyBytes;
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        'No se pudo descargar el archivo.',
        code: 'network_error',
      );
    }
  }

  Future<ApiResponse> request(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
    Map<String, String> headers = const {},
    bool retryAfterRefresh = true,
  }) async {
    final token = authenticated
        ? await PilotLocalStore.readAccessToken()
        : null;
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...headers,
    };
    final uri = _uri(path);
    late http.Response response;
    try {
      response = await _send(
        method,
        uri,
        requestHeaders,
        body,
      ).timeout(const Duration(seconds: 20));
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(
        'No se pudo conectar con el servidor.',
        code: 'network_error',
      );
    }

    if (response.statusCode == 401 &&
        authenticated &&
        retryAfterRefresh &&
        await _refreshSession()) {
      return request(
        method,
        path,
        body: body,
        authenticated: authenticated,
        headers: headers,
        retryAfterRefresh: false,
      );
    }

    return _response(response);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return _http.put(uri, headers: headers, body: encoded);
      case 'PATCH':
        return _http.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        return _http.delete(uri, headers: headers, body: encoded);
      default:
        throw AppFailure('Método HTTP no soportado: $method');
    }
  }

  Future<bool> _refreshSession() async {
    final activeRefresh = _refreshInProgress;
    if (activeRefresh != null) return activeRefresh;
    final refresh = _performRefresh();
    _refreshInProgress = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
      }
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await PilotLocalStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await post(
        '/sesiones/renovaciones',
        authenticated: false,
        body: {
          'refreshToken': refreshToken,
          'identificadorDispositivo': AppEnvironment.deviceId,
        },
      );
      await saveSessionResponse(response.object);
      return true;
    } catch (_) {
      await PilotLocalStore.clearSession();
      return false;
    }
  }

  Future<void> saveSessionResponse(Map<String, dynamic> json) =>
      PilotLocalStore.saveApiSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        sessionId: json['id'] as String,
      );

  void close() => _http.close();

  Uri _uri(String pathOrUrl) {
    final parsed = Uri.tryParse(pathOrUrl);
    if (parsed != null && parsed.hasScheme) return parsed;
    final origin = Uri.parse(baseUrl);
    if (pathOrUrl.startsWith('/api/')) {
      return Uri.parse('${origin.scheme}://${origin.authority}$pathOrUrl');
    }
    return Uri.parse(
      '$baseUrl${pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl'}',
    );
  }

  ApiResponse _response(http.Response response) {
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final problem = decoded is Map<String, dynamic> ? decoded : null;
      throw AppFailure(
        problem?['detail'] as String? ??
            problem?['title'] as String? ??
            'La operación no pudo completarse.',
        code: problem?['codigo'] as String? ?? 'http_${response.statusCode}',
      );
    }
    return ApiResponse(response.statusCode, decoded, response.headers);
  }

  Object? _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      throw const AppFailure(
        'El servidor devolvió contenido no válido.',
        code: 'invalid_json',
      );
    }
  }
}
