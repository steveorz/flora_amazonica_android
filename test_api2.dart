import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final res = await http.post(
    Uri.parse('https://floraamazonica-backendapi-production.up.railway.app/api/v1/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'test@test.com', 'password': '123'}),
  );
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
