import 'package:bitetimenew/ui/sheets/food.dart';

class CartItem {
  Food food;
  List<Addon> selectedAddons;
  int quantity;

  CartItem({
    required this.food,
    this.selectedAddons = const[],
    this.quantity = 1,
  });

  double get totalPrice{
    return food.price * quantity;
  }
}
