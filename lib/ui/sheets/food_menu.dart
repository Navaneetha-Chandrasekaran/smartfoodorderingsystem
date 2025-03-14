import 'package:bitetimenew/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'food.dart';

class FoodMenu extends ChangeNotifier{
final List<Food> _menu = [
  Food(
    name: 'Chicken Biriyani',
    description: 'Fragrant rice and tender chicken slow-cooked with aromatic spices, served with raita.', 
    image: 'assets/food/cb.png', 
    price: 80, 
    category: FoodCategory.lunch, 
    availableAddons: [
      Addon(name: 'Raita'),
      Addon(name: 'Extra Chicken'),
      Addon(name: 'Egg')
    ],
    isVeg: false,
  ),
  Food(
    name: 'Chicken Fried Rice',
    description: 'A delicious mix of seasoned rice and succulent chicken, cooked to perfection with aromatic flavors.', 
    image: 'assets/food/cfc.png', 
    price: 70, 
    category: FoodCategory.lunch, 
    availableAddons: [
      // Addon
      Addon(name: 'Medium Spice', spiceLevel: SpiceLevel.medium), // 🌶 Medium Spice
      Addon(name: 'More Spice', spiceLevel: SpiceLevel.full), // 🔥 Full Spice
    ],
    isVeg: false,
  ),
  
  Food(
    name: 'Chicken Biriyani',
    description: 'Fragrant rice and tender chicken slow-cooked with aromatic spices, served with raita.', 
    image: 'assets/food/cb.png', 
    price: 80, 
    category: FoodCategory.lunch, 
    availableAddons: [
      // Addon
    ],
    isVeg: false,
  ),
  Food(
    name: 'Chicken Biriyani',
    description: 'Fragrant rice and tender chicken slow-cooked with aromatic spices, served with raita.', 
    image: 'assets/food/cb.png', 
    price: 80, 
    category: FoodCategory.lunch, 
    availableAddons: [
      // Addon
    ],
    isVeg: false,
  ),
  Food(
    name: 'Chicken Biriyani',
    description: 'Fragrant rice and tender chicken slow-cooked with aromatic spices, served with raita.', 
    image: 'assets/food/cb.png', 
    price: 80, 
    category: FoodCategory.lunch, 
    availableAddons: [
      // Addon
    ],
    isVeg: false,
  ),
];

  List<Food> get menu => _menu; // ✅ Get available food items
  List<CartItem> get cart => _cart; // ✅ Get user cart

  // ✅ User Cart
  final List<CartItem> _cart = [];

  // ✅ Add food to cart (Now includes selectedAddons)
void addToCart(Food food, List<Addon> selectedAddons) {
  CartItem? cartItem = _cart.firstWhereOrNull((item) {
    // Check if the food item & addons match
    bool isSameFood = item.food == food;
    bool isSameAddons = _areAddonsEqual(item.selectedAddons, selectedAddons);

    return isSameFood && isSameAddons;
  });

  // ✅ If item already exists, increase its quantity:
  if (cartItem != null) {
    cartItem.quantity++;
  } else {
    // ✅ Add new item with selected addons
    _cart.add(
      CartItem(
        food: food,
        selectedAddons: selectedAddons,
        quantity: 1,
      ),
    );
  }
  
  notifyListeners(); // ✅ Update UI
}

// ✅ Function to update quantity (Optional, for better reusability)
void updateQuantity(CartItem cartItem, int newQuantity) {
  if (newQuantity > 0) {
    cartItem.quantity = newQuantity;
  } else {
    _cart.remove(cartItem);
  }
  
  notifyListeners();
}

  // ✅ Remove item from cart
  void removeFromCart(CartItem cartItem) {
    int cartIndex = _cart.indexOf(cartItem);
    if (cartIndex != -1) {
      if (_cart[cartIndex].quantity > 1) {
        _cart[cartIndex].quantity--;
      } else {
        _cart.removeAt(cartIndex);
      }
    }
    notifyListeners();
  }

  // ✅ Remove a specific addon from an item
  void removeAddon(CartItem cartItem, Addon addon) {
    int cartIndex = _cart.indexOf(cartItem);
    if (cartIndex != -1) {
      _cart[cartIndex].selectedAddons.remove(addon);
      notifyListeners();
    }
  }

  // ✅ Get total price (Food only, since addons are free)
  double getTotalPrice() {
    double total = 0;
    for (CartItem cartItem in _cart) {
      total += cartItem.food.price * cartItem.quantity;
    }
    return total;
  }

  // ✅ Get total number of items in the cart
  int getTotalItemCount() {
    int totalItemCount = 0;
    for (CartItem cartItem in _cart) {
      totalItemCount += cartItem.quantity;
    }
    return totalItemCount;
  }

  // ✅ Clear cart
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ✅ Check if two addon lists are the same
  bool _areAddonsEqual(List<Addon> list1, List<Addon> list2) {
    final deepEq = const DeepCollectionEquality().equals;
    return deepEq(
      list1.map((e) => e.name).toList(),
      list2.map((e) => e.name).toList(),
    );
  }

  // ✅ Add new food item to the menu
  void addFood(Food food) {
    _menu.add(food);
    notifyListeners();
  }
}