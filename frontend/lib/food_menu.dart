import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'food.dart';
import 'models/cart_item.dart';

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
  List<CartItem> _lastOrderedItems = [];
  List<CartItem> _upcomingOrders = [];
  final List<CartItem> _completedOrders = [];
  final Map<CartItem, int> _orderSteps = {};
  final Map<CartItem, int> _orderNumbers = {};
  int _nextOrderNumber = 1;
  bool _isOrderCancelled = false;

  // ✅ Getters
  List<Food> get menu => _menu;
  List<CartItem> get cart => _cart;
  List<CartItem> get lastOrderedItems => _lastOrderedItems;
  List<CartItem> get upcomingOrders => _upcomingOrders;
  List<CartItem> get completedOrders => _completedOrders;
  bool get isOrderCancelled => _isOrderCancelled;

  // ✅ Add to Cart (Decreases Available Stock)
  void addToCart(Food food, List<Addon> selectedAddons) {
    if (food.availableQuantity > 0) {
      food.availableQuantity--;

      CartItem? cartItem = _cart.firstWhereOrNull((item) =>
          item.food == food && _areAddonsEqual(item.selectedAddons, selectedAddons));

      if (cartItem != null) {
        cartItem.quantity++;
      } else {
        _cart.add(CartItem(food: food, selectedAddons: selectedAddons, quantity: 1));
      }
      notifyListeners();
    }
  }

  // ✅ Place Order (Saves Last Ordered Items & Clears Cart)
  void placeOrder() {
    if (_cart.isNotEmpty) {
      _lastOrderedItems = List.from(_cart);
      _upcomingOrders.addAll(_cart);
      _cart.clear();
      notifyListeners();
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

  // ✅ Clear last ordered items when order is canceled
  void cancelOrder() {
    _lastOrderedItems.clear();
    _upcomingOrders.clear();
    _isOrderCancelled = true;
    notifyListeners();
  }

  // ✅ Reset order cancellation status
  void resetOrderStatus() {
    _isOrderCancelled = false;
    notifyListeners();
  }

  // ✅ Mark an order as ready
  void markOrderReady(CartItem order) {
    _lastOrderedItems.remove(order);
    _upcomingOrders.remove(order);
    notifyListeners();
  }

  // ✅ Add a new order to upcoming orders
  void addOrder(CartItem order) {
    _upcomingOrders.add(order);
    _orderSteps[order] = 1;
    _orderNumbers[order] = _nextOrderNumber++;
    notifyListeners();
  }

  // ✅ Get the current step of an order
  int getOrderStep(CartItem order) {
    return _orderSteps[order] ?? 1;
  }

  // ✅ Get Order Number
  int getOrderNumber(CartItem order) {
    return _orderNumbers[order] ?? 0;
  }

  // ✅ Move the order to the next step
  void nextOrderStep(CartItem order) {
    if (_orderSteps.containsKey(order)) {
      int currentStep = _orderSteps[order]!;

      // ✅ Only reduce stock when confirming the order (Step 1 → Step 2)
      if(currentStep == 1){
        if(order.food.availableQuantity >= order.quantity){
          order.food.availableQuantity -= order.quantity;
        }
        else{
          order.food.availableQuantity = 0; // Prevents negative values
        }
      }
      _orderSteps[order] = (_orderSteps[order]! + 1).clamp(1, 4);
      notifyListeners();
    }
  }

  // ✅ Move order to "Completed Orders"
  void completeOrder(CartItem order, [int? orderNumber]) {
    if (_upcomingOrders.contains(order)) {
      _upcomingOrders.remove(order);
      _completedOrders.add(order);
      _orderSteps.remove(order);

      // Deduct stock based on order quantity:
      order.food.availableQuantity -= order.quantity;

      //Prevents negative stock values:
      if(order.food.availableQuantity < 0){
        order.food.availableQuantity = 0;
      }
      notifyListeners();
    }
  }

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

  // ✅ Check if two addon lists are the same
  bool _areAddonsEqual(List<Addon> list1, List<Addon> list2) {
    return const DeepCollectionEquality().equals(
      list1.map((e) => e.name).toList(),
      list2.map((e) => e.name).toList(),
    );
  }
}
