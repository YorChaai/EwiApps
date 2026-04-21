import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() async {
  final url = Uri.parse('http://127.0.0.1:5000/api/auth/login');
  final loginRes = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': 'manager1', 'password': 'manager12345'}),
  );
  if (loginRes.statusCode != 200) {
    debugPrint('Login failed: ${loginRes.body}');
    return;
  }
  final token = jsonDecode(loginRes.body)['token'];

  final setUrl = Uri.parse('http://127.0.0.1:5000/api/settlements');
  final setRes = await http.get(
    setUrl,
    headers: {'Authorization': 'Bearer $token'},
  );
  debugPrint('Settlements status: ${setRes.statusCode}');

  try {
    final res = jsonDecode(setRes.body);
    final settlements = List<Map<String, dynamic>>.from(res['settlements']);
    debugPrint('Success! Parsed ${settlements.length} items.');
  } catch (e) {
    debugPrint('Error parsing: $e');
  }
}
