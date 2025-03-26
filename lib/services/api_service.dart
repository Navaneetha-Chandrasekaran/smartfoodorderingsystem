import 'dart:convert';
import 'package:http/http.dart' as http;

import '../food.dart';

class ApiService {
  final String apiUrl = 'https://run.mocky.io/v3/d4a8c26d-4e75-4ee8-88dd-bbad2e20d876'; // Your Mocky URL

  Future<List<Food>> fetchFoodMenu() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Parse the JSON data
        List<dynamic> jsonData = json.decode(response.body);

        // Map the JSON data to a List of Food objects
        return jsonData.map((foodJson) => Food.fromJson(foodJson)).toList();
      } else {
        throw Exception('Failed to load menu');
      }
    } catch (e) {
      throw Exception('Failed to load menu: $e');
    }
  }
}
