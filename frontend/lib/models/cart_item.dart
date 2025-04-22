import '../food.dart';


class CartItem {
  String cartId;
  Food food;
  int quantity;
  String paymentMode;
  String otp;

  CartItem({
    required this.cartId,
    required this.food,
    this.quantity = 1,
    required this.paymentMode,
    required this.otp,
  });

  double get totalPrice {
    return food.price * quantity;
  }

  // From JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cart_id'] ?? '',
      food: Food.fromJson(json['food'] ?? {}),
      quantity: json['quantity'] ?? 1,
      paymentMode: json['payment_mode'] ?? '',
      otp: json['otp'] ?? '',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'food': food.toJson(),
      'quantity': quantity,
      'payment_mode': paymentMode,
      'otp': otp,
    };
  }
}
