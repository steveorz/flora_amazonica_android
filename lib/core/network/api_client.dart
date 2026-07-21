import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../storage/secure_storage.dart';

/// Espejo de `APIError` (iOS). Distingue fallo de red, de servidor y de decodificación
/// porque la UI reacciona distinto a cada uno.
sealed class ApiException implements Exception {
  const ApiException();

  /// Mensaje listo para mostrar al usuario, igual que `APIError.errorDescription`.
  String get message;

  @override
  String toString() => message;
}

class ApiInvalidUrl extends ApiException {
  const ApiInvalidUrl();
  @override
  String get message => 'URL inválida';
}

/// El servidor respondió con un status fuera de 200-299.
class ApiRequestFailed extends ApiException {
  final int statusCode;

  /// Mensaje que vino del backend (NestJS), si se pudo extraer.
  final String? serverMessage;

  const ApiRequestFailed(this.statusCode, [this.serverMessage]);

  @override
  String get message => serverMessage ?? 'Error del servidor ($statusCode)';
}

/// No se pudo alcanzar el servidor (sin red, DNS, timeout).
class ApiNetworkFailure extends ApiException {
  const ApiNetworkFailure();
  @override
  String get message => 'No se pudo conectar al servidor.';
}

class ApiDecodingFailed extends ApiException {
  const ApiDecodingFailed();
  @override
  String get message => 'Error decodificando respuesta';
}

/// Parsea fechas del backend. NestJS emite ISO8601 con fracciones de segundo
/// (`2024-01-05T10:22:31.482Z`) pero algunos campos vienen sin ellas.
/// `DateTime.parse` acepta ambas; devolvemos `fallback` si el string es basura.
DateTime parseApiDate(dynamic raw, {DateTime? fallback}) {
  if (raw is String && raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toLocal();
  }
  return fallback ?? DateTime.now();
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Mismo backend en producción que consume la app iOS.
  static const String baseUrl =
      'https://floraamazonica-backendapi-production.up.railway.app/api/v1';

  /// Timeout por defecto de iOS (`timeoutInterval: TimeInterval = 10`).
  static const Duration defaultTimeout = Duration(seconds: 10);

  Future<Map<String, String>> _headers({String? token, bool json = true}) async {
    final effectiveToken = token ?? await secureStorage.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (effectiveToken != null) 'Authorization': 'Bearer $effectiveToken',
    };
  }

  /// Equivale a `APIClient.request<T>`: un único punto de entrada para JSON.
  /// Devuelve el cuerpo ya decodificado (`Map`, `List`, o `{}` si viene vacío).
  Future<dynamic> request(
    String endpoint, {
    String method = 'GET',
    Object? body,
    String? token,
    Duration timeout = defaultTimeout,
  }) async {
    final uri = Uri.tryParse('$baseUrl$endpoint');
    if (uri == null) throw const ApiInvalidUrl();

    final headers = await _headers(token: token);
    final encoded = body != null ? jsonEncode(body) : null;

    late final http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encoded != null) request.body = encoded;

      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException {
      throw const ApiNetworkFailure();
    } on HttpException {
      throw const ApiNetworkFailure();
    } catch (_) {
      // TimeoutException y cualquier otro fallo de transporte.
      throw const ApiNetworkFailure();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiRequestFailed(response.statusCode, _extractServerMessage(response.body));
    }

    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const ApiDecodingFailed();
    }
  }

  /// Equivale a `APIClient.uploadMultipart`. El backend espera el archivo bajo
  /// el campo `file` más parámetros de texto sueltos.
  Future<dynamic> uploadMultipart(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    required Map<String, String> parameters,
    String? token,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final uri = Uri.tryParse('$baseUrl$endpoint');
    if (uri == null) throw const ApiInvalidUrl();

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(await _headers(token: token, json: false))
      ..fields.addAll(parameters)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

    late final http.Response response;
    try {
      final streamed = await request.send().timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const ApiNetworkFailure();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiRequestFailed(response.statusCode, _extractServerMessage(response.body));
    }

    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const ApiDecodingFailed();
    }
  }

  // Conveniencias con la misma forma que el resto del código ya usaba.
  Future<dynamic> get(String endpoint, {Duration timeout = defaultTimeout, String? token}) =>
      request(endpoint, timeout: timeout, token: token);

  Future<dynamic> post(String endpoint, {Object? body, Duration timeout = defaultTimeout}) =>
      request(endpoint, method: 'POST', body: body, timeout: timeout);

  Future<dynamic> patch(String endpoint, {Object? body, Duration timeout = defaultTimeout}) =>
      request(endpoint, method: 'PATCH', body: body, timeout: timeout);

  Future<dynamic> delete(String endpoint, {Duration timeout = defaultTimeout}) =>
      request(endpoint, method: 'DELETE', timeout: timeout);

  /// NestJS devuelve `{"message": "..."}` o `{"message": ["err1","err2"]}`
  /// (este último cuando falla el ValidationPipe). iOS maneja ambos casos.
  static String? _extractServerMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final message = decoded['message'];
      if (message is String) return message;
      if (message is List) return message.join(', ');
      if (decoded['error'] is String) return decoded['error'] as String;
    } catch (_) {
      // Cuerpo no-JSON: no hay nada legible que mostrar.
    }
    return null;
  }
}

final apiClient = ApiClient();
