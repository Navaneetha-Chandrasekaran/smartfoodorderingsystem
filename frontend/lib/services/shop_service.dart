import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop.dart';

class ShopService {
  // Fetch the list of shops from the backend
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

  // Store the shop ID in local storage
  Future<void> storeSelectedShopId(String? shopId) async {
    if (shopId == null) {
      print("Cannot store null Shop ID");
      return;
    }
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isStored = await prefs.setString('selectedShopId', shopId);
      if (isStored) {
        print("Shop ID stored successfully: $shopId");
      } else {
        print("Failed to store Shop ID.");
      }
    } catch (e) {
      print("Error storing Shop ID: $e");
    }
  }

  // Fetch the selected shop ID from local storage
  Future<String?> getStoredShopId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? shopId = prefs.getString('selectedShopId');
      print("Fetched Shop ID: $shopId");
      return shopId;
    } catch (e) {
      print("Error fetching Shop ID: $e");
      return null;
    }
  }

  // Get shop ID dynamically from the selected shop (assumes `Shop` has an `id` field)
  Future<int?> getSelectedShopId(Shop selectedShop) async {
    if (selectedShop.id == null) {
      print("Shop has null ID");
      return null;
    }
    
    try {
      int? shopId = int.tryParse(selectedShop.id!); // Using null assertion since we already checked above
      print("Selected Shop ID: $shopId");
      return shopId;
    } catch (e) {
      print("Error parsing Shop ID: $e");
      return null;
    }
  }
}
