import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../food.dart';

class FoodService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';

  Future<List<Food>> fetchFoodItems({int? shopId, String? category, String? type}) async {
    try {
      Uri uri = Uri.parse("$_baseUrl/food/getfoods").replace(queryParameters: {
        if (shopId != null) 'shop_id': shopId.toString(),
        if (category != null) 'category': category,
        if (type != null) 'type': type,
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

  Map<String, dynamic> _convertJson(Map<String, dynamic> json) {
    return {
      'name': json['name'],
      'description': json['description'],
      'image': json['image'],
      'price': json['price'],
      'category': json['category'],
      'availableQuantity': 10,
      'availableAddons': [],
      'type': json['type'], // ✅ FIXED HERE: Pass the backend 'type' key directly
    };
  }
}
