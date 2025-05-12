import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/login_auth.dart' as auth;

class OrderStatusService {
  // Verify OTP and update order status
  Future<bool> verifyOtpAndUpdateStatus(String orderId, String otp, String newStatus) async {
    try {
      // Get host configuration
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      
      print("🔧 API Configuration - Host: $host, Secure: $isSecure");
      
      // Construct the URI for updating order status
      final uri = isSecure
          ? Uri.https(host, '/api/orders/updateorder')
          : Uri.http(host, '/api/orders/updateorder');
      
      // Get auth headers with JWT token
      final headers = await auth.AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      print("📤 Updating order #$orderId status to $newStatus with OTP verification");
      
      // Add OTP verification to the request
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'status': newStatus,
          'otp': otp, // Include the OTP for verification
          'verified': true, // Flag to indicate OTP verification happened
        }),
      );
      
      print("📥 Status update response: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        print("✅ Order status updated successfully");
        return true;
      } else {
        final errorResponse = jsonDecode(response.body);
        print("❌ Error updating order status: ${errorResponse['error'] ?? 'Unknown error'}");
        return false;
      }
    } catch (e) {
      print("❌ Exception updating order status: $e");
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Check if environment variables are loaded properly
      final baseApiUrl = dotenv.env['API_BASE_URL'];
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      
      print("🔧 API Configuration - Base URL: $baseApiUrl, Host: $host, Secure: $isSecure");
      
      // Construct the URI for updating order status
      final uri = isSecure
          ? Uri.https(host, '/api/orders/updateorder')
          : Uri.http(host, '/api/orders/updateorder');
      
      // Get auth headers with JWT token
      final headers = await auth.AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      print("📤 Updating order #$orderId status to $newStatus");
      
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'status': newStatus,
        }),
      );
      
      print("📥 Status update response: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        print("✅ Order status updated successfully");
        return true;
      } else {
        final errorResponse = jsonDecode(response.body);
        print("❌ Error updating order status: ${errorResponse['error'] ?? 'Unknown error'}");
        return false;
      }
    } catch (e) {
      print("❌ Exception updating order status: $e");
      return false;
    }
  }
} 