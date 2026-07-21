import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final res = await http.get(Uri.parse('https://floraamazonica-backendapi-production.up.railway.app/api/v1/especies'));
  print('Status: ${res.statusCode}');
  if (res.statusCode == 200) {
    final List data = jsonDecode(res.body);
    if (data.isNotEmpty) {
      print('Keys: ${data.first.keys}');
      print('First item: ${data.first}');
    } else {
      print('Empty list');
    }
  }
}
