import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SignupAuth {
  final String baseUrl = dotenv.env['API_BASE_URL']!; // ✅ Use correct API URL

  /// ✅ **Register Student**
  Future<Map<String, dynamic>> registerStudent(
      String name, String email, String phone, String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/auth/register/student'); // ✅ Correct API endpoint

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message'], 'email': data['email']};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Server error: $e'};
    }
  }
}
