import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/buttons.dart';
import '../../../models/event_card.dart';
import '../../../models/timeline.dart';
import '../../../models/cart_item.dart';
import '../../../food_menu.dart';

class OrderTimeline {
  int currentStep;
  String orderOtp;
  Timer? pickupTimer;
  int remainingSeconds;
  bool pickupTimeExpired;
  bool orderCancelled;
  final String orderNumber;

  OrderTimeline({
    required this.orderNumber,
    int? currentStep,
    int? remainingSeconds,
    bool? pickupTimeExpired,
  })  : currentStep = currentStep ?? 0,  
        orderOtp = (1000 + Random().nextInt(9000)).toString(),
        remainingSeconds = remainingSeconds ?? 600, 
        pickupTimeExpired = pickupTimeExpired ?? false,
        orderCancelled = false;
}


class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final List<OrderTimeline> _orders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeOrders());
  }

  void _initializeOrders() {
  final foodMenu = Provider.of<FoodMenu>(context, listen: false);
  final activeOrders = foodMenu.getActiveOrders();

  setState(() {
    for (var order in activeOrders) {
      final existing = _orders.indexWhere((o) => o.orderNumber == order.orderNumber.toString());
      if (existing == -1) {
        final newOrder = OrderTimeline(
          orderNumber: order.orderNumber.toString(),
          currentStep: order.step,
          remainingSeconds: order.remainingSeconds,
          pickupTimeExpired: order.pickupTimeExpired,
        );
        _orders.add(newOrder);

        if (newOrder.currentStep < 4) {
          _startTimelineAnimation(newOrder);
        } else if (!newOrder.pickupTimeExpired) {
          _startPickupTimer(newOrder);
        }
      }
    }
  });

  _startOrderTimers();
}


  void _startOrderTimers() {
    for (var order in _orders) {
      _startTimelineAnimation(order);
    }
  }

 Future<void> _startTimelineAnimation(OrderTimeline order) async {
  for (int i = order.currentStep + 1; i <= 4; i++) { // ✅ Resume from last step
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      order.currentStep = i;
      if (i == 4) _startPickupTimer(order);
    });
  }
}



  void _startPickupTimer(OrderTimeline order) {
    if (order.pickupTimer != null) return; 

    order.pickupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (order.remainingSeconds > 0) {
        setState(() {
          order.remainingSeconds--; // ✅ Decrease remaining seconds every tick
        });
      } else {
        timer.cancel();
        setState(() {
          order.pickupTimeExpired = true;
        });
      }
    });
  }



void _cancelOrder(int index, String reason) {
  if (index < 0 || index >= _orders.length) return;

  final foodMenu = Provider.of<FoodMenu>(context, listen: false);
  int orderNum = int.tryParse(_orders[index].orderNumber) ?? -1;
  if (orderNum == -1) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order not found!")));
    return;
  }

  foodMenu.cancelOrder(orderNum);

  _orders[index].pickupTimer?.cancel();
  _orders[index].pickupTimer = null;

  setState(() {
    _orders[index].orderCancelled = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order cancelled: $reason"))); // ✅ Snackbar appears after UI update
  });
}


  @override
  void dispose() {
    for (var order in _orders) {
      order.pickupTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Order Timeline"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _orders.isEmpty // ✅ Check _orders instead of lastOrderedItems
          ? _buildNoOrderMessage()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOtpDisplay(order.orderOtp),
                        const SizedBox(height: 20),
                        _buildOrderedFoodList(Provider.of<FoodMenu>(context), order.orderNumber), // ✅ Fetch correct ordered items
                        const SizedBox(height: 20),
                        _buildTimelineSteps(order.currentStep),
                        if (order.currentStep == 4) _buildPickupTimer(order),
                        const SizedBox(height: 20),
                        if (!order.orderCancelled)
                          Center(
                            child: CustomButton(
                              label: "Cancel Order",
                              gradientColors: [Colors.redAccent, Colors.red],
                              onPressed: () => _showCancelReasonSheet(context, index),
                              hasBorder: true,
                              borderColor: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOtpDisplay(String otp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1)],
      ),
      child: Center(
        child: Text(
          "Order OTP: $otp",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

   /// ✅ **Timeline Steps with Animated Event Cards**
  Widget _buildTimelineSteps(int currentStep) {
    return Column(
      children: [
        Timeline(isFirst: true, isLast: false, isPast: currentStep >= 1, eventCard: EventCard(isPast: currentStep >= 1, child: const Text('Order Placed'))),
        Timeline(isFirst: false, isLast: false, isPast: currentStep >= 2, eventCard: EventCard(isPast: currentStep >= 2, child: const Text('Order Confirmed'))),
        Timeline(isFirst: false, isLast: false, isPast: currentStep >= 3, eventCard: EventCard(isPast: currentStep >= 3, child: const Text('Order Getting Ready'))),
        Timeline(isFirst: false, isLast: true, isPast: currentStep >= 4, eventCard: EventCard(isPast: currentStep >= 4, child: const Text('Ready for Pickup'))),
      ],
    );
  }

  /// ✅ **Pickup Timer UI**
  Widget _buildPickupTimer(OrderTimeline order) {
    int minutes = order.remainingSeconds ~/ 60;
    int seconds = order.remainingSeconds % 60;

    return Center(
      child: Text(
        order.pickupTimeExpired
            ? "Pickup time expired!"
            : "Pickup Time Remaining: $minutes:${seconds.toString().padLeft(2, '0')}",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: order.pickupTimeExpired ? Colors.red : Colors.green),
      ),
    );
  }


  Widget _buildOrderedFoodList(FoodMenu foodMenu, String orderNumber) {
  // Convert orderNumber (String) to an integer for correct comparison
  final int parsedOrderNumber = int.tryParse(orderNumber) ?? -1; // Safely parse the string to an integer

  // Fetch the ordered items by matching the order number
  final orderedItems = foodMenu.getActiveOrders().firstWhere(
    (order) => order.orderNumber == parsedOrderNumber, // Compare integer to integer
    orElse: () => Order(
      orderNumber: -1, 
      items: [], 
      orderPlacedTime: DateTime.now(), shopId: '',
    ), // Return an empty order if not found
  ).items;

  if (orderedItems.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Ordered Items:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orderedItems.length,
        itemBuilder: (context, index) {
          return _buildFoodItemTile(orderedItems[index]);
        },
      ),
    ],
  );
}



  Widget _buildFoodItemTile(CartItem cartItem) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Image.asset(cartItem.food.image, width: 50, height: 50, fit: BoxFit.cover),
        title: Text(cartItem.food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Qty: ${cartItem.quantity}"),
        trailing: Text("₹${(cartItem.food.price * cartItem.quantity).toStringAsFixed(2)}"),
      ),
    );
  }

  Widget _buildNoOrderMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/no-order.png', width: 200),
          const SizedBox(height: 20),
          const Text("No current orders.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Looks like you haven't placed an order yet.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          CustomButton(label: 'Browse Menu', gradientColors: [Colors.blue, Colors.purple]),
        ],
      ),
    );
  }

  void _showCancelReasonSheet(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return CancelReasonSheet(
          orderNumber: _orders[index].orderNumber, 
          onConfirm: (reason) {
          Navigator.pop(context); // ✅ Close bottom sheet before navigation
          _cancelOrder(index, reason); // ✅ Cancel the order
          },
        );
      },
    );
  }


    // ✅ Show BottomSheet for cancel reasons
// void _showCancelReasonSheet(BuildContext context, int orderIndex) {
//   final foodMenu = Provider.of<FoodMenu>(context, listen: false);
//   final orders = foodMenu.getActiveOrders();

//   if (orderIndex < 0 || orderIndex >= orders.length) return; // ✅ Prevent crashes

//   showModalBottomSheet(
//     context: context,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (context) {
//       return CancelReasonSheet(
//         orderNumber: orders[orderIndex].orderNumber.toString(), // ✅ Pass order number
//         onConfirm: (String reason) {
//           _cancelOrder(context, orderIndex, reason); // ✅ Cancel order correctly
//         },
//       );
//     },
//   );
// }


}

// ✅ Cancel Reason BottomSheet
class CancelReasonSheet extends StatefulWidget {
  final Function(String) onConfirm;
  final String orderNumber;

  const CancelReasonSheet({
    required this.onConfirm,
    required this.orderNumber,
  });

  @override
  _CancelReasonSheetState createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<CancelReasonSheet> {
  String? _selectedReason;
  final List<String> _reasons = [
    "Class schedule changed",
    "Unexpected lecture/timetable update",
    "Exam or test announced suddenly",
    "Lab session extended",
    "Meeting with professor",
    "Other (Specify in notes)",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Why do you want to cancel?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // ✅ List of reasons
          Expanded(
            child: ListView(
              children: _reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                  )).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Confirm Cancellation Button
          ElevatedButton(
            onPressed: _selectedReason == null
              ? null
              : () {
                  final reason = _selectedReason!;
                  Navigator.pop(context);        // ✅ Close the bottom sheet first
                  widget.onConfirm(reason);      // ✅ Then call the callback safely
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Confirm Cancellation"),
          ),
        ],
      ),
    );
  }
}
