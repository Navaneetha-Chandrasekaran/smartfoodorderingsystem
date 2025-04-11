import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/shop.dart';

class ShopService {
  Future<List<Shop>> fetchShops() async {
    final String baseUrl = dotenv.env['API_BASE_URL']!;
    final Uri url = Uri.parse('$baseUrl/api/shop/get-shops');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shops = data['shops'] as List;
        return shops.map((shop) => Shop.fromJson(shop)).toList();
      } else {  
        throw Exception('Failed to load shops');
      }
    } catch (e) {
      throw Exception('Error fetching shops: $e');
    }
  }
}
