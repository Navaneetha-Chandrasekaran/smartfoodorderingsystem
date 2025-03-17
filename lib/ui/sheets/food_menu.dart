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
    image: 'assets/food/cfc.png', 
    price: 70, 
    category: FoodCategory.lunch, 
    availableQuantity: 100,
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
    availableQuantity: 100,
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
    availableQuantity: 100,
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
    availableQuantity: 100,
    availableAddons: [
      // Addon
    ],
    isVeg: false,
  ),
];


  List<Food> get menu => _menu;
  List<CartItem> get cart => _cart;

  final List<CartItem> _cart = [];

  // ✅ Add to Cart (Decreases Available Stock)
  void addToCart(Food food, List<Addon> selectedAddons) {
    if (food.availableQuantity > 0) { // ✅ Only add if in stock
      food.availableQuantity--; // ✅ Reduce stock

      CartItem? cartItem = _cart.firstWhereOrNull((item) {
        bool isSameFood = item.food == food;
        bool isSameAddons = _areAddonsEqual(item.selectedAddons, selectedAddons);
        return isSameFood && isSameAddons;
      });

      if (cartItem != null) {
        cartItem.quantity++;
      } else {
        _cart.add(CartItem(food: food, selectedAddons: selectedAddons, quantity: 1));
      }

      notifyListeners();
    }
  }

  // ✅ Remove from Cart (Restores Stock)
  void removeFromCart(CartItem cartItem) {
    int cartIndex = _cart.indexOf(cartItem);
    if (cartIndex != -1) {
      _cart[cartIndex].food.availableQuantity++; // ✅ Restore stock
      if (_cart[cartIndex].quantity > 1) {
        _cart[cartIndex].quantity--;
      } else {
        _cart.removeAt(cartIndex);
      }
    }
    notifyListeners();
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
      item.food.availableQuantity += item.quantity; // ✅ Restore stock
    }
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
}