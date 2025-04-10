import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // make sure this is in pubspec
import '../food.dart';

class FoodService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api';

  Future<List<Food>> fetchFoodItems({int? shopId, String? category}) async {
    try {
      Uri uri = Uri.parse("$_baseUrl/admin/foodItems").replace(queryParameters: {
        if (shopId != null) 'shop_id': shopId.toString(),
        if (category != null) 'category': category,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Food.fromJson(_convertJson(item))).toList();
      } else {
        throw Exception('Failed to load food items');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Optional: Convert backend JSON format to Flutter's expected format
  Map<String, dynamic> _convertJson(Map<String, dynamic> json) {
    return {
      'name': json['name'],
      'description': json['description'],
      'image': json['image'], // You might need to handle URLs here
      'price': json['price'],
      'category': json['category'],
      'availableQuantity': 10, // If backend doesn’t provide, use default
      'availableAddons': [], // Placeholder if not available in backend
      'isVeg': json['type'] == 'veg',
    };
  }
}
