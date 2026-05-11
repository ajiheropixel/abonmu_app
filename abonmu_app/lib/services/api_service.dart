import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Gunakan IP komputer Anda
  static const String baseUrl = 'http://10.73.13.106:3000';

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('📤 GET: $url');

      final response = await http.get(url);
      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Gagal koneksi ke server: $e');
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('📤 POST: $url');
      print('📦 Body: $body');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Gagal koneksi ke server: $e');
    }
  }
}
