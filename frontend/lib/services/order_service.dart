// order_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading .env
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../food_menu.dart';
import 'auth_service.dart' as auth;
import 'auth/login_auth.dart' as login_auth; // Import the correct auth service
import 'package:flutter/foundation.dart';
import 'shop_service.dart'; // Added import for ShopService
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  WebSocketChannel? _channel;
  String? _currentUserId;
  String? _currentShopId;
  Function(Map<String, dynamic>)? _onStatusUpdate;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  bool get isWebSocketConnected => _channel != null && _channel?.closeCode == null;

  void setOnStatusUpdate(Function(Map<String, dynamic>) callback) {
    _onStatusUpdate = callback;
  }

  Future<Map<String, dynamic>> placeOrder(String userId, String shopId, DateTime pickupTime, String paymentMethod, double totalAmount, List<Map<String, dynamic>> foodItems) async {
    try {
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      
      // Use API_BASE_URL if available, otherwise construct from host
      final uri = baseUrl != null 
          ? Uri.parse('$baseUrl/orders/placeorder')
          : (isSecure 
          ? Uri.https(host, '/api/orders/placeorder')
              : Uri.http(host, '/api/orders/placeorder'));
      
      // Get authentication headers with JWT token
      final token = await auth.AuthService.getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      print("📤 Placing order at: $uri");
      print("🔐 Using token: ${token != null ? 'Yes' : 'No'}");
      print("📦 Order details: User=$userId, Shop=$shopId, Items=${foodItems.length}, Total=$totalAmount");

      // Store original food items with complete details
      final fullFoodItems = List<Map<String, dynamic>>.from(foodItems);
      
      // Debug log items before sending
      for (var item in foodItems) {
        print("   📦 Sending item: food_id=${item['food_id']}, quantity=${item['quantity']}");
      }

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'user_id': userId,
          'shop_id': shopId,
          'pickup_time': pickupTime.toIso8601String(),
          'payment_method': paymentMethod,
          'total_amount': totalAmount,
          'food_items': foodItems,
        }),
      );

      print("📥 Received response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print("🔄 Successfully parsed API response: ${data.keys.join(', ')}");
          
          // Create a complete response with food item details
          final result = {
            'success': true,
            'message': data['message'] ?? 'Order placed successfully',
            'order_id': data['order_id']?.toString() ?? '',
            'otp': data['otp']?.toString() ?? '',
            'shop_id': shopId,
            // Get shop name from shared utility
            'shop_name': await getShopName(shopId),
            'payment_method': paymentMethod,
            'pickup_time': pickupTime.toIso8601String(),
            'total_amount': totalAmount,
            'status': 'pending',
            // Include the FULL food items (not just what was sent to API)
            'items': fullFoodItems,
          };
          
          print("📤 Returning complete order data with food_items: ${result['items'].length} items");
          return result;
        } catch (e) {
          print("❌ Error parsing response: $e");
          return {'success': false, 'message': 'Error processing server response'};
        }
      } else if (response.statusCode == 401) {
        print("❌ Authentication error: User not authorized");
        return {'success': false, 'message': 'Authentication failed. Please log in again.'};
      } else {
        try {
        final error = jsonDecode(response.body);
          return {'success': false, 'message': error['error'] ?? 'Failed to place order'};
        } catch (e) {
          return {'success': false, 'message': 'Server error: ${response.statusCode}'};
        }
      }
    } catch (e) {
      print('❌ Error placing order: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrders(String shopId) async {
    try {
      print("🔄 Fetching orders from backend...");
      
      // Get current user ID
      final userId = await auth.AuthService.getCurrentUserId();
      if (userId == null) {
        print("❌ No user ID found");
        return [];
      }
      
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      
      // Use API_BASE_URL if available, otherwise construct from host
      final uri = baseUrl != null 
          ? Uri.parse('$baseUrl/orders/getorder/$shopId/$userId')  // Modified to include userId
          : (isSecure 
          ? Uri.https(host, '/api/orders/getorder/$shopId/$userId')
              : Uri.http(host, '/api/orders/getorder/$shopId/$userId'));

      print("📤 Fetching orders from: $uri");
      print("👤 Filtering for user ID: $userId");
      
      // Get auth headers
      final headers = await auth.AuthService.getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      print("📥 Received response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("✅ Fetched ${data.length} orders from backend");
        
        // Organize by order_id to group items
        final Map<String, dynamic> ordersMap = {};
        
        for (var item in data) {
          final orderId = item['order_id'].toString();
          
          if (!ordersMap.containsKey(orderId)) {
            ordersMap[orderId] = {
              'order_id': orderId,
              'user_id': item['user_id'],
              'pickup_time': item['pickup_time'],
              'payment_method': item['payment_method'],
              'total_amount': item['total_amount'] is num ? item['total_amount'] : 
                            (item['total_amount'] is String ? 
                             double.tryParse(item['total_amount']) ?? 0.0 : 0.0),
              'otp': item['otp'],
              'status': item['status']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'pending',
              'items': [],
            };
          }
          
          // Add item with all fields from the backend
          ordersMap[orderId]['items'].add({
            'id': item['food_id']?.toString() ?? '',
            'food_id': item['food_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Unknown Item',
            'quantity': item['quantity'] is num ? item['quantity'] : 
                      (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
            'price': item['price'] is num ? item['price'] : 
                    (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
            'description': item['description']?.toString() ?? '',
            'image': item['image']?.toString() ?? '',
            'isVeg': item['type']?.toString().toLowerCase() == 'veg',
            'type': item['type']?.toString() ?? 'veg',
            'category': item['category']?.toString() ?? '',
          });
        }
        
        // Convert to list and calculate totals
        List<Map<String, dynamic>> orders = ordersMap.values.map((order) {
          // Calculate total if not present
          if (order['total_amount'] == 0.0) {
            double total = 0.0;
            for (var item in order['items'] as List) {
              final price = item['price'] as double;
              final quantity = item['quantity'] as int;
              total += price * quantity;
            }
            order['total_amount'] = total;
          }
          return order as Map<String, dynamic>;
        }).toList();
        
        // Debug log
        for (var order in orders) {
          print("📊 Processing order #${order['order_id']}:");
          print("   📅 Status: ${order['status']}");
          print("   💰 Total: ${order['total_amount']}");
          print("   📦 Items: ${order['items'].length}");
          for (var item in order['items']) {
            print("      - ${item['name']} (${item['quantity']}x) @ ₹${item['price']}");
          }
        }
        
        return orders;
      } else {
        print("❌ Error fetching orders: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching orders: $e");
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus, {String? otp, bool verified = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': await _getAuthToken() ?? '',
        },
        body: jsonEncode({
          'order_id': orderId,
          'status': newStatus,
          'otp': otp,
          'verified': verified,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Order status updated successfully");
        
        // Emit status update through WebSocket
        _channel?.sink.add(jsonEncode({
          'type': 'status_update',
          'order_id': orderId,
          'new_status': newStatus,
          'userId': _currentUserId,
          'shopId': _currentShopId,
        }));
        
        return true;
      } else {
        print("❌ Failed to update order status: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error updating order status: $e");
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/updateorder');
      final headers = await auth.AuthService.getAuthHeaders();

      print("📤 Cancelling order #$orderId with reason: $reason");
      
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          'order_id': orderId,
          'status': 'Cancelled',
          'cancel_reason': reason,
          'is_cancellation': true
        }),
      );

      print("📥 Received response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
        return data['status'] == 'Cancelled';
            }
      
      print("❌ Failed to cancel order: ${response.body}");
          return false;
    } catch (e) {
      print("❌ Error cancelling order: $e");
      return false;
    }
  }

  void initializeWebSocket(String userId, String shopId) async {
    try {
      _currentUserId = userId;
      _currentShopId = shopId;
      
      if (baseUrl == null) {
        print("❌ API_BASE_URL not found in environment variables");
        return;
      }
      
      // Parse the base URL
      final uri = Uri.parse(baseUrl);
      final isNgrok = uri.host.contains('ngrok-free.app');
      
      // Construct WebSocket URL
      String wsUrl;
      if (isNgrok) {
        // For ngrok, we need to use wss:// and the ngrok host
        wsUrl = 'wss://${uri.host}/ws';
      } else {
        // For regular URLs, convert http/https to ws/wss
        wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
        wsUrl = '$wsUrl/ws';
      }
      
      // Add query parameters
      final wsUri = Uri.parse(wsUrl).replace(
        queryParameters: {
          'userId': userId,
          'shopId': shopId,
          'transport': 'websocket',
          'EIO': '4',
        }
      );
      
      print("🔌 Connecting to WebSocket at: $wsUri");
      print("👤 User ID: $userId");
      print("🏪 Shop ID: $shopId");

      disconnect(); // Close any existing connection
      
      // Create WebSocket connection with retry logic
      _channel = await _connectWithRetry(wsUri);
      if (_channel == null) {
        print("❌ Failed to establish WebSocket connection after retries");
        _startPolling(); // Fallback to polling
        return;
      }
      
      print("✅ WebSocket connection established");

      // Join specific rooms
      _channel?.sink.add(jsonEncode({
        'type': 'join',
        'rooms': [
          'user_$userId',
          'shop_$shopId',
          'order_updates'
        ]
      }));

      // Set up heartbeat
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_channel == null) {
          timer.cancel();
          return;
        }
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          print("❌ Error sending heartbeat: $e");
          timer.cancel();
          _scheduleReconnect();
        }
      });

      _channel?.stream.listen(
        (message) {
          try {
            print("📥 WebSocket message received: $message");
            final data = jsonDecode(message);
            
            if (data['type'] == 'pong') {
              print("💓 Heartbeat received");
              return;
            }
            
            if (data['type'] == 'connected') {
              print("✅ Connection confirmed by server");
              return;
            }
            
            if (data['type'] == 'status_update') {
              print("🔄 Status update received: ${data['order_id']} -> ${data['new_status']}");
              if (_onStatusUpdate != null) {
                _onStatusUpdate!(data);
              }
              
              // Notify all listeners about the status update
              _notifyStatusUpdate(data);
            }
          } catch (e) {
            print("❌ Error processing WebSocket message: $e");
          }
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
          _scheduleReconnect();
        },
        onDone: () {
          print("📴 WebSocket connection closed");
          _scheduleReconnect();
        },
        cancelOnError: false,
      );

      // Start polling as a fallback
      _startPolling();
      
    } catch (e) {
      print("❌ Error initializing WebSocket: $e");
      _scheduleReconnect();
    }
  }

  Future<WebSocketChannel?> _connectWithRetry(Uri uri, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final ws = WebSocketChannel.connect(uri);
        await ws.ready;
        return ws;
      } catch (e) {
        print("❌ Connection attempt ${i + 1} failed: $e");
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 * (i + 1))); // Exponential backoff
        }
      }
    }
    return null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentUserId != null && _currentShopId != null) {
        print("🔄 Attempting to reconnect WebSocket...");
        initializeWebSocket(_currentUserId!, _currentShopId!);
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isWebSocketConnected && _currentShopId != null) {
        print("📡 Polling for order updates...");
        try {
          final orders = await fetchOrders(_currentShopId!);
          if (_onStatusUpdate != null) {
            for (var order in orders) {
              _onStatusUpdate!({
                'type': 'status_update',
                'order_id': order['order_id'],
                'new_status': order['status'],
              });
            }
          }
        } catch (e) {
          print("❌ Error polling for updates: $e");
        }
      }
    });
  }

  void disconnect() {
    print("🔌 Disconnecting WebSocket");
    _channel?.sink.close();
    _channel = null;
    _reconnectTimer?.cancel();
    _pollingTimer?.cancel();
  }

  Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      print("🔄 Fetching specific order #$orderId from backend...");
      
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      
      // Get auth headers with JWT token
      final headers = await auth.AuthService.getAuthHeaders();
      
      // Use API_BASE_URL if available, otherwise construct from host
      final uri = baseUrl != null 
          ? Uri.parse('$baseUrl/orders/order/$orderId')
          : (isSecure 
          ? Uri.https(host, '/api/orders/order/$orderId')
              : Uri.http(host, '/api/orders/order/$orderId'));

      print("📤 Fetching order from: $uri");
      print("🔑 Using auth headers: ${headers.containsKey('Authorization') ? 'Yes' : 'No'}");
      
      // Try to fetch from backend with proper error handling
      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print("⏱️ Request timed out for order #$orderId");
        throw TimeoutException("Request timed out");
      });

      print("📥 Received response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        // Process successful response
        final data = jsonDecode(response.body);
        print("✅ Successfully fetched order #$orderId from backend");
        
        // Validate total_amount exists and is a number
        final totalAmount = data['total_amount'];
        if (totalAmount == null || !(totalAmount is num) || totalAmount <= 0) {
          print("⚠️ Warning: total_amount is missing or invalid in response: $totalAmount");
          
          // Try to calculate from items
          final items = data['items'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            double calculatedTotal = 0.0;
            for (var item in items) {
              final price = item['price'] is num ? (item['price'] as num).toDouble() :
                           (item['price'] is String ? double.tryParse(item['price'].toString()) ?? 0.0 : 0.0);
              final quantity = item['quantity'] is num ? (item['quantity'] as num).toInt() :
                              (item['quantity'] is String ? int.tryParse(item['quantity'].toString()) ?? 1 : 1);
              calculatedTotal += price * quantity;
            }
            
            if (calculatedTotal > 0) {
              print("📊 Calculated total_amount from items: $calculatedTotal");
              data['total_amount'] = calculatedTotal;
            }
          }
        }
        
        // Create a deep copy of the response data
        final Map<String, dynamic> orderData = Map<String, dynamic>.from(data);
        
        // Get shop_name if missing
        if ((orderData['shop_name'] == null || orderData['shop_name'].toString().isEmpty) && 
            orderData['shop_id'] != null && orderData['shop_id'].toString().isNotEmpty) {
          final shopId = orderData['shop_id'].toString();
          orderData['shop_name'] = await getShopName(shopId);
          print("🏪 Added shop name '${orderData['shop_name']}' for shop ID $shopId");
        }
        
        // Process items to ensure they have full details
        final items = data['items'] as List<dynamic>? ?? [];
        if (items.isEmpty) {
          print("⚠️ Warning: Order has no items from backend");
        } else {
          print("📦 Order has ${items.length} items from backend");
          for (var item in items) {
            print("   📦 Item: ${item['name'] ?? 'Unknown'}, quantity: ${item['quantity'] ?? '?'}, price: ${item['price'] ?? '?'}");
          }
        }
        
        // Make a proper deep copy of items array with all necessary fields
        if (items.isNotEmpty) {
          orderData['items'] = items.map((item) => {
            'id': item['food_id']?.toString() ?? '',
            'food_id': item['food_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Unknown Item',
            'quantity': item['quantity'] is num ? item['quantity'] : 1,
            'price': item['price'] is num ? item['price'] : 
                    (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
            'total_price': (item['price'] is num && item['quantity'] is num) ? 
                          (item['price'] as num) * (item['quantity'] as num) : 0.0,
            'total_item_price': (item['price'] is num && item['quantity'] is num) ? 
                               (item['price'] as num) * (item['quantity'] as num) : 0.0,
            'description': item['description']?.toString() ?? '',
            'image': item['image']?.toString() ?? '',
            'isVeg': item['type'] == 'veg',
            'category': item['category']?.toString() ?? '',
          }).toList();
          
          // Double-check that the total_amount is properly set
          if (orderData['total_amount'] == null || 
              !(orderData['total_amount'] is num) || 
              (orderData['total_amount'] as num) <= 0) {
            
            print("📊 Recalculating total_amount from processed items");
            double calculatedTotal = 0.0;
            final processedItems = orderData['items'] as List<dynamic>;
            
            for (var item in processedItems) {
              final price = item['price'] is num ? (item['price'] as num).toDouble() : 0.0;
              final quantity = item['quantity'] is num ? (item['quantity'] as num).toInt() : 1;
              calculatedTotal += price * quantity;
            }
            
            if (calculatedTotal > 0) {
              print("📊 Updated total_amount: $calculatedTotal");
              orderData['total_amount'] = calculatedTotal;
            }
          }
          
          // Return the order with items
          print("🔄 Returning order with ${orderData['items'].length} items, total_amount: ${orderData['total_amount']}");
          return orderData;
        } else {
          // If no items in response, try alternative approaches to get the items
          return await _fetchOrderItemsAlternatively(orderData, orderId);
        }
      } else if (response.statusCode == 401) {
        print("🔑 Authentication error (401) - Attempting to validate token");
        
        // Try to validate token
        final tokenValid = await login_auth.AuthService.validateToken();
        if (tokenValid) {
          print("🔑 Token is valid, retrying request...");
          // Retry with validated token (recursive call)
          return await fetchOrderById(orderId);
        } else {
          print("❌ Token validation failed");
          // Use alternative approach as fallback
          return await _fetchOrderItemsFromAllOrders(orderId);
        }
      } else if (response.statusCode == 404) {
        print("⚠️ Order #$orderId not found (404)");
        // Try fallback approach
        return await _fetchOrderItemsFromAllOrders(orderId);
      } else {
        print("❌ Server error (${response.statusCode})");
        // Try fallback approach
        return await _fetchOrderItemsFromAllOrders(orderId);
      }
    } catch (e) {
      print("❌ Error fetching order: $e");
      // Try fallback approach
      return await _fetchOrderItemsFromAllOrders(orderId);
    }
  }
  
  // Helper method to fetch order items through alternative means
  Future<Map<String, dynamic>?> _fetchOrderItemsAlternatively(Map<String, dynamic> orderData, String orderId) async {
    print("🔄 Trying alternative approaches to get items for order #$orderId");
    
    try {
      // Try to get this order from the general orders list
      final allOrders = await fetchOrders(orderData['shop_id']?.toString() ?? '');
      print("📋 Fetched ${allOrders.length} orders to search for order #$orderId");
      
      // Find our order in the list
      final matchingOrder = allOrders.firstWhere(
        (order) => order['order_id'].toString() == orderId,
        orElse: () => <String, dynamic>{},
      );
      
      if (matchingOrder.isNotEmpty) {
        final matchingItems = matchingOrder['items'] as List<dynamic>? ?? [];
        if (matchingItems.isNotEmpty) {
          print("🔍 Found ${matchingItems.length} items for order #$orderId from all orders list");
          
          // Capture the total amount from the matching order to ensure we preserve it
          final matchingTotalAmount = matchingOrder['total_amount'];
          print("💰 Total amount from matching order: $matchingTotalAmount");
          
          // Use these items instead
          final List<Map<String, dynamic>> processedItems = matchingItems.map((item) => {
            'id': item['id']?.toString() ?? '',
            'food_id': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Unknown Item',
            'quantity': item['quantity'] is num ? item['quantity'] : 1,
            'price': item['price'] is num ? item['price'] : 
                    (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
            'total_price': (item['price'] is num && item['quantity'] is num) ? 
                          (item['price'] as num) * (item['quantity'] as num) : 0.0,
            'total_item_price': (item['price'] is num && item['quantity'] is num) ? 
                               (item['price'] as num) * (item['quantity'] as num) : 0.0,
            'description': item['description']?.toString() ?? '',
            'image': item['image']?.toString() ?? '',
            'isVeg': item['type'] == 'veg' || item['isVeg'] == true,
            'category': item['category']?.toString() ?? '',
          }).toList();
          
          orderData['items'] = processedItems;
          
          // Calculate total from items if necessary
          if (matchingTotalAmount != null && matchingTotalAmount is num && matchingTotalAmount > 0) {
            // Use the total from the matching order
            orderData['total_amount'] = matchingTotalAmount;
          } else {
            // Calculate total from the processed items
            double calculatedTotal = 0.0;
            for (var item in processedItems) {
              final price = item['price'] is num ? (item['price'] as num).toDouble() : 0.0;
              final quantity = item['quantity'] is num ? (item['quantity'] as num).toInt() : 1;
              calculatedTotal += price * quantity;
            }
            
            if (calculatedTotal > 0) {
              print("📊 Calculated total amount: $calculatedTotal");
              orderData['total_amount'] = calculatedTotal;
            }
          }
          
          print("💰 Final total amount for order #$orderId: ${orderData['total_amount']}");
          return orderData;
        }
      }
    } catch (e) {
      print("⚠️ Error getting items from all orders: $e");
      // Continue to fallback
    }
    
    // If all else fails, create a placeholder based on total amount
    final totalAmount = orderData['total_amount'];
    if (totalAmount != null && totalAmount is num && totalAmount > 0) {
      print("📊 Creating placeholder based on total amount: $totalAmount");
      
      orderData['items'] = [
        {
          'id': 'placeholder',
          'food_id': 'placeholder',
          'name': 'Order Item',
          'quantity': 1,
          'price': totalAmount,
          'total_price': totalAmount,
          'total_item_price': totalAmount,
          'description': '',
          'image': '',
          'isVeg': true,
          'category': '',
        }
      ];
    } else {
      // If no total amount available, try to use a reasonable default
      // or leave as empty items array
      print("⚠️ No total amount available for order #$orderId");
      orderData['items'] = [];
      orderData['total_amount'] = 0.0;
    }
    
    return orderData;
  }
  
  // Helper method to fetch order items directly from all orders endpoint
  Future<Map<String, dynamic>?> _fetchOrderItemsFromAllOrders(String orderId) async {
    try {
      print("🔄 Trying to find order #$orderId in all orders");
      
      // Try to get shop ID from user preferences
      final shopService = ShopService();
      final shopId = await shopService.getStoredShopId();
      if (shopId == null) {
        print("❌ Cannot fetch orders without shop ID");
        return null;
      }
      
      // Fetch all orders for this shop
      final allOrders = await fetchOrders(shopId);
      print("📋 Fetched ${allOrders.length} orders to search for order #$orderId");
      
      // Find our order in the list
      final matchingOrder = allOrders.firstWhere(
        (order) => order['order_id'].toString() == orderId,
        orElse: () => <String, dynamic>{},
      );
      
      if (matchingOrder.isNotEmpty) {
        print("✅ Found order #$orderId in all orders");
        return matchingOrder;
      }
      
      print("❌ Order #$orderId not found in all orders");
      return null;
    } catch (e) {
      print("❌ Error fetching order from all orders: $e");
      return null;
    }
  }

  // Helper method to get shop name by shop ID
  Future<String> getShopName(String shopId) async {
    try {
      // First, try to fetch from ShopService
      final shopService = ShopService();
      final shops = await shopService.fetchShops();
      
      // Look for matching shop ID in fetched shops
      for (var shop in shops) {
        if (shop.id?.toString() == shopId) {
          print("🏪 Found shop name '${shop.name}' for shop ID $shopId");
          return shop.name;
        }
      }
      
      // If not found, use a fallback naming convention
      return 'Shop #$shopId';
    } catch (e) {
      print("❌ Error getting shop name: $e");
      return 'Unknown Shop';
    }
  }

  // This method gets shop name from SharedPreferences if available (used as a backup)
  Future<String?> _getStoredShopName(String shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedOrdersJson = prefs.getString('completed_orders') ?? '[]';
      
      try {
        final completedOrders = jsonDecode(completedOrdersJson) as List;
        
        // Find any order with matching shop ID and shop name
        for (var order in completedOrders) {
          if (order is Map && 
              order['shop_id']?.toString() == shopId && 
              order['shop_name'] != null) {
            print("🏪 Found cached shop name '${order['shop_name']}' for shop ID $shopId");
            return order['shop_name'].toString();
          }
        }
      } catch (e) {
        print("❌ Error parsing stored orders: $e");
      }
      
      return null;
    } catch (e) {
      print("❌ Error getting stored shop name: $e");
      return null;
    }
  }

  // List of status update callbacks
  final List<Function(Map<String, dynamic>)> _statusUpdateCallbacks = [];

  // Add a new status update listener
  void addStatusUpdateListener(Function(Map<String, dynamic>) callback) {
    _statusUpdateCallbacks.add(callback);
  }

  // Remove a status update listener
  void removeStatusUpdateListener(Function(Map<String, dynamic>) callback) {
    _statusUpdateCallbacks.remove(callback);
  }

  // Notify all listeners about a status update
  void _notifyStatusUpdate(Map<String, dynamic> data) {
    for (var callback in _statusUpdateCallbacks) {
      callback(data);
    }
  }
}
