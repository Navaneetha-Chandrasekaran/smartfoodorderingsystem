import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../food_menu.dart';
import '../../../models/cart_item.dart';

class CanteenDashboard extends StatefulWidget {
  const CanteenDashboard({super.key});

  @override
  State<CanteenDashboard> createState() => _CanteenDashboardState();
}

class _CanteenDashboardState extends State<CanteenDashboard> {
  int nextOrderNumber = 1; // ✅ Order number sequence

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodMenu>(
      builder: (context, foodMenu, child) {
        final totalOrders = foodMenu.upcomingOrders.length + foodMenu.completedOrders.length;
        final completedOrdersCount = foodMenu.completedOrders.length;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              _buildHeader(),
              _buildOrderSummary(context, totalOrders, completedOrdersCount),
              _buildUpcomingOrders(foodMenu),
            ],
          ),
        );
      },
    );
  }

  /// ✅ **Stylish Header with Gradient**
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)], // **Improved Green Gradient**
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🍽️ Canteen Dashboard",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(
            "Track orders, manage requests, and serve efficiently",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// ✅ **Order Summary with Live Updates**
  Widget _buildOrderSummary(BuildContext context, int totalOrders, int completedOrdersCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem("📦 Total Orders", totalOrders.toString(), Colors.green),
                _buildSummaryItem("✅ Completed Orders", completedOrdersCount.toString(), Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _addRandomOrder(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Order", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ **Order Summary Styling**
  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  /// ✅ **Upcoming Orders List**
  Widget _buildUpcomingOrders(FoodMenu foodMenu) {
    return Expanded(
      child: foodMenu.upcomingOrders.isEmpty
          ? _buildEmptyOrders()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: foodMenu.upcomingOrders.length,
              itemBuilder: (context, index) {
                return _buildOrderTile(foodMenu.upcomingOrders[index], foodMenu, index + 1);
              },
            ),
    );
  }

  /// ✅ **Empty State Message**
  Widget _buildEmptyOrders() {
    return const Center(
      child: Text("No upcoming orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  /// ✅ **Order Tile Design**
  Widget _buildOrderTile(CartItem order, FoodMenu foodMenu, int orderNumber) {
    double orderCost = order.food.price * order.quantity;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ✅ **Centered Order Number**
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Order No: #$orderNumber",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),

            // ✅ **Food Image, Name & Quantity**
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(order.food.image, width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(order.food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Text("Qty: ${order.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            // ✅ **OTP & Cost**
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("OTP: ${order.otp ?? "----"}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red[600])),
                Text("₹${orderCost.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),

            // ✅ **Centered Status Button**
            _buildStatusButton(order, foodMenu, orderNumber),
          ],
        ),
      ),
    );
  }

  /// ✅ **Status Button**
  Widget _buildStatusButton(CartItem order, FoodMenu foodMenu, int orderNumber) {
  int step = foodMenu.getOrderStep(order);
  String buttonText;
  Color buttonColor;

  switch (step) {
    case 1:
      buttonText = "Confirm Order";
      buttonColor = Colors.red;
      break;
    case 2:
      buttonText = "Prepare Order";
      buttonColor = Colors.yellow;
      break;
    case 3:
      buttonText = "Mark Ready";
      buttonColor = Colors.orange;
      break;
    case 4:
      buttonText = "Completed";
      buttonColor = Colors.green;
      break;
    default:
      buttonText = "Next Step";
      buttonColor = Colors.black;
  }

  return ElevatedButton(
    onPressed: () {
      if (step < 4) {
        foodMenu.nextOrderStep(order);
      } else {
        foodMenu.completeOrder(order, orderNumber); // ✅ Pass order number to completed orders
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: buttonColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(
      buttonText,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
  }

}


  void _addRandomOrder(BuildContext context) {
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    final randomFood = foodMenu.menu[Random().nextInt(foodMenu.menu.length)];
    final newOrder = CartItem(
      food: randomFood,
      selectedAddons: [],
      quantity: Random().nextInt(3) + 1,
      otp: (1000 + Random().nextInt(9000)).toString(),
      paymentMode: Random().nextBool() ? "Cash" : "GPay",
    );

    foodMenu.addOrder(newOrder);
  }
