import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Untuk emulator Android - localhost komputer
  static const String baseUrl = 'http://localhost:3000';

  // Atau bisa juga pakai ini:
  // static const String baseUrl = 'http://127.0.0.1:3000';

  static String? _authToken;

  static void setToken(String token) {
    _authToken = token;
    print('✅ Token saved: $token');
  }

  static void clearToken() {
    _authToken = null;
    print('✅ Token cleared');
  }

  static String? getToken() {
    return _authToken;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('\n📤 GET: $url');

    final response = await http.get(
      url,
      headers: _getHeaders(),
    );

    print('📥 Status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('\n📤 POST: $url');
    print('📦 Body: $body');

    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    print('📥 Status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
}
