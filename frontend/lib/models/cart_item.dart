import '../food.dart';


class CartItem {
  String cartId;
  Food food;
  int quantity;

  CartItem({
    required this.cartId,
    required this.food,
    this.quantity = 1, required String paymentMode, required String otp,
  });

  double get totalPrice {
    return food.price * quantity;
  }

  // From JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cart_id'],
      food: Food.fromJson(json['food']),
      quantity: json['quantity'] ?? 1, paymentMode: '', otp: '',
    );
  }
}
