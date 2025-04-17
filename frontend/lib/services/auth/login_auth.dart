import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {

  /// ✅ **User Login**
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final String loginUrl = '$baseUrl/auth/login';
    final Uri url = Uri.parse(loginUrl);

    try {
      print("🔗 Connecting to API: $url"); // Debugging log

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message'], 'role': data['role']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      print("❌ API Request Error: $e");
      return {'success': false, 'message': 'Server error: $e'};
    }
  }
}


