import 'package:flutter/material.dart';
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
    this.expired = false, // ✅ properly initialized here
  });
  
  /// ✅ Compute remaining time dynamically
  int get remainingSeconds {
    if (isCancelled || pickupTimeExpired) return 0; // ✅ Ensure expired/cancelled orders show 0 time left

    final expiryTime = orderPlacedTime.add(preparationTime);
    final difference = expiryTime.difference(DateTime.now()).inSeconds;
    return difference > 0 ? difference : 0;
  }
}


class FoodMenu extends ChangeNotifier {
  final List<Food> _menu = [
    // ✅ Breakfast menu:
    Food(
      name: 'Idly',
      description: 'Steamed to perfection, these tender delights are complemented by creamy chutney and a bowl of spicy sambar.',
      image: 'assets/food/breakfast/idly.jpg',
      price: 10,
      category: FoodCategory.breakfast,
      availableQuantity: 100,
      availableAddons: [],
      isVeg: true,
    ),

    Food(
      name: 'Dosai',
      description: 'Thick, soft, and crispy on the edges, served with a generous amount of chutney and a steaming bowl of flavorful sambar.',
      image: 'assets/food/breakfast/dosai.jpg',
      price: 10,
      category: FoodCategory.breakfast,
      availableQuantity: 100,
      availableAddons: [],
      isVeg: true,
    ),

    Food(
      name: 'Roast',
      description: 'Crispy and golden on the outside, soft and tender on the inside, served with a side of fresh chutney and spicy sambar.',
      image: 'assets/food/breakfast/roast.jpg',
      price: 20,
      category: FoodCategory.breakfast,
      availableQuantity: 100,
      availableAddons: [],
      isVeg: true,
    ),

    // ✅ Lunch menu:
    Food(
      name: 'Chicken Biriyani',
      description: 'Fragrant rice and tender chicken slow-cooked with aromatic spices, served with raita.',
      image: 'assets/food/lunch/chicken-biryani.png',
      price: 80,
      category: FoodCategory.lunch,
      availableQuantity: 100,
      availableAddons: [
        Addon(name: 'Raita'),
        Addon(name: 'Egg')
      ],
      isVeg: false,
    ),

    Food(
      name: 'Chicken Fried Rice',
      description: 'A delicious mix of seasoned rice and succulent chicken, cooked to perfection with aromatic flavors.',
      image: 'assets/food/lunch/chicken-rice.png',
      price: 70,
      category: FoodCategory.lunch,
      availableQuantity: 100,
      availableAddons: [
        Addon(name: 'Medium Spice', spiceLevel: SpiceLevel.medium),
        Addon(name: 'More Spice', spiceLevel: SpiceLevel.full),
      ],
      isVeg: false,
    ),

    Food(
      name: 'Veg Fried Rice',
      description: 'Fragrant rice stir-fried with fresh vegetables, aromatic spices, and a dash of soy sauce.',
      image: 'assets/food/lunch/veg-rice.jpg',
      price: 50,
      category: FoodCategory.lunch,
      availableQuantity: 100,
      availableAddons: [
        Addon(name: 'Medium Spice', spiceLevel: SpiceLevel.medium),
        Addon(name: 'Full Spice', spiceLevel: SpiceLevel.full),
      ],
      isVeg: true,
    ),

    Food(
      name: 'Egg Fried Rice',
      description: 'Stir-fried rice with perfectly scrambled eggs, seasoned with bold spices and a touch of freshness.',
      image: 'assets/food/lunch/egg-rice.jpg',
      price: 60,
      category: FoodCategory.lunch,
      availableQuantity: 100,
      availableAddons: [
        Addon(name: 'Medium Spice', spiceLevel: SpiceLevel.medium),
        Addon(name: 'Full Spice', spiceLevel: SpiceLevel.full)
      ],
      isVeg: false,
    ),
  ];


 final List<CartItem> _cart = [];
final List<Order> _orders = [];
List<CartItem> _lastOrderedItems = [];
List<Order> _upcomingOrders = [];
final List<Order> _completedOrders = [];
final Map<int, int> _orderSteps = {};
final Map<Order, int> _orderNumbers = {};
int _nextOrderNumber = 1;
bool _isOrderCancelled = false;

// ✅ Getters
List<Food> get menu => _menu;
List<CartItem> get cart => _cart;
List<CartItem> get lastOrderedItems => _lastOrderedItems;
// List<Order> getActiveOrders() => _activeOrders;
List<Order> getCompletedOrders() => _completedOrders;
List<Order> get upcomingOrders => _upcomingOrders;
List<Order> get completedOrders => _completedOrders;
bool get isOrderCancelled => _isOrderCancelled;
int get nextOrderNumber => _nextOrderNumber;


  // ✅ Returns a list of all active (non-cancelled) orders
  
  List<Order> getActiveOrders() {
  final completedOrderIds = _completedOrders.map((o) => o.orderNumber).toSet();
  return [..._orders, ..._upcomingOrders]
      .where((order) => order.isCancelled != true && !completedOrderIds.contains(order.orderNumber))
      .toList();
}



  // ✅ Returns the list of ordered items from the most recent order
//   List<CartItem> getOrderItems(String orderNumber) {
//   int? num = int.tryParse(orderNumber);
//   if (num == null) return []; // ✅ Return empty list for invalid input
//   return _orders.firstWhereOrNull((order) => order.orderNumber == num)?.items ?? [];
// }
  List<CartItem> getOrderItems(int orderNumber) {
    return _orders.firstWhereOrNull((order) => order.orderNumber == orderNumber)?.items ?? [];
  }







  final Map<int, int> _orderProgress = {};

  int getOrderProgress(int orderNumber) {
    return _orderProgress[orderNumber] ?? 0;
  }

  void updateOrderProgress(int orderNumber, int step){
    _orderProgress[orderNumber] = step;
    notifyListeners();
  }


  // ✅ Add to Cart (Decreases Available Stock)
  void addToCart(Food food, List<Addon> selectedAddons) {
    if (food.availableQuantity > 0) {
      CartItem? cartItem = _cart.firstWhereOrNull((item) =>
          item.food == food && _areAddonsEqual(item.selectedAddons, selectedAddons));

      if (cartItem != null) {
        cartItem.quantity++;
      } else {
        _cart.add(CartItem(food: food, selectedAddons: selectedAddons, quantity: 1));
      }

      food.availableQuantity--; // ✅ Reduce stock **after** adding to cart
      notifyListeners();
    }
  }


  // ✅ Place Order (Saves Last Ordered Items & Clears Cart), Separate order:
  void placeOrder(TimeOfDay? selectedTime) {
    // if (_cart.isNotEmpty) {
    //   _lastOrderedItems = List.from(_cart);
    //   _upcomingOrders.addAll(_cart);
    //   _cart.clear();
    //   notifyListeners();
    // }
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
    notifyListeners(); // ✅ Ensure UI updates after order placement
  }
}

  // ✅ Remove from Cart (Restores Stock)
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

  // ✅ Get total number of items in the cart
  int getTotalItemCount() {
    return _cart.fold(0, (sum, item) => sum + item.quantity);
  }

  // ✅ Get total price
  double getTotalPrice() {
    return _cart.fold(0, (sum, item) => sum + (item.food.price * item.quantity));
  }

  // ✅ Clear cart and restore all stock
  void clearCart() {
    for (var item in _cart) {
      item.food.availableQuantity += item.quantity;
    }
    _cart.clear();
    notifyListeners();
  }

  // ✅ Cancel a Specific Order (Restores Stock)
void cancelOrder(int orderNumber) {
  Order? order = _orders.firstWhereOrNull((o) => o.orderNumber == orderNumber);
  if (order == null || order.isCancelled) return;

  for (var item in order.items) {
    item.food.availableQuantity += item.quantity;
  }

  order.isCancelled = true;
  order.step = 0; // ✅ Reset step progress
  notifyListeners();
}


  // ✅ Reset order cancellation status
  void resetOrderStatus() {
    _isOrderCancelled = false;
    notifyListeners();
  }

  // ✅ Mark an order as ready
 void markOrderReady(Order order) {
  if (order.items.isNotEmpty) {
    _lastOrderedItems.removeWhere((item) => item.food == order.items.first.food);
  }
  _upcomingOrders.remove(order);
  notifyListeners();
}

  // ✅ Add a new order to upcoming orders
  void addOrder(Order order) {
  _upcomingOrders.add(order); // Add the entire Order, not just a CartItem
  _orderSteps[order.orderNumber] = 1; // Initialize the order's step to 1
  _orderNumbers[order] = _nextOrderNumber++; // Assign a unique order number
  incrementOrderNumber();
  notifyListeners(); // Notify listeners for UI update
}


  // ✅ Get the current step of an order
  int getOrderStep(Order order) {
    return _orderSteps[order.orderNumber] ?? 1;
  }

  // ✅ Get Order Number
  int getOrderNumber(CartItem order) {
    return _orderNumbers[order] ?? 0;
  }

  // ✅ Move Order to Next Step
  void nextOrderStep(int orderNumber) {
  if (_orderSteps[orderNumber] == 4) return; // ✅ Stop at last step
  _orderSteps[orderNumber] = (_orderSteps[orderNumber] ?? 0) + 1;
  notifyListeners(); // ✅ Ensure UI updates
}


  int getNextOrderNumber(){
    return _nextOrderNumber;
  }






// void updateOrderTime(int orderNumber, int remainingSeconds) {
//   final order = _orders.firstWhereOrNull((o) => o.orderNumber == orderNumber);
//   if (order != null) {
//     order.remainingSeconds = remainingSeconds < 0 ? 0 : remainingSeconds;
//     notifyListeners();

//     // ✅ Automatically mark order as complete if time expires
//     if (order.remainingSeconds == 0) {
//       completeOrder(orderNumber);
//     }
//   }
// }




  // ✅ Move order to "Completed Orders"
// final List<Order> _completedOrdersList = [];

void completeOrder(int orderNumber) {
  Order? order;

  // Try to find in _orders
  order = _orders.firstWhereOrNull((o) => o.orderNumber == orderNumber);
  if (order != null) {
    _orders.remove(order);
  }

  // Try to find in _upcomingOrders if not found
  if (order == null) {
    order = _upcomingOrders.firstWhereOrNull((o) => o.orderNumber == orderNumber);
    if (order != null) {
      _upcomingOrders.remove(order);
    }
  }

  if (order != null) {
    _completedOrders.add(order);
    notifyListeners();
  }
}





// ✅ Get completed orders


  // ✅ Update Stocks
  void updateStock(Food food, int newQuantity) {
    food.availableQuantity = newQuantity;
    notifyListeners();
  }

  // ✅ Clear all orders
  void clearOrders() {
    _upcomingOrders.clear();
    _completedOrders.clear();
    _orderSteps.clear();
    notifyListeners();
  }


  void incrementOrderNumber(){
    _nextOrderNumber++;
    notifyListeners();
  }

  // ✅ Check if two addon lists are the same
  bool _areAddonsEqual(List<Addon> list1, List<Addon> list2) {
    return const DeepCollectionEquality().equals(
      list1.map((e) => e.name).toList(),
      list2.map((e) => e.name).toList(),
    );
  }
}