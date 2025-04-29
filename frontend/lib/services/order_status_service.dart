import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrderStatusService {
  String get _baseUrl => '${dotenv.env['API_BASE_URL']}/orders/updateorder';

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'status': newStatus,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] != null;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
} 