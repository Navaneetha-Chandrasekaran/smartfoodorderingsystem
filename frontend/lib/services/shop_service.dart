import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/shop.dart';

class ShopService {
  // You can remove the hardcoded value and get the shop ID dynamically from the selected shop
  Future<int?> getSelectedShopId(Shop selectedShop) async {
    return int.tryParse(selectedShop.id); // Assuming 'id' is a string, and you want to parse it into an integer
  }

  Future<List<Shop>> fetchShops() async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final Uri url = Uri.parse('$baseUrl/shop/get-shops'); // 👈 No query param
    print('Request URL: $url');

    try {
      final response = await http.get(url);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');  // Log the response body

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['shops'] != null) {
          final shops = data['shops'] as List;
          return shops.map((shop) => Shop.fromJson(shop)).toList();
        } else {
          throw Exception('Shops not found in response');
        }
      } else {
        throw Exception('Failed to load shops: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');  // Log the error if the request fails
      throw Exception('Error fetching shops: $e');
    }
  }
}
