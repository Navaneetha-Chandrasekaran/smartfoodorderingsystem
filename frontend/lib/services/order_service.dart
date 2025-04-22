// order_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading .env
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../food_menu.dart';

class OrderService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? _onStatusUpdate;
  String? _currentUserId;
  String? _currentShopId;
  Timer? _reconnectTimer;

  bool get isWebSocketConnected => _channel != null && _channel?.closeCode == null;

  void setOnStatusUpdate(Function(Map<String, dynamic>) callback) {
    _onStatusUpdate = callback;
  }

  Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required String shopId,
    required String pickupTime,
    required String paymentMethod,
    required double totalAmount,
    required List<CartItem> cartItems,
    required BuildContext context,
  }) async {
    try {
      print("🚀 Starting order placement process...");
      print("📦 Order details - UserID: $userId, ShopID: $shopId, PickupTime: $pickupTime");
      print("💰 Payment: $paymentMethod, Total: $totalAmount");
      print("🛒 Cart items count: ${cartItems.length}");

      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final uri = isSecure
          ? Uri.https(host, '/api/orders/placeorder')
          : Uri.http(host, '/api/orders/placeorder');

      print("🌐 Making API request to: $uri");

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'shop_id': shopId,
          'pickup_time': pickupTime,
          'payment_method': paymentMethod,
          'total_amount': totalAmount,
          'food_items': cartItems.map((item) => {
            'food_id': item.food.id,
            'quantity': item.quantity,
          }).toList(),
        }),
      );

      print("📥 API Response Status: ${response.statusCode}");
      print("📥 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Order placed successfully!");
        print("📋 Order ID: ${data['order_id']}");
        print("🔑 OTP: ${data['otp']}");
        
        // Initialize WebSocket connection
        try {
          print("🔌 Initializing WebSocket connection...");
          initializeWebSocket(userId, shopId);
        } catch (e) {
          print("⚠️ WebSocket initialization failed: $e");
          _startPolling(userId, shopId);
        }

        // Navigate to timeline screen with order details
        if (context.mounted) {
          print("🔄 Navigating to timeline screen...");
          final orderData = {
            'order_id': data['order_id'].toString(),
            'otp': data['otp'].toString(),
            'items': cartItems.map((item) => {
              'id': item.food.id,
              'name': item.food.name,
              'quantity': item.quantity,
              'price': item.food.price,
              'description': item.food.description,
              'image': item.food.image,
              'isVeg': item.food.isVeg,
              'total_item_price': item.food.price * item.quantity,
            }).toList(),
            'payment_mode': paymentMethod,
            'pickup_time': pickupTime,
            'total_amount': totalAmount,
          };

          // Store the order data in FoodMenu
          await Provider.of<FoodMenu>(context, listen: false).setLatestOrderData(orderData);

          if (context.mounted) {
            print("🔄 Navigating to timeline screen with order data: $orderData");
            Navigator.pushReplacementNamed(
              context,
              '/timeline',
              arguments: orderData,
            );
          }
        }
        
        return {
          'success': true,
          'order_id': data['order_id'],
          'otp': data['otp'],
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        print("❌ Order placement failed!");
        print("📝 Error details: ${error['error'] ?? 'Unknown error'}");
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to place order'
        };
      }
    } catch (e) {
      print("❌ Exception during order placement!");
      print("📝 Error: $e");
      return {
        'success': false,
        'error': 'Error placing order: $e'
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrders(String shopId) async {
    try {
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final uri = isSecure
          ? Uri.https(host, '/api/orders/getorder/$shopId')
          : Uri.http(host, '/api/orders/getorder/$shopId');

      print("📤 Fetching orders from: $uri");
      final response = await http.get(uri);

      print("📥 Received response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((order) => order as Map<String, dynamic>).toList();
        } catch (e) {
          print("❌ Error parsing response: $e");
          return [];
        }
      } else {
        print("❌ Failed to fetch orders: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final uri = isSecure
          ? Uri.https(host, '/api/orders/updateorder')
          : Uri.http(host, '/api/orders/updateorder');

      print("📤 Updating order status: $uri");
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'status': newStatus,
        }),
      );

      print("📥 Received response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['success'] == true;
        } catch (e) {
          print("❌ Error parsing response: $e");
          return false;
        }
      } else {
        print("❌ Failed to update order: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print('❌ Error updating order: $e');
      return false;
    }
  }

  Timer? _pollingTimer;

  void initializeWebSocket(String userId, String shopId) {
    try {
      // Only reconnect if the user or shop ID has changed
      if (_currentUserId == userId && _currentShopId == shopId && isWebSocketConnected) {
        print("🔄 WebSocket already connected for user $userId and shop $shopId");
        return;
      }

      _currentUserId = userId;
      _currentShopId = shopId;

      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final wsProtocol = isSecure ? 'wss' : 'ws';
      final wsUrl = '$wsProtocol://$host/socket.io/?EIO=4&transport=websocket';

      print("🔌 Attempting WebSocket connection: $wsUrl");
      
      // Close existing connection if any
      _channel?.sink.close();
      
      try {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        
        // Send Socket.IO handshake
        _channel?.sink.add('40');
        
        // Join the user's room
        _channel?.sink.add('42["join_user",{"user_id":"$userId"}]');
        print("👤 Joined user room: user_$userId");

        // Join the canteen's room
        _channel?.sink.add('42["join_canteen",{"shop_id":"$shopId"}]');
        print("🏪 Joined canteen room: canteen_$shopId");
        
        _channel?.stream.listen(
          (message) {
            print("📨 Received WebSocket message: $message");
            if (_onStatusUpdate != null) {
              try {
                if (message.startsWith('42')) {
                  final data = jsonDecode(message.substring(2));
                  if (data[0] == 'order_status_update') {
                    _onStatusUpdate!(data[1]);
                  }
                }
              } catch (e) {
                print("❌ Error parsing WebSocket message: $e");
              }
            }
          },
          onError: (error) {
            print("❌ WebSocket error: $error");
            _handleConnectionError(userId, shopId);
          },
          onDone: () {
            print("🔌 WebSocket connection closed");
            _handleConnectionError(userId, shopId);
          },
          cancelOnError: true,
        );

        // Set up reconnection timer
        _setupReconnectionTimer(userId, shopId);
      } catch (e) {
        print("❌ WebSocket connection failed: $e");
        _handleConnectionError(userId, shopId);
      }
    } catch (e) {
      print("⚠️ WebSocket initialization failed: $e");
      _handleConnectionError(userId, shopId);
    }
  }

  void _handleConnectionError(String userId, String shopId) {
    _channel = null;
    _startPolling(userId, shopId);
    _setupReconnectionTimer(userId, shopId);
  }

  void _setupReconnectionTimer(String userId, String shopId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isWebSocketConnected) {
        print("🔄 Attempting to reconnect WebSocket...");
        initializeWebSocket(userId, shopId);
      }
    });
  }

  void _startPolling(String userId, String shopId) {
    print("🔄 Starting polling for order updates...");
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        print("🔄 Polling for new order updates...");
        final orders = await fetchOrders(shopId);
        if (_onStatusUpdate != null) {
          for (var order in orders) {
            print("📨 Polling update for order ${order['order_id']}: ${order['status']}");
            _onStatusUpdate!({
              'order_id': order['order_id'].toString(),
              'new_status': order['status'],
            });
          }
        }
      } catch (e) {
        print("❌ Error polling orders: $e");
      }
    });
  }

  void disconnect() {
    try {
      _channel?.sink.close();
      _channel = null;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _currentUserId = null;
      _currentShopId = null;
      print("🔌 WebSocket disconnected and polling stopped");
    } catch (e) {
      print("❌ Error disconnecting: $e");
    }
  }
}
