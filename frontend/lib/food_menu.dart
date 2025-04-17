import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'food.dart';
import 'models/cart_item.dart';

class Order {
  final int orderNumber;
  final List<CartItem> items;
  final TimeOfDay? pickupTime;
  final DateTime orderPlacedTime;
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
  List<Food> _rawMenu = [];
  List<Food> _menu = [];
  String? _currentTypeFilter;

  final List<CartItem> _cart = [];
  final List<Order> _orders = [];
  List<CartItem> _lastOrderedItems = [];
  List<Order> _upcomingOrders = [];
  final List<Order> _completedOrders = [];
  final Map<int, int> _orderSteps = {};
  final Map<Order, int> _orderNumbers = {};
  int _nextOrderNumber = 1;
  bool _isOrderCancelled = false;

  List<Food> get menu => _menu;
  List<CartItem> get cart => _cart;
  List<CartItem> get lastOrderedItems => _lastOrderedItems;
  List<Order> get upcomingOrders => _upcomingOrders;
  List<Order> get completedOrders => _completedOrders;
  bool get isOrderCancelled => _isOrderCancelled;
  int get nextOrderNumber => _nextOrderNumber;

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

  // void addToCart(Food food, /*List<Addon> selectedAddons*/) {
  //   if (food.availableQuantity > 0) {
  //     CartItem? cartItem = _cart.firstWhereOrNull(
  //       (item) => item.food == food /*&& _areAddonsEqual(item.selectedAddons, selectedAddons ),*/);

  //     if (cartItem != null) {
  //       cartItem.quantity++;
  //     } else {
  //       _cart.add(CartItem(food: food, /*selectedAddons: selectedAddons, quantity: 1*/));
  //     }

  //     food.availableQuantity--;
  //     notifyListeners();
  //   }
  // }

  void addToCart(Food food /*, List<Addon> selectedAddons*/) {
  if (food.availableQuantity > 0) {
    // Check if the item is already in the cart
    CartItem? cartItem = _cart.firstWhereOrNull(
      (item) => item.food == food /*&& _areAddonsEqual(item.selectedAddons, selectedAddons )*/,
    );

    // If the item is in the cart, increase the quantity; otherwise, add the new item to the cart
    if (cartItem != null) {
      cartItem.quantity++;
    } else {
      _cart.add(CartItem(food: food, /*selectedAddons: selectedAddons, quantity: 1*/));
    }

    // Do not change the available quantity here
    // food.availableQuantity--; // <-- This line is removed

    notifyListeners();
  }
}


  void placeOrder(TimeOfDay? selectedTime, String? otp, String selectedPayment) {
    if (_cart.isNotEmpty) {
      Order newOrder = Order(
        orderNumber: _nextOrderNumber++,
        items: List.from(_cart),
        pickupTime: selectedTime,
        orderPlacedTime: DateTime.now(),
      );
      _orders.add(newOrder);
      _upcomingOrders.add(newOrder);
      _cart.clear();
      notifyListeners();
    }
  }

  void removeFromCart(CartItem cartItem) {
    if (_cart.contains(cartItem)) {
      cartItem.food.availableQuantity++;
      if (cartItem.quantity > 1) {
        cartItem.quantity--;
      } else {
        _cart.remove(cartItem);
      }
      notifyListeners();
    }
  }

  int getTotalItemCount() => _cart.fold(0, (sum, item) => sum + item.quantity);

  double getTotalPrice() => _cart.fold(0, (sum, item) => sum + (item.food.price * item.quantity));

  void clearCart() {
    for (var item in _cart) {
      item.food.availableQuantity += item.quantity;
    }
    _cart.clear();
    notifyListeners();
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

  void resetOrderStatus() {
    _isOrderCancelled = false;
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
      _menu[index] = updatedFood;  // Update the food in the list
      notifyListeners();  // Notify listeners to rebuild the UI
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

  // bool _areAddonsEqual(List<Addon> list1, List<Addon> list2) {
  //   return const DeepCollectionEquality().equals(
  //     list1.map((e) => e.name).toList(),
  //     list2.map((e) => e.name).toList(),
  //   );
  // }

  // Fetch food menu from backend

Future<void> fetchMenuFromBackend({FoodCategory? category, String? type, required int shopId}) async {
    try {
      final categoryStr = category?.name.toLowerCase() ?? 'lunch';
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';
      final path = '/api/food/getfoods';

      final queryParams = {
        'shop_id': shopId.toString(),
        'category': categoryStr,
        if (type != null) 'type': type.replaceAll(' ', '_').toLowerCase(),
      };

      final uri = isSecure
          ? Uri.https(host, path, queryParams)
          : Uri.http(host, path, queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _rawMenu = data.map((item) => Food.fromJson(item)).toList();
        _currentTypeFilter = type;
        _applyFilter();
      } else {
        debugPrint('❌ Failed to load menu: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 Error fetching food menu: $e');
    }
  }

  void _applyFilter() {
    debugPrint('🔍 Applying filter: $_currentTypeFilter with ${_rawMenu.length} items');
    if (_currentTypeFilter == 'veg') {
      _menu = _rawMenu.where((f) => f.isVeg).toList();
    } else if (_currentTypeFilter == 'non veg') {
      _menu = _rawMenu.where((f) => !f.isVeg).toList();
    } else {
      _menu = List.from(_rawMenu);
    }
    debugPrint('📋 Filtered menu length: ${_menu.length}');
    notifyListeners();
  }


  void updateFilter(String? type) {
    _currentTypeFilter = type?.toLowerCase().replaceAll('_', ' ');
    _applyFilter();
  }
}