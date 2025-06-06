import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'food.dart';
import 'models/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Order {
  final int orderNumber;
  final List<CartItem> items;
  final TimeOfDay? pickupTime;
  final DateTime orderPlacedTime;
  final String shopId;
  final Duration preparationTime;
  final String? paymentMode;
  bool expired;

  int step;
  bool isCancelled;
  DateTime? readyTime;
  bool pickupTimeExpired;

  Order({
    required this.orderNumber,
    required this.items,
    this.pickupTime,
    required this.orderPlacedTime,
    required this.shopId,
    this.preparationTime = const Duration(minutes: 10),
    this.paymentMode,
    this.step = 1,
    this.isCancelled = false,
    this.readyTime,
    this.pickupTimeExpired = false,
    this.expired = false,
  });

  int get remainingSeconds {
    if (isCancelled || pickupTimeExpired) return 0;
    final expiryTime = orderPlacedTime.add(preparationTime);
    final difference = expiryTime.difference(DateTime.now()).inSeconds;
    return difference > 0 ? difference : 0;
  }
}

class FoodMenu extends ChangeNotifier {
  List<Food> _menu = [];
  List<CartItem> _cart = [];
  Map<String, List<Food>> _shopMenus = {}; // Store menus by shop ID
  String? _currentShopId;
  Map<String, dynamic>? _latestOrderData;

  List<Food> get menu => _menu;
  List<CartItem> get cart => _cart;
  String? get currentShopId => _currentShopId;
  Map<String, dynamic>? get latestOrderData => _latestOrderData;

  final List<Order> _orders = [];
  List<CartItem> _lastOrderedItems = [];
  List<Order> _upcomingOrders = [];
  final List<Order> _completedOrders = [];
  final Map<int, int> _orderSteps = {};
  final Map<Order, int> _orderNumbers = {};
  int _nextOrderNumber = 1;
  bool _isOrderCancelled = false;

  static const String _orderDataKey = 'latest_order_data';

  FoodMenu() {
    _loadLatestOrderData();
  }

  List<CartItem> get lastOrderedItems => _lastOrderedItems;
  List<Order> get upcomingOrders => _upcomingOrders;
  List<Order> get completedOrders => _completedOrders;
  bool get isOrderCancelled => _isOrderCancelled;
  int get nextOrderNumber => _nextOrderNumber;

  Future<void> _loadLatestOrderData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderDataString = prefs.getString(_orderDataKey);
      if (orderDataString != null) {
        _latestOrderData = json.decode(orderDataString);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading order data: $e');
    }
  }

  Future<bool> setLatestOrderData(Map<String, dynamic> orderData) async {
    try {
      // Create a deep copy to avoid reference issues
      final orderCopy = Map<String, dynamic>.from(orderData);
      
      // Ensure items are deeply copied and properly formatted
      if (orderData.containsKey('items')) {
        final items = orderData['items'] as List<dynamic>;
        
        // Debug log raw items
        print("📦 Processing ${items.length} items for storage - checking image paths:");
        for (var item in items) {
          if (item is Map) {
            final rawImagePath = item['image']?.toString() ?? '';
            print("   🖼️ Item: ${item['name']}, Image Path: $rawImagePath");
          }
        }
        
        // Deep copy with all required fields
        orderCopy['items'] = items.map((item) {
          if (item is Map) {
            return {
              'id': item['id']?.toString() ?? item['food_id']?.toString() ?? '',
              'food_id': item['food_id']?.toString() ?? item['id']?.toString() ?? '',
              'name': item['name']?.toString() ?? 'Unknown Item',
              'quantity': item['quantity'] is int ? item['quantity'] : 
                        (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
              'price': item['price'] is num ? item['price'] : 
                      (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
              'total_price': item['total_price'] is num ? item['total_price'] :
                            (item['total_item_price'] is num ? item['total_item_price'] : 
                             (item['price'] is num && item['quantity'] is num ? 
                              (item['price'] as num) * (item['quantity'] as num) : 0.0)),
              'total_item_price': item['total_item_price'] is num ? item['total_item_price'] :
                                 (item['total_price'] is num ? item['total_price'] : 
                                  (item['price'] is num && item['quantity'] is num ? 
                                   (item['price'] as num) * (item['quantity'] as num) : 0.0)),
              'description': item['description']?.toString() ?? '',
              'image': item['image']?.toString() ?? '',
              'isVeg': item['isVeg'] is bool ? item['isVeg'] : true,
              'category': item['category']?.toString() ?? '',
            };
          } else {
            // Fallback for non-map items
            return {
              'id': '',
              'food_id': '',
              'name': 'Unknown Item',
              'quantity': 1,
              'price': 0.0,
              'total_price': 0.0,
              'total_item_price': 0.0,
              'description': '',
              'image': '',
              'isVeg': true,
              'category': '',
            };
          }
        }).toList();
      } else {
        // Ensure there's at least an empty items array
        orderCopy['items'] = [];
      }
      
      print("💾 Storing order data with ${orderCopy['items'].length} items in provider and SharedPreferences");
      
      // Log the items being stored
      for (var item in orderCopy['items']) {
        print("   📝 Stored Item: ${item['name']}, price=${item['price']}, quantity=${item['quantity']}");
      }
      
      // Store the copied data
      _latestOrderData = orderCopy;
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_orderDataKey, json.encode(orderCopy));
      print("✅ Order data saved to SharedPreferences");
      
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ Error storing order data: $e");
      return false;
    }
  }

  Future<void> clearLatestOrderData() async {
    if (_latestOrderData != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_orderDataKey);
        _latestOrderData = null;
        notifyListeners();
      } catch (e) {
        print('Error clearing order data: $e');
      }
    }
  }

  List<Order> getActiveOrders() {
    final completedOrderIds = _completedOrders.map((o) => o.orderNumber).toSet();
    return [..._orders, ..._upcomingOrders]
        .where((order) => !order.isCancelled && !completedOrderIds.contains(order.orderNumber))
        .toList();
  }

  List<CartItem> getOrderItems(int orderNumber) {
    return _orders.firstWhereOrNull((order) => order.orderNumber == orderNumber)?.items ?? [];
  }

  final Map<int, int> _orderProgress = {};

  int getOrderProgress(int orderNumber) => _orderProgress[orderNumber] ?? 0;

  void updateOrderProgress(int orderNumber, int step) {
    _orderProgress[orderNumber] = step;
    notifyListeners();
  }

  Future<void> fetchMenuFromBackend({
    required FoodCategory category,
    String? type,
    required int shopId,
  }) async {
    try {
      print('🔄 Fetching menu for shop #$shopId, category: ${category.name}, type: $type');
      
      final baseUrl = dotenv.env['API_BASE_URL'];
      if (baseUrl == null) throw Exception('API_BASE_URL not found in environment variables');

      final queryParams = {
        'category': category.name.toLowerCase(),
        if (type != null) 'type': type,
        'shop_id': shopId.toString(),
      };

      final uri = Uri.parse('$baseUrl/food/getfoods').replace(queryParameters: queryParams);
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Food> fetchedMenu = data.map((item) => Food.fromJson(item)).toList();
        
        // Store the menu for this shop
        _shopMenus[shopId.toString()] = fetchedMenu;
        _currentShopId = shopId.toString();
        _menu = fetchedMenu;
        
        print('✅ Fetched ${fetchedMenu.length} items for shop #$shopId');
        notifyListeners();
      } else {
        print('❌ Failed to fetch menu: ${response.statusCode}');
        throw Exception('Failed to fetch menu');
      }
    } catch (e) {
      print('❌ Error fetching menu: $e');
      throw Exception('Error fetching menu: $e');
    }
  }

  void addToCart(Food food) {
    if (_currentShopId == null) {
      print('⚠️ Cannot add to cart: No shop selected');
      return;
    }

    final existingIndex = _cart.indexWhere((item) => item.food.id == food.id);
    
    if (existingIndex != -1) {
      _cart[existingIndex] = CartItem(
        food: food,
        quantity: _cart[existingIndex].quantity + 1,
        shopId: _currentShopId!,
      );
    } else {
      _cart.add(CartItem(
        food: food,
        quantity: 1,
        shopId: _currentShopId!,
      ));
    }
    
    print('🛒 Added ${food.name} to cart for shop #$_currentShopId');
    notifyListeners();
  }

  void removeFromCart(Food food) {
    final existingIndex = _cart.indexWhere((item) => item.food.id == food.id);

    if (existingIndex != -1) {
      if (_cart[existingIndex].quantity > 1) {
        _cart[existingIndex] = CartItem(
          food: food,
          quantity: _cart[existingIndex].quantity - 1,
          shopId: _cart[existingIndex].shopId,
        );
      } else {
        _cart.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double getTotalPrice() {
    return _cart.fold(0, (total, item) => total + (item.food.price * item.quantity));
  }

  void placeOrder(TimeOfDay? selectedTime, String? otp, String selectedPayment, String shopId) {
    if (_cart.isNotEmpty) {
      Order newOrder = Order(
        orderNumber: _nextOrderNumber++,
        items: List.from(_cart),
        pickupTime: selectedTime,
        orderPlacedTime: DateTime.now(),
        shopId: shopId,
      );
      _orders.add(newOrder);
      _upcomingOrders.add(newOrder);
      _cart.clear();
      notifyListeners();
    }
  }

  void cancelOrder(int orderNumber) {
    Order? order = _orders.firstWhereOrNull((o) => o.orderNumber == orderNumber);
    if (order == null || order.isCancelled) return;

    for (var item in order.items) {
      item.food.availableQuantity += item.quantity;
    }

    order.isCancelled = true;
    order.step = 0;
    notifyListeners();
  }

  void markOrderReady(Order order) {
    _lastOrderedItems.removeWhere((item) => item.food == order.items.first.food);
    _upcomingOrders.remove(order);
    notifyListeners();
  }

  void addOrder(Order order) {
    _upcomingOrders.add(order);
    _orderSteps[order.orderNumber] = 1;
    _orderNumbers[order] = _nextOrderNumber++;
    incrementOrderNumber();
    notifyListeners();
  }

  int getOrderStep(Order order) => _orderSteps[order.orderNumber] ?? 1;

  int getOrderNumber(CartItem order) => _orderNumbers[order] ?? 0;

  void nextOrderStep(int orderNumber) {
    if (_orderSteps[orderNumber] == 4) return;
    _orderSteps[orderNumber] = (_orderSteps[orderNumber] ?? 0) + 1;
    notifyListeners();
  }

  int getNextOrderNumber() => _nextOrderNumber;

  void completeOrder(int orderNumber) {
    Order? order = _orders.firstWhereOrNull((o) => o.orderNumber == orderNumber);
    order ??= _upcomingOrders.firstWhereOrNull((o) => o.orderNumber == orderNumber);

    if (order != null) {
      _orders.remove(order);
      _upcomingOrders.remove(order);
      _completedOrders.add(order);
      notifyListeners();
    }
  }

  void updateStock(Food food, int newQuantity) {
    food.availableQuantity = newQuantity;
    notifyListeners();
  }

  void updateFood(Food updatedFood) {
    int index = _menu.indexWhere((food) => food.id == updatedFood.id);
    if (index != -1) {
      _menu[index] = updatedFood;  
      notifyListeners();  
    }
  }

  void clearOrders() {
    _upcomingOrders.clear();
    _completedOrders.clear();
    _orderSteps.clear();
    notifyListeners();
  }

  void incrementOrderNumber() {
    _nextOrderNumber++;
    notifyListeners();
  }

  void updateFilter(String? type) {
    // Implementation needed for filter updates
    notifyListeners();
  }

  // Check if an order with given order ID is cancelled
  Future<bool> checkIfOrderIsCancelled(String orderId) async {
    if (orderId.isEmpty) return false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedOrdersJson = prefs.getString('completed_orders') ?? '[]';
      
      List<dynamic> completedOrders;
      try {
        final decodedJson = json.decode(completedOrdersJson);
        if (decodedJson is List) {
          completedOrders = decodedJson;
        } else if (decodedJson is Map) {
          completedOrders = [decodedJson];
        } else {
          completedOrders = [];
        }
      } catch (e) {
        print("❌ Error parsing completed orders: $e");
        completedOrders = [];
      }
      
      // Check if the order ID is in the cancelled orders list
      return completedOrders.any((order) {
        if (order is Map) {
          final storedOrderId = order['order_id']?.toString() ?? '';
          final storedStatus = order['status']?.toString()?.toLowerCase() ?? '';
          final isCancelled = order['is_cancelled'] == true || 
                              order['cancel_reason'] != null;
          
          return storedOrderId == orderId && 
                 (storedStatus == 'cancelled' || isCancelled);
        }
        return false;
      });
    } catch (e) {
      print("❌ Error checking if order is cancelled: $e");
      return false;
    }
  }
  
  // Mark an order as cancelled
  Future<void> markOrderAsCancelled(String orderId, String reason) async {
    if (_latestOrderData != null && 
        _latestOrderData!['order_id']?.toString() == orderId) {
      
      print("🚫 Marking order #$orderId as cancelled in provider");
      
      // Update the status on the latest order data
      _latestOrderData!['status'] = 'cancelled';
      _latestOrderData!['is_cancelled'] = true;
      _latestOrderData!['cancel_reason'] = reason;
      _latestOrderData!['cancelled_at'] = DateTime.now().toIso8601String();
      
      // Save the updated data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_orderDataKey, json.encode(_latestOrderData));
      
      // Also check if we need to update completed orders storage
      final completedOrdersJson = prefs.getString('completed_orders') ?? '[]';
      
      List<dynamic> completedOrders;
      try {
        final decodedJson = json.decode(completedOrdersJson);
        if (decodedJson is List) {
          completedOrders = decodedJson;
        } else if (decodedJson is Map) {
          completedOrders = [decodedJson];
        } else {
          completedOrders = [];
        }
      } catch (e) {
        print("❌ Error parsing completed orders: $e");
        completedOrders = [];
      }
      
      // Check if the order is already in completed orders
      bool orderExists = false;
      for (int i = 0; i < completedOrders.length; i++) {
        if (completedOrders[i] is Map && 
            completedOrders[i]['order_id']?.toString() == orderId) {
          orderExists = true;
          // Update the cancelled status
          completedOrders[i]['status'] = 'cancelled';
          completedOrders[i]['is_cancelled'] = true;
          completedOrders[i]['cancel_reason'] = reason;
          completedOrders[i]['cancelled_at'] = _latestOrderData!['cancelled_at'];
          break;
        }
      }
      
      // If not found, add it
      if (!orderExists) {
        completedOrders.add(_latestOrderData);
        print("➕ Added order #$orderId to completed_orders with cancelled status");
      }
      
      // Save back to shared preferences
      await prefs.setString('completed_orders', json.encode(completedOrders));
      
      // Set the cancelled flag
      _isOrderCancelled = true;
      
      notifyListeners();
    }
  }
  
  // Get shop name by shop ID
  String? getShopNameById(String shopId) {
    try {
      // First check if we have the shop name in the latest order data
    if (_latestOrderData != null && 
        _latestOrderData!['shop_id']?.toString() == shopId && 
        _latestOrderData!['shop_name'] != null) {
      return _latestOrderData!['shop_name'].toString();
    }
    
      // Then check if we have it in the shop menus
      if (_shopMenus.containsKey(shopId) && _shopMenus[shopId]!.isNotEmpty) {
        // Get shop name from the first item in the menu that has a shop name
        final foodWithShopName = _shopMenus[shopId]!.firstWhere(
          (food) => food.shopName != null && food.shopName!.isNotEmpty,
          orElse: () => _shopMenus[shopId]!.first
        );
        if (foodWithShopName.shopName != null && foodWithShopName.shopName!.isNotEmpty) {
          return foodWithShopName.shopName;
        }
      }

      // Finally check completed orders in SharedPreferences
      SharedPreferences.getInstance().then((prefs) {
        final completedOrdersString = prefs.getString('completed_orders');
        if (completedOrdersString != null) {
          final completedOrders = json.decode(completedOrdersString) as List;
          final matchingOrder = completedOrders.firstWhere(
            (order) => order['shop_id']?.toString() == shopId && 
                      order['shop_name'] != null && 
                      order['shop_name'].toString().isNotEmpty,
            orElse: () => null
          );
          if (matchingOrder != null) {
            return matchingOrder['shop_name'].toString();
          }
        }
      });

      // If no shop name found, try to fetch it from the backend
      _fetchShopName(shopId);
      
      return null;
    } catch (e) {
      print('❌ Error getting shop name for shop #$shopId: $e');
      return null;
    }
  }

  // Fetch shop name from backend
  Future<void> _fetchShopName(String shopId) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'];
      if (baseUrl == null) throw Exception('API_BASE_URL not found in environment variables');

      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['name'] != null) {
          // Update shop name in menus if we have any items from this shop
          if (_shopMenus.containsKey(shopId)) {
            _shopMenus[shopId] = _shopMenus[shopId]!.map((food) => 
              food.copyWith(shopName: data['name'].toString())
            ).toList();
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error fetching shop name from backend: $e');
    }
  }
  
  // Clear all orders data on logout
  Future<void> clearAllOrdersData() async {
    try {
      print("🗑️ Clearing all orders data from provider");
      _latestOrderData = null;
      _orders.clear();
      _upcomingOrders.clear();
      _completedOrders.clear();
      _lastOrderedItems.clear();
      _isOrderCancelled = false;
      
      // Not clearing from SharedPreferences as we keep cancelled orders for history
      
      notifyListeners();
    } catch (e) {
      print("❌ Error clearing all orders data: $e");
    }
  }
}
