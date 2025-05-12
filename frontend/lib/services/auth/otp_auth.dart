import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpService {
  final String baseUrl = dotenv.env['API_BASE_URL']!; // ✅ Correct API URL

  /// ✅ **Verify OTP**
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      /// ✅ **Check if Response is JSON**
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if verification returns a token (it should after successful verification)
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          
          // Store the JWT token
          await prefs.setString('token', data['token']);
          
          // Store user data if provided
          if (data['userId'] != null) {
            await prefs.setString('userId', data['userId'].toString());
          }
          
          if (data['email'] != null) {
            await prefs.setString('email', data['email']);
          }
          
          if (data['name'] != null) {
            await prefs.setString('name', data['name']);
          }
          
          if (data['role'] != null) {
            await prefs.setString('role', data['role']);
          }
        }
        
        return {'success': true, 'message': data['message']};
      } else {
        /// ✅ **Check for HTML Error Page (Non-JSON Response)**
        if (response.body.startsWith('<!DOCTYPE html>')) {
          return {'success': false, 'message': 'Unexpected server error. Please try again later.'};
        }

        /// ✅ **Handle Proper JSON Error**
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Server error: $e'};
    }
  }
}
