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
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? _onStatusUpdate;
  String? _currentUserId;
  String? _currentShopId;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;

  bool get isWebSocketConnected => _channel != null && _channel?.closeCode == null;

  void setOnStatusUpdate(Function(Map<String, dynamic>) callback) {
    _onStatusUpdate = callback;
  }

  Future<Map<String, dynamic>> placeOrder(String userId, String shopId, DateTime pickupTime, String paymentMethod, double totalAmount, List<Map<String, dynamic>> foodItems) async {
    try {
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final baseUrl = dotenv.env['API_BASE_URL'];
      
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
      
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final baseUrl = dotenv.env['API_BASE_URL'];
      
      // Use API_BASE_URL if available, otherwise construct from host
      final uri = baseUrl != null 
          ? Uri.parse('$baseUrl/orders/getorder/$shopId')
          : (isSecure 
          ? Uri.https(host, '/api/orders/getorder/$shopId')
              : Uri.http(host, '/api/orders/getorder/$shopId'));

      print("📤 Fetching orders from: $uri");
      final response = await http.get(uri);

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
              'total_amount': item['total_amount'],
              'otp': item['otp'],
              'status': item['status']?.toLowerCase() ?? 'pending',
              'items': [],
            };
          }
          
          ordersMap[orderId]['items'].add({
            'id': item['food_id'],
            'name': item['name'],
            'quantity': item['quantity'],
            'price': item['price'] != null ? double.tryParse(item['price'].toString()) ?? 0.0 : 0.0,
            'image': item['image'] ?? '',
            'description': item['description'] ?? '',
            'type': item['type'] ?? 'veg',
          });
        }
        
        List<Map<String, dynamic>> orders = ordersMap.values.cast<Map<String, dynamic>>().toList();
        
        for (var order in orders) {
          print("📊 Processing order #${order['order_id']} with status: ${order['status']}");
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

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final uri = isSecure
          ? Uri.https(host, '/api/orders/updateorder')
          : Uri.http(host, '/api/orders/updateorder');

      // Get auth headers with JWT token
      final headers = await auth.AuthService.getAuthHeaders();

      print("📤 Updating order status: $uri");
      final response = await http.put(
        uri,
        headers: headers,
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

  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      // Use the updateorder endpoint instead of cancelorder
      final uri = isSecure
          ? Uri.https(host, '/api/orders/updateorder')
          : Uri.http(host, '/api/orders/updateorder');

      // Get auth headers with JWT token
      final headers = await auth.AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      print("📤 Cancelling order #$orderId with reason: $reason");
      print("🔄 Using endpoint: $uri");
      
      // Create request body
      final requestBody = {
        'order_id': orderId,
        'status': 'Pending', // Use a valid enum value from the database
        'cancel_reason': reason,
        'is_cancellation': true // Add a flag to indicate this is a cancellation operation
      };
      
      print("📦 Request payload: ${json.encode(requestBody)}");
      
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      print("📥 Received response code: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print("📄 Complete response body: ${response.body}");
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final success = data['message'] != null;
          
          if (success) {
            print("✅ Successfully cancelled order #$orderId");
            // If cancellation was successful, broadcast status update to subscribers
            if (_onStatusUpdate != null) {
              _onStatusUpdate!({
                'order_id': orderId,
                'new_status': 'Pending', // Use the same status value we sent to the server
                'cancel_reason': reason,
                'is_cancelled': true // Flag to indicate cancellation
              });
            }
          } else {
            print("❌ Server returned error for cancelling order #$orderId");
          }
          
          return success;
        } catch (e) {
          print("❌ Error parsing cancel response: $e");
          return false;
        }
      } else if (response.statusCode == 404) {
        print("❌ Order #$orderId not found (404)");
        return false;
      } else if (response.statusCode == 401) {
        print("❌ Authentication error (401) - Token may be invalid");
        
        // Try validating and refreshing the token
        final tokenValid = await login_auth.AuthService.validateToken();
        if (tokenValid) {
          print("🔑 Token is valid, retrying cancellation...");
          // Retry with validated token (recursive call)
          return await cancelOrder(orderId, reason);
        } else {
          print("❌ Token validation failed");
          return false;
        }
      } else {
        print("❌ Failed to cancel order: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print('❌ Error cancelling order: $e');
      return false;
    }
  }

  void initializeWebSocket(String userId, String shopId) {
    try {
      // Only reconnect if the user or shop ID has changed
      if (_currentUserId == userId && _currentShopId == shopId && isWebSocketConnected) {
        print("🔄 WebSocket already connected for user $userId and shop $shopId");
        return;
      }

      _currentUserId = userId;
      _currentShopId = shopId;

      // Start polling as the reliable mechanism
      print("🔄 Starting polling as primary update mechanism");
      _startPolling(userId, shopId);
      
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final apiBaseUrl = dotenv.env['API_BASE_URL'];
      
      // Extract domain for detection
      String domain = host;
      if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(apiBaseUrl);
          domain = uri.host;
        } catch (e) {
          print("⚠️ Error parsing API_BASE_URL: $e");
        }
      }
      
      // Check if using ngrok
      if (domain.contains('ngrok-free.app')) {
        print("🔍 Detected ngrok URL: $domain");
        print("ℹ️ Using polling only for ngrok as WebSockets return 404");
        return; // Skip WebSocket connection for ngrok URLs
      }
      
      // Try WebSocket only for non-ngrok URLs
      _tryWebSocketConnection(userId, shopId);
    } catch (e) {
      print("⚠️ WebSocket initialization failed: $e");
      _handleConnectionError(userId, shopId);
    }
  }

  void _tryWebSocketConnection(String userId, String shopId) {
    try {
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final apiBaseUrl = dotenv.env['API_BASE_URL'];
      final wsProtocol = isSecure ? 'wss' : 'ws';
      
      // Extract base domain for WebSocket connection
      String baseWsUrl = '';
      if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
        // Extract domain from API_BASE_URL
        final uri = Uri.parse(apiBaseUrl);
        final domain = uri.host;
        baseWsUrl = domain;
        print("🔌 Using baseWsUrl from API_BASE_URL: $baseWsUrl");
      } else {
        baseWsUrl = host;
        print("🔌 Using baseWsUrl from API_HOST: $baseWsUrl");
      }
      
      // Try multiple WebSocket endpoints
      List<String> wsUrls = [];
      
      if (baseWsUrl.contains('ngrok-free.app')) {
        // For ngrok, don't include the port number in the WebSocket URL
        final domainOnly = baseWsUrl.split(':')[0]; // Remove any port
        wsUrls = [
          '$wsProtocol://$domainOnly/ws', // Standard WebSocket without port
        ];
        print("🔌 Using ngrok URL without port: $wsProtocol://$domainOnly/ws");
      } else {
        wsUrls = [
          '$wsProtocol://$baseWsUrl/ws',
          '$wsProtocol://$baseWsUrl/socket.io/?EIO=4&transport=websocket',
        ];
      }
      
      // Close existing connection if any
      try {
      _channel?.sink.close();
        _channel = null;
      } catch (e) {
        print("⚠️ Error closing existing WebSocket: $e");
      }
      
      // Try each WebSocket URL
      _tryNextWebSocketUrl(wsUrls, 0, userId, shopId);
      
    } catch (e) {
      print("⚠️ WebSocket connection attempt failed: $e");
    }
  }
  
  void _tryNextWebSocketUrl(List<String> urls, int index, String userId, String shopId) {
    if (index >= urls.length) {
      print("❌ All WebSocket connection attempts failed");
      return;
    }
    
    final wsUrl = urls[index];
    print("🔌 Attempting WebSocket connection to: $wsUrl");
    
    // Create a flag to track if we've already moved to the next URL
    bool movedToNextUrl = false;
    
    // Use a single timer instead of Future.timeout to avoid zone mismatch
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (!movedToNextUrl) {
        movedToNextUrl = true;
        print("⏱️ WebSocket connection timed out: $wsUrl");
        timeoutTimer?.cancel();
        _tryNextWebSocketUrl(urls, index + 1, userId, shopId);
      }
    });
    
    try {
      // Create connection synchronously to avoid zone mismatch
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        
      // When connection is established, cancel the timeout timer
      _channel?.ready.then((_) {
        if (!movedToNextUrl) {
          movedToNextUrl = true;
          timeoutTimer?.cancel();
          print("✅ WebSocket connected successfully to: $wsUrl");
          
          // Handle Socket.IO vs standard WebSocket
          try {
            if (wsUrl.contains('socket.io')) {
              // Socket.IO handshake
        _channel?.sink.add('40');
        _channel?.sink.add('42["join_user",{"user_id":"$userId"}]');
              _channel?.sink.add('42["join_canteen",{"shop_id":"$shopId"}]');
              print("🔗 Sent Socket.IO handshake and room joins");
            } else {
              // Standard WebSocket auth
              _channel?.sink.add(jsonEncode({
                'type': 'auth',
                'user_id': userId,
                'shop_id': shopId
              }));
              print("🔐 Sent WebSocket authentication");
            }
          } catch (e) {
            print("⚠️ Error sending WebSocket messages: $e");
          }
          
          _setupWebSocketListener(userId, shopId);
        }
      }).catchError((error) {
        if (!movedToNextUrl) {
          movedToNextUrl = true;
          timeoutTimer?.cancel();
          print("❌ WebSocket connection error: $error");
          _tryNextWebSocketUrl(urls, index + 1, userId, shopId);
        }
      });
    } catch (e) {
      if (!movedToNextUrl) {
        movedToNextUrl = true;
        timeoutTimer?.cancel();
        print("❌ WebSocket connection failed: $e");
        _tryNextWebSocketUrl(urls, index + 1, userId, shopId);
      }
    }
  }
  
  void _setupWebSocketListener(String userId, String shopId) {
    try {
        _channel?.stream.listen(
          (message) {
            print("📨 Received WebSocket message: $message");
          // Update the UI on the main isolate
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_onStatusUpdate != null) {
              try {
                if (message is String && message.startsWith('42')) {
                  // Socket.IO format
                  final data = jsonDecode(message.substring(2));
                  if (data is List && data.length > 1 && data[0] == 'order_status_update') {
                    _onStatusUpdate!(data[1]);
                  }
                } else if (message is String) {
                  // Try standard JSON format
                  try {
                    final data = jsonDecode(message);
                    if (data is Map && data['type'] == 'order_status_update') {
                      _onStatusUpdate!(data['data']);
                    }
                  } catch (e) {
                    print("⚠️ Error parsing WebSocket JSON message: $e");
                  }
                }
              } catch (e) {
                print("❌ Error processing WebSocket message: $e");
              }
            }
          });
          },
          onError: (error) {
            print("❌ WebSocket error: $error");
          // Handle error on the main isolate
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              if (error.toString().contains('not upgraded to websocket') ||
                  error.toString().contains('Connection refused')) {
                print("Switching to next WebSocket URL due to connection error");
              }
            } catch (e) {
              print("⚠️ Error in WebSocket error handler: $e");
            }
          });
          },
          onDone: () {
            print("🔌 WebSocket connection closed");
          // Handle connection close on the main isolate
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
        _setupReconnectionTimer(userId, shopId);
      } catch (e) {
              print("⚠️ Error setting up reconnection timer: $e");
      }
          });
        },
        cancelOnError: false, // Don't cancel on error to prevent freezing
      );
    } catch (e) {
      print("⚠️ Error setting up WebSocket listener: $e");
    }
  }

  void _handleConnectionError(String userId, String shopId) {
    try {
    _channel = null;
      
      // Make sure polling is running
      if (_pollingTimer == null || !(_pollingTimer?.isActive ?? false)) {
    _startPolling(userId, shopId);
      }
      
    _setupReconnectionTimer(userId, shopId);
    } catch (e) {
      print("⚠️ Error handling connection error: $e");
    }
  }

  void _setupReconnectionTimer(String userId, String shopId) {
    try {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isWebSocketConnected) {
        print("🔄 Attempting to reconnect WebSocket...");
          try {
            _tryWebSocketConnection(userId, shopId);
          } catch (e) {
            print("⚠️ Error during WebSocket reconnection: $e");
          }
      }
    });
    } catch (e) {
      print("⚠️ Error setting up reconnection timer: $e");
    }
  }

  void _startPolling(String userId, String shopId) {
    try {
      // Determine if using ngrok
      final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
      final isNgrok = apiBaseUrl.contains('ngrok-free.app');
      
      // Use shorter polling interval for ngrok (since WebSocket is disabled)
      final pollingInterval = isNgrok ? 5 : 8; // 5 seconds for ngrok, 8 for others
      
      if (isNgrok) {
        print("🔄 Starting polling with ${pollingInterval}s interval (WebSocket disabled for ngrok)");
      } else {
        print("🔄 Starting polling for order updates with ${pollingInterval}s interval");
      }
      
      // Cancel existing polling timer
    _pollingTimer?.cancel();
      
      // Start new polling timer
      _pollingTimer = Timer.periodic(Duration(seconds: pollingInterval), (_) async {
      try {
        print("🔄 Polling for new order updates...");
        final orders = await fetchOrders(shopId);
          
          if (_onStatusUpdate != null && orders.isNotEmpty) {
            // Track if we've found any status changes
            bool foundStatusChanges = false;
            
            // Process all orders
          for (var order in orders) {
              final orderId = order['order_id'].toString();
              final status = order['status'].toString();
              
              print("📨 Polling found order #$orderId with status: $status");
              
              // Notify about each order's status
            _onStatusUpdate!({
                'order_id': orderId,
                'new_status': status, // Use the status directly from the backend
              });
              
              foundStatusChanges = true;
            }
            
            if (!foundStatusChanges) {
              print("ℹ️ Polling found no status changes");
            }
          } else if (orders.isEmpty) {
            print("ℹ️ Polling found no orders");
        }
      } catch (e) {
        print("❌ Error polling orders: $e");
      }
    });
    } catch (e) {
      print("⚠️ Error starting polling timer: $e");
    }
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

  Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      print("🔄 Fetching specific order #$orderId from backend...");
      
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final baseUrl = dotenv.env['API_BASE_URL'];
      
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
}
