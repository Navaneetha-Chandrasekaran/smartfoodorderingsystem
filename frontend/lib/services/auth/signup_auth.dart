import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// class SignupAuth {
//   final String baseUrl = dotenv.env['API_BASE_URL']!; // ✅ Use correct API URL

//   /// ✅ **Register Student**
//   Future<Map<String, dynamic>> registerStudent(
//       String name, String email, String phone, String password, String confirmPassword) async {
//     final url = Uri.parse('$baseUrl/auth/register/student'); // ✅ Correct API endpoint

//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'name': name,
//           'email': email,
//           'phone': phone,
//           'password': password,
//           'confirmPassword': confirmPassword,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return {'success': true, 'message': data['message'], 'email': data['email']};
//       } else {
//         final error = json.decode(response.body);
//         return {'success': false, 'message': error['message']};
//       }
//     } catch (e) {
//       return {'success': false, 'message': 'Server error: $e'};
//     }
//   }
// }

class SignupAuth {
  final String baseUrl = dotenv.env['API_BASE_URL']!;
  final storage = FlutterSecureStorage(); // For securely storing user ID

  /// ✅ **Register Student**
  Future<Map<String, dynamic>> registerStudent(
      String name, String email, String phone, String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/auth/register/student');

    try {
      print('🔄 Attempting to register student...');
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

      print('📥 Registration response status: ${response.statusCode}');
      print('📥 Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // If registration returns a token (normally would happen after OTP verification)
        if (data['token'] != null) {
          final token = data['token'];
          final userId = data['userId']?.toString();

          // Store user data in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          
          if (userId != null) {
            await prefs.setString('userId', userId);
          }
          
          await prefs.setString('email', email);
          await prefs.setString('name', name);
          await prefs.setString('role', data['role'] ?? 'student');
        }

        // Check if there was a warning about OTP sending
        if (data['warning'] != null) {
          print('⚠️ Warning from server: ${data['warning']}');
          return {
            'success': true,
            'message': data['message'],
            'email': data['email'],
            'userId': data['userId'],
            'warning': data['warning'],
            'needsOtpResend': true
          };
        }

        return {
          'success': true,
          'message': data['message'],
          'email': data['email'],
          'userId': data['userId'],
        };
      } else {
        final error = json.decode(response.body);
        print('❌ Registration error: ${error['message']}');
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      print('❌ Registration exception: $e');
      return {'success': false, 'message': 'Server error: $e'};
    }
  }

  // To retrieve the userId from secure storage later
  Future<String?> getUserId() async {
    return await storage.read(key: 'userId');
  }
}


class CanteenReg {
  final String baseUrl = dotenv.env['API_BASE_URL']!; // ✅ Use correct API URL

  /// ✅ **Register Canteen Staff**
  Future<Map<String, dynamic>> registerCanteenStaff(
      String name, String email, String phone, String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/auth/register/canteenstaff'); // Updated API endpoint for canteen staff

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

      // Check if the response is a valid JSON response
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          // If registration returns a token (normally would happen after OTP verification)
          if (data['token'] != null) {
            final token = data['token'];
            final userId = data['userId']?.toString();

            // Store user data in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            
            if (userId != null) {
              await prefs.setString('userId', userId);
            }
            
            await prefs.setString('email', email);
            await prefs.setString('name', name);
            await prefs.setString('role', data['role'] ?? 'canteen_staff');
          }
          
          return {'success': true, 'message': data['message'], 'email': data['email']};
        } catch (e) {
          return {'success': false, 'message': 'Invalid JSON response: $e'};
        }
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'API not found. Check the endpoint.'};
      } else if (response.statusCode == 500) {
        return {'success': false, 'message': 'Server error. Try again later.'};
      } else {
        return {'success': false, 'message': 'Unexpected error occurred: ${response.statusCode}'};
      }
    } catch (e) {
      // Handle errors like network issues or invalid URL
      return {'success': false, 'message': 'Server error: $e'};
    }
  }
}
