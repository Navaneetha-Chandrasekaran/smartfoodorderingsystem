import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// ✅ User Login
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
        print("📦 Decoded JSON: $data");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Store user data locally with detailed logging
        final userId = data['userId']?.toString();
        print("🔑 Storing user ID: $userId");
        if (userId != null && userId.isNotEmpty) {
          await prefs.setString('userId', userId);
        } else {
          print("⚠️ Warning: No user ID received from server");
          return {
            'success': false,
            'message': 'Login failed: No user ID received'
          };
        }
        
        final email = data['email']?.toString();
        print("📧 Storing email: $email");
        await prefs.setString('email', email ?? '');
        
        final name = data['name']?.toString();
        print("👤 Storing name: $name");
        await prefs.setString('name', name ?? '');

        // Verify the stored data
        final storedUserId = prefs.getString('userId');
        print("✅ Verified stored user ID: $storedUserId");

        return {
          'success': true,
          'message': data['message'],
          'role': data['role'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print("❌ API Request Error: $e");
      return {
        'success': false,
        'message': 'Server error: $e',
      };
    }
  }

  // ✅ Global Static Getters

  static Future<int?> getCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('userId');
      print("🔍 Retrieved userId from SharedPreferences: $userIdString");

      if (userIdString == null) {
        print("⚠️ No userId found in SharedPreferences");
        return null;
      }

      if (userIdString.isEmpty) {
        print("⚠️ Empty userId string found in SharedPreferences");
        return null;
      }

      final userId = int.tryParse(userIdString);
      print("🔢 Parsed userId: $userId");
      return userId;
    } catch (e) {
      print("❌ Error getting current user ID: $e");
      return null;
    }
  }

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

  // ✅ Logout
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("👋 User logged out. Local data cleared.");
  }
}
