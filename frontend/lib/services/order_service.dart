// order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading .env
import '../models/cart_item.dart';

class OrderService {
  final String apiUrl = dotenv.env['API_BASE_URL'] ?? "http://localhost:5000/api";

  // Place order function
  Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required String shopId,
    required String pickupTime,
    required String paymentMethod,
    required double totalAmount,
    required List<CartItem> cartItems,
  }) async {
    final url = Uri.parse('$apiUrl/orders/placeorder'); // API endpoint for placing the order

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'user_id': userId,
      'shop_id': shopId,
      'pickup_time': pickupTime,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'food_items': cartItems.map((cartItem) {
        return {
          'food_id': cartItem.food.id, // Assuming cartItem has `food` object with `id`
          'quantity': cartItem.quantity,
        };
      }).toList(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return json.decode(response.body); // Return OTP and success response
      } else {
        return {'error': 'Failed to place order. Please try again later.'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }
}
