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
          final totalOrders = foodMenu.getActiveOrders().length;
          // final completedOrdersCount = foodMenu.getCompletedOrders().length; // Assuming this method exists
          
          return ListView(
            children: [
              // Header Section
              _buildHeader(),
              
              // Order Summary Section
              // _buildOrderSummary(context, totalOrders, completedOrdersCount),
              
              // Upcoming Orders Section
              _buildUpcomingOrders(foodMenu),
            ],
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
      final activeOrders = foodMenu.getActiveOrders();

      return activeOrders.isEmpty
          ? _buildEmptyOrders()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Don't scroll inside main ListView
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return _buildOrderTile(order, foodMenu, order.orderNumber);
              },
            );
    }


    /// ✅ **Empty State Message**
    Widget _buildEmptyOrders() {
      return const Center(
        child: Text("No upcoming orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
      );
    }

    /// ✅ **Order Tile Design**
    Widget _buildOrderTile(Order order, FoodMenu foodMenu, int orderNumber) {
  double orderCost = order.items.fold(0, (total, item) => total + (item.food.price * item.quantity));

  return StatefulBuilder(
    builder: (context, setLocalState) {
      if (order.readyTime != null && !order.expired) {
        final now = DateTime.now();
        final deadline = order.readyTime!.add(const Duration(minutes: 10));
        final remaining = deadline.difference(now);

        if (remaining.isNegative && !order.expired) {
          // Expire the order
          order.expired = true;
          foodMenu.completeOrder(orderNumber); // Move it to completed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {}); // Refresh main screen
          });
        } else {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setLocalState(() {});
          });
        }
      }

      String countdownText = "--:--";
      Color timerColor = Colors.black;

      if (order.readyTime != null && !order.expired) {
        final deadline = order.readyTime!.add(const Duration(minutes: 10));
        final remaining = deadline.difference(DateTime.now());

        int minutes = remaining.inMinutes;
        int seconds = remaining.inSeconds % 60;
        countdownText = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

        if (remaining.inMinutes < 2) timerColor = Colors.red;
      }

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Order Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: order.expired ? Colors.red[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.expired
                      ? "⏱️ Order No: #$orderNumber (Expired)"
                      : "Order No: #$orderNumber",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: order.expired ? Colors.red : Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Items
              Column(
                children: order.items.map((item) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(item.food.image, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Text("Qty: ${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // OTP & Cost
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("OTP: ${order.items.first.otp ?? "----"}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red[600])),
                  Text("₹${orderCost.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),

              // Countdown timer
              if (order.readyTime != null)
                Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      order.expired ? "Order Expired" : countdownText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: order.expired ? Colors.red : timerColor,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 10),

              // Status Button
              if (!order.expired) _buildStatusButton(order, foodMenu, orderNumber),
            ],
          ),
        ),
      );
    },
  );
}



    /// ✅ **Status Button**
    /// ✅ **Status Button (Updated)**
  Widget _buildStatusButton(Order order, FoodMenu foodMenu, int orderNumber) {
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
      if (step == 1) {
        for (var item in order.items) {
          final currentStock = item.food.availableQuantity;
          final updatedStock = currentStock - item.quantity;
          foodMenu.updateStock(item.food, updatedStock);
        }
        foodMenu.nextOrderStep(order.orderNumber);
        setState(() {});
      } else if (step == 3 && order.readyTime == null) {
        // Just before moving to step 4
        order.readyTime = DateTime.now();
        foodMenu.nextOrderStep(order.orderNumber);
        setState(() {});
      } else if (step < 4) {
        foodMenu.nextOrderStep(order.orderNumber);
        setState(() {});
      } else {
        _verifyOTP(order, foodMenu, orderNumber);
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





    /// ✅ **OTP Verification Dialog**
    void _verifyOTP(Order order, FoodMenu foodMenu, int orderNumber) {
  TextEditingController otpController = TextEditingController();

  // ✅ No need to find the order again – it's already passed in
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Verify OTP"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter the OTP received by the customer."),
          const SizedBox(height: 10),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Enter OTP",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final enteredOtp = otpController.text.trim();
            final actualOtp = order.items.first.otp;

            if (enteredOtp == actualOtp) {
              foodMenu.completeOrder(order.orderNumber); // ✅ Move to completed
              Navigator.pop(context);
              setState(() {}); // ✅ Refresh dashboard to remove the order

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ Order #$orderNumber completed successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Incorrect OTP! Please try again."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text("Verify"),
        ),
      ],
    ),
  );
}
  }



    void _addRandomOrder(BuildContext context) {
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    final randomFood = foodMenu.menu[Random().nextInt(foodMenu.menu.length)];
    
    // Create an Order instead of a single CartItem
    final newOrder = Order(
      orderNumber: foodMenu.nextOrderNumber,  // Generate order number
      items: [
        CartItem(
          food: randomFood,
          // selectedAddons: [],
          quantity: Random().nextInt(3) + 1,
          otp: (1000 + Random().nextInt(9000)).toString(),
          paymentMode: Random().nextBool() ? "Cash" : "GPay",
        ),
      ],
      pickupTime: TimeOfDay.now(),
      orderPlacedTime: DateTime.now(),
    );

    // Add the entire Order object
    foodMenu.addOrder(newOrder);  // Pass Order, not CartItem
  }
