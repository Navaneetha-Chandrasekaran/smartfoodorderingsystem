import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../food_menu.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodMenu>(
      builder: (context, foodMenu, child) {
        final completedOrders = foodMenu.completedOrders; // ✅ Live update

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text("📋 Completed Orders"),
            backgroundColor: Colors.green,
            centerTitle: true,
            elevation: 3,
          ),
          body: Column(
            children: [
              Padding(
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
                      Text(
                        "✅ Total Orders Completed: ${completedOrders.length}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: completedOrders.isEmpty
                    ? const Center(
                        child: Text(
                          "No completed orders yet!",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: completedOrders.length,
                        itemBuilder: (context, index) {
                          final order = completedOrders[index];
                          final orderNumber = foodMenu.getOrderNumber(order); // ✅ Fetch order number

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: Colors.black26,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  // ✅ Order Number with Highlighted Box
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Order No: #$orderNumber",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // ✅ Image, Name, and Quantity
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(order.food.image, width: 60, height: 60, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          order.food.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "Qty: ${order.quantity}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // ✅ OTP & Cost
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.red[600], size: 20),
                                          const SizedBox(width: 4),
                                          Text(
                                            "OTP: ${order.otp ?? "----"}",
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red[600]),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "₹${(order.food.price * order.quantity).toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // ✅ Payment Mode with Icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payment, color: Colors.purple, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Payment: ${order.paymentMode ?? "Unknown"}",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
