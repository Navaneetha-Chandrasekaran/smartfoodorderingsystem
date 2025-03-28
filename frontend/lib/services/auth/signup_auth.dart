import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupAuth {
  final String baseUrl = 'http://10.0.2.2:3000/api/auth'; // ✅ Use correct API URL

  /// ✅ **Register Student**
  Future<Map<String, dynamic>> registerStudent(
      String name, String email, String phone, String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/register/student'); // ✅ Correct API endpoint

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
