import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CanteenOrderService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  Future<List<Map<String, dynamic>>> fetchCanteenOrders(String shopId) async {
    final Uri url = Uri.parse('$baseUrl/orders/getorder/$shopId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Group items by order_id
        final Map<String, List<Map<String, dynamic>>> orderItemsMap = {};
        for (var item in data) {
          final orderId = item['order_id'].toString();
          orderItemsMap.putIfAbsent(orderId, () => []);
          orderItemsMap[orderId]!.add({
            'id': item['food_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'quantity': item['quantity'] ?? 1,
            'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
            'description': item['description']?.toString() ?? '',
            'image': item['image']?.toString() ?? '',
          });
        }
        // Build orders list
        final List<Map<String, dynamic>> orders = [];
        final Set<String> processedOrderIds = {};
        for (var item in data) {
          final orderId = item['order_id'].toString();
          if (processedOrderIds.contains(orderId)) continue;
          processedOrderIds.add(orderId);
          orders.add({
            'order_id': orderId,
            'user_id': item['user_id'],
            'pickup_time': item['pickup_time'],
            'payment_method': item['payment_method'],
            'total_amount': double.tryParse(item['total_amount']?.toString() ?? '0') ?? 0.0,
            'otp': item['otp'],
            'status': item['status'],
            'items': orderItemsMap[orderId] ?? [],
          });
        }
        return orders;
      } else {
        throw Exception('Failed to fetch canteen orders');
      }
    } catch (e) {
      print('Error fetching canteen orders: $e');
      return [];
    }
  }
} 