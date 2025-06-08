import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// ✅ User Login
  Future<Map<String, dynamic>> loginUser(String email, String password, String loginType) async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final String loginUrl = '$baseUrl/auth/login';
    final Uri url = Uri.parse(loginUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'loginType': loginType
        }),
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📦 Decoded JSON: $data");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Store JWT token
        final token = data['token'];
        if (token == null) {
          print("⚠️ Warning: No token received from server");
          return {
            'success': false,
            'message': 'Login failed: No authentication token received'
          };
        }
        
        await prefs.setString('token', token);
        print("🔑 Storing JWT token: $token");

        // Store user data
        final userId = data['userId']?.toString();
        print("🔑 Storing user ID: $userId");
        if (userId != null && userId.isNotEmpty) {
          await prefs.setString('userId', userId);
        } else {
          print("⚠️ Warning: No user ID received from server");
        }
        
        final email = data['email']?.toString();
        print("📧 Storing email: $email");
        await prefs.setString('email', email ?? '');
        
        final name = data['name']?.toString();
        print("👤 Storing name: $name");
        await prefs.setString('name', name ?? '');
        
        final role = data['role']?.toString();
        print("👑 Storing role: $role");
        await prefs.setString('role', role ?? '');

        // Store shop_id for canteen staff
        if (role == 'canteen_staff') {
          final shopId = data['shop_id']?.toString();
          print("🏪 Storing shop_id: $shopId");
          if (shopId != null) {
            await prefs.setString('shop_id', shopId);
          } else {
            print("⚠️ Warning: No shop_id received for canteen staff");
          }
        }

        // Verify the stored data
        final storedToken = prefs.getString('token');
        print("✅ Verified stored token: ${storedToken != null ? 'Token exists' : 'Token missing'}");

        return {
          'success': true, // Explicitly set success flag
          'message': data['message'] ?? 'Login successful',
          'role': data['role'],
        };
      } else {
        try {
          final error = json.decode(response.body);
          print("⚠️ Login error response: $error");
          return {
            'success': false,
            'message': error['message'] ?? 'Login failed with status ${response.statusCode}',
          };
        } catch (e) {
          print("⚠️ Error parsing login error response: $e");
          return {
            'success': false,
            'message': 'Login failed with status ${response.statusCode}',
          };
        }
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
  static Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

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
    print("👋 User logged out. Local data and token cleared.");
  }

  // Check if token is valid by making a test request
  static Future<bool> validateToken() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        print("⚠️ No token found");
        return false;
      }
      
      final String baseUrl = dotenv.env['API_BASE_URL']!;
      final String validateUrl = '$baseUrl/auth/validate-token';
      final Uri url = Uri.parse(validateUrl);
      
      final response = await http.get(
        url,
        headers: await getAuthHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Token validation error: $e");
      return false;
    }
  }

  // Helper method to convert frontend status format to backend format
  String _convertToBackendStatusFormat(String frontendStatus) {
    // Map of frontend status (lowercase_with_underscores) to backend status (Title Case With Spaces)
    final statusMap = {
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready_for_pickup': 'Ready for Pickup',
      'completed': 'Delivered', // Backend uses "Delivered" instead of "Completed"
    };
    
    return statusMap[frontendStatus] ?? frontendStatus;
  }
}
