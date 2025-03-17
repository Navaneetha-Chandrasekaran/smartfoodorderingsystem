import 'package:bitetimenew/ui/sheets/food.dart';
import 'package:flutter/material.dart';

class CartItem {
  Food food;
  List<Addon> selectedAddons;
  int quantity;
  TimeOfDay? selectedTime;

  CartItem({
    required this.food,
    this.selectedAddons = const[],
    this.quantity = 1,
    this.selectedTime,
  });

  double get totalPrice{
    return food.price * quantity; 
  }
}
