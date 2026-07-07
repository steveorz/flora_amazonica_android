import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  
  @override
  String toString() => "ApiException(status: $statusCode, message: $message)";
}

class ApiClient {
  // Para Android Emulator el localhost de la maquina es 10.0.2.2.
  // Si usamos dispositivo físico, cambiar a la IP del Wi-Fi.
  final String baseUrl = "http://10.0.2.2:3000"; 
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await secureStorage.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();
    
    final response = await http.post(
      url, 
      headers: headers, 
      body: body != null ? jsonEncode(body) : null
    );
    return _handleResponse(response);
  }
  
  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();
    
    final response = await http.patch(
      url, 
      headers: headers, 
      body: body != null ? jsonEncode(body) : null
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = await _getHeaders();
    
    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

final apiClient = ApiClient();
