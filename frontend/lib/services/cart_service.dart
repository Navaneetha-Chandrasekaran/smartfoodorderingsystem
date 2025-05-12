import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/cart_item.dart';

class CartService {
  // Get base URL from environment
  String get baseUrl {
    final apiUrl = dotenv.env['API_BASE_URL'];
    print("🛒 Cart Service using API URL: $apiUrl");
    return apiUrl ?? 'http://localhost:5000/api';
  }

  // Fetch cart items
  Future<List<CartItem>> getCartItems(String userId) async {
    final Uri url = Uri.parse('$baseUrl/cart/view/$userId');
    print("🛒 Fetching cart items from: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> cartData = json.decode(response.body);
        return cartData.map((item) => CartItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load cart items');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Add item to cart
  Future<Map<String, dynamic>> addToCart(String userId, String shopId, String foodId) async {
    final Uri url = Uri.parse('$baseUrl/cart/add');
    print("🛒 Adding to cart at: $url");

    // Ensure userId is a valid integer
    final int? parsedUserId = int.tryParse(userId);
    if (parsedUserId == null) {
      print('❌ Invalid user ID format: $userId');
      return {
        'success': false,
        'message': 'Invalid user ID format'
      };
    }

    final payload = {
      'user_id': parsedUserId,
      'shop_id': shopId,
      'food_id': foodId,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Item added to cart successfully'
        };
      } else {
        // Handle error response
        final errorMessage = responseData['error'] ?? 
                           responseData['message'] ?? 
                           'Failed to add item to cart';
        print('Cart error: $errorMessage'); // Debug log
        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      print('Network error adding to cart: $e'); // Debug log
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection and try again.'
      };
    }
  }

  // Remove item from cart
  Future<Map<String, dynamic>> removeFromCart(String cartId) async {
    final Uri url = Uri.parse('$baseUrl/cart/remove/$cartId');
    print("🛒 Removing from cart: $url");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Item removed from cart!'};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Clear the cart
  Future<Map<String, dynamic>> clearCart(String userId) async {
    final Uri url = Uri.parse('$baseUrl/cart/clear/$userId');
    print("🛒 Clearing cart: $url");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cart cleared!'};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
