import 'package:bitetimenew/food.dart';
import 'package:flutter/material.dart';

class CartItem {
  Food food;
  List<Addon> selectedAddons;
  int quantity;
  TimeOfDay? selectedTime;
  String? otp;
  String? paymentMode;

  CartItem({
    required this.food,
    this.selectedAddons = const[],
    this.quantity = 1,
    this.selectedTime,
    this.otp,
    this.paymentMode
  });

  double get totalPrice{
    return food.price * quantity; 
  }
}
