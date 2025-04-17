import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// ✅ **User Login**
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final String loginUrl = '$baseUrl/auth/login';
    final Uri url = Uri.parse(loginUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Store user data in local storage
        await prefs.setString('userId', data['userId'].toString());
        await prefs.setString('email', data['email']);
        await prefs.setString('name', data['name']);

        // Print stored values to the console
        print("✅ Stored user data:");
        print("UserId: ${prefs.getString('userId')}");
        print("Email: ${prefs.getString('email')}");
        print("Name: ${prefs.getString('name')}");

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

  /// ✅ **Get Current User ID as int**
  static Future<int?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userIdString = prefs.getString('userId');
    print("Fetched userId: $userIdString");

    if (userIdString != null && userIdString.isNotEmpty) {
      return int.tryParse(userIdString);
    }
    return null;
  }

  /// ✅ **Optional Getters**
  static Future<String?> getCurrentEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  static Future<String?> getCurrentName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Future<String?> getCurrentRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  /// ✅ **Logout**
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // clears all stored user data
  }
}
