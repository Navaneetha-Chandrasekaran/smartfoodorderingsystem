import '../food.dart';


class CartItem {
  final Food food;
  int quantity;
  final String shopId;
  String? cartId;
  String? otp;
  String? paymentMode;

  CartItem({
    required this.food,
    this.quantity = 1,
    required this.shopId,
    this.cartId,
    this.otp,
    this.paymentMode,
  });

  double get totalPrice {
    return food.price * quantity;
  }

  // From JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      food: Food.fromJson(json['food'] ?? {}),
      quantity: json['quantity'] ?? 1,
      shopId: json['shop_id'] ?? '',
      cartId: json['cart_id'],
      otp: json['otp'],
      paymentMode: json['payment_mode'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'food': food.toJson(),
      'quantity': quantity,
      'shop_id': shopId,
      'cart_id': cartId,
      'otp': otp,
      'payment_mode': paymentMode,
    };
  }
}
