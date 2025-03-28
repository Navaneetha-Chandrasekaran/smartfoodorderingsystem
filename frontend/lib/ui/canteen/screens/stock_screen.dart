// ignore_for_file: deprecated_member_use

import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../food.dart';
import '../../../food_menu.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final Map<Food, int> updatedStock = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodMenu>(
      builder: (context, foodMenu, child) {
        return Scaffold(
          appBar: AppBar(
            title: const SubTitles(title: "📦 Stock Management"),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: () => _saveStockChanges(foodMenu),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              itemCount: foodMenu.menu.length,
              itemBuilder: (context, index) {
                final food = foodMenu.menu[index];
                return _buildStockItem(food);
              },
            ),
          ),
        );
      },
    );
  }

  /// ✅ **Stock Item UI**
  Widget _buildStockItem(Food food) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(food.image, width: 65, height: 65, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 5),
                  Consumer<FoodMenu>(
                    builder: (context, foodMenu, child) {
                      return Text("Available: ${foodMenu.menu.firstWhere((item) => item.name == food.name).availableQuantity}");
                    },
                  ),
                ],
              ),
            ),
            _buildStockStepper(food),
          ],
        ),
      ),
    );
  }

  /// ✅ **Stock Counter Stepper with Animation**
  Widget _buildStockStepper(Food food) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if ((updatedStock[food] ?? food.availableQuantity) > 0) {
                updatedStock[food] = (updatedStock[food] ?? food.availableQuantity) - 1;
              }
            });
          },
          child: _iconButton(Icons.remove_circle, Colors.redAccent),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              (updatedStock[food] ?? food.availableQuantity).toString(),
              key: ValueKey<int>(updatedStock[food] ?? food.availableQuantity),
              // style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              updatedStock[food] = (updatedStock[food] ?? food.availableQuantity) + 1;
            });
          },
          child: _iconButton(Icons.add_circle, Colors.green),
        ),
      ],
    );
  }

  /// ✅ **Circular Icon Button for Stepper**
  Widget _iconButton(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
      child: Icon(icon, color: color, size: 32),
    );
  }

  /// ✅ **Save Updated Stock with Undo Option**
  void _saveStockChanges(FoodMenu foodMenu) {
  Map<Food, int> previousStock = {}; // Store previous values
  updatedStock.forEach((food, newQuantity) {
    previousStock[food] = food.availableQuantity; // Store old quantity
    foodMenu.updateStock(food, newQuantity);  // Notify UI to update
  });

  // ✅ Show SnackBar with Undo Option
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text("✅ Stock updated successfully!"),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: "Undo",
        textColor: Colors.white,
        onPressed: () {
          setState(() {
            previousStock.forEach((food, oldQuantity) {
              foodMenu.updateStock(food, oldQuantity);  //Calls updateStock
              updatedStock[food] = oldQuantity; // ✅ Ensure UI reflects the previous state
            });
          });
        },
      ),
    ),
  );
}

}
