import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class CartService {
  final String baseUrl = dotenv.env['API_BASE_URL']!;

  // Add item to cart
  Future<Map<String, dynamic>> addToCart(String userId, String shopId, String foodId) async {
    final Uri url = Uri.parse('$baseUrl/cart/add');

    final payload = {
      'user_id': userId,
      'shop_id': shopId,
      'food_id': foodId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Item added to cart!'};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
