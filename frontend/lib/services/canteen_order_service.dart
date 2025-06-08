import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CanteenOrderService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<List<Map<String, dynamic>>> fetchCanteenOrders() async {
    try {
      print('🔄 Attempting to fetch canteen orders...');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final shopId = prefs.getString('shop_id');
      final role = prefs.getString('role');

      print('📝 Token available: ${token != null}');
      print('🏪 Shop ID: $shopId');
      print('👤 Role: $role');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      if (shopId == null) {
        throw Exception('No shop assigned to this canteen staff');
      }

      if (role != 'canteen_staff') {
        throw Exception('Invalid role for fetching canteen orders');
      }

      final url = '$baseUrl/auth/canteen/orders/$shopId';
      print('🌐 Fetching orders from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status code: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final orders = data.map((item) => item as Map<String, dynamic>).toList();
        print('✅ Successfully fetched ${orders.length} orders');
        
        // Log each order for debugging
        orders.forEach((order) {
          print('📋 Order #${order['order_id']}: Status=${order['status']}, Items=${order['items']?.length ?? 0}');
        });
        
        return orders;
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed. Token: ${token.substring(0, 10)}...');
        throw Exception('Unauthorized: Please log in again');
      } else if (response.statusCode == 403) {
        print('❌ Access forbidden. Shop ID: $shopId, Role: $role');
        throw Exception('Forbidden: You do not have access to these orders');
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch orders: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching canteen orders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }
} 