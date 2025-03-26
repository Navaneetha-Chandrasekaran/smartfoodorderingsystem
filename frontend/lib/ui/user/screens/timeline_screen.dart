import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/buttons.dart';
import '../../../models/event_card.dart';
import '../../../models/timeline.dart';
import '../../../models/cart_item.dart';
import '../../../food_menu.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _currentStep = 0;
  String _orderOtp = '';
  Timer? _pickupTimer;
  int _remainingSeconds = 600; // ✅ 10-minute timer
  bool _pickupTimeExpired = false;
  bool _orderCancelled = false;

  @override
  void initState() {
    super.initState();
    _generateOtp();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimelineAnimation());
  }

  void _generateOtp() {
    setState(() {
      _orderOtp = (1000 + Random().nextInt(9000)).toString();
    });
  }

  void _startTimelineAnimation() async {
    for (int i = 0; i < 4; i++) {
      await Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _currentStep = i + 1;
          });

          if (_currentStep == 4) {
            _startPickupTimer();
          }
        }
      });
    }
  }

  void _startPickupTimer() {
    _pickupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _pickupTimeExpired = true);
      }
    });
  }

  void _cancelOrder(String reason) {
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    foodMenu.cancelOrder();
    _pickupTimer?.cancel();

    setState(() {
      _currentStep = 0;
      _orderOtp = '';
      _pickupTimeExpired = false;
      _remainingSeconds = 600;
      _orderCancelled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order cancelled: $reason")),
    );
  }

  @override
  void dispose() {
    _pickupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderedItems = Provider.of<FoodMenu>(context).lastOrderedItems;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Order Timeline"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: (_orderCancelled || orderedItems.isEmpty)
          ? _buildNoOrderMessage()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 20),
                _buildOtpDisplay(),
                const SizedBox(height: 20),
                _buildOrderedFoodList(orderedItems),
                const SizedBox(height: 20),
                _buildTimelineSteps(),
                if (_currentStep == 4) _buildPickupTimer(),
                const SizedBox(height: 20),
                CustomButton(
                  label: "Cancel Order",
                  gradientColors: [Colors.redAccent, Colors.red],
                  onPressed: () => _showCancelReasonSheet(context),
                  hasBorder: true,
                  borderColor: Colors.white,
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  /// ✅ **Stylish OTP Display**
  Widget _buildOtpDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1)],
      ),
      child: Center(
        child: Text(
          "Order OTP: $_orderOtp",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  /// ✅ **Timeline Steps with Animated Event Cards**
  Widget _buildTimelineSteps() {
    return Column(
      children: [
        Timeline(
          isFirst: true,
          isLast: false,
          isPast: _currentStep >= 1,
          eventCard: EventCard(isPast: _currentStep >= 1, child: const Text('Order Placed')),
        ),
        Timeline(
          isFirst: false,
          isLast: false,
          isPast: _currentStep >= 2,
          eventCard: EventCard(isPast: _currentStep >= 2, child: const Text('Order Confirmed')),
        ),
        Timeline(
          isFirst: false,
          isLast: false,
          isPast: _currentStep >= 3,
          eventCard: EventCard(isPast: _currentStep >= 3, child: const Text('Order Getting Ready')),
        ),
        Timeline(
          isFirst: false,
          isLast: true,
          isPast: _currentStep >= 4,
          eventCard: EventCard(isPast: _currentStep >= 4, child: const Text('Ready for Pickup')),
        ),
      ],
    );
  }

  /// ✅ **Pickup Timer UI**
  Widget _buildPickupTimer() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;

    return Center(
      child: Text(
        _pickupTimeExpired ? "Pickup time expired!" : "Pickup Time Remaining: $minutes:${seconds.toString().padLeft(2, '0')}",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _pickupTimeExpired ? Colors.red : Colors.green),
      ),
    );
  }

  /// ✅ **"No Orders" Message**
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
}


// ✅ Build Individual Ordered Food Tile
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

// ✅ Build Ordered Food List Widget
  Widget _buildOrderedFoodList(List<CartItem> orderedItems) {
  if (orderedItems.isEmpty) {
    return SizedBox(); // ✅ Ensures no empty list UI appears after cancel
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Ordered Items:",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orderedItems.length,
        itemBuilder: (context, index) {
          final cartItem = orderedItems[index];
          return _buildFoodItemTile(cartItem);
        },
      ),
    ],
  );
}

// ✅ Show Cancel Reason BottomSheet
void _showCancelReasonSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return CancelReasonSheet(onConfirm: (reason) {
        Navigator.pop(context); // ✅ Close BottomSheet

        // ✅ Trigger cancellation and update UI
        final timelineState = context.findAncestorStateOfType<_TimelineScreenState>();
        if (timelineState != null) {
          timelineState._cancelOrder(reason);
        }
      });
    },
  );
}


// ✅ Cancel Reason BottomSheet
class CancelReasonSheet extends StatefulWidget {
  final Function(String) onConfirm;
  const CancelReasonSheet({required this.onConfirm});

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
                    widget.onConfirm(_selectedReason!); // ✅ Call cancellation function

                    // ✅ Clear last ordered items and update UI
                    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
                    foodMenu.cancelOrder(); // Removes timeline and last ordered items

                    Navigator.pop(context); // ✅ Close BottomSheet

                    // ✅ Navigate back to refresh the screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const TimelineScreen()),
                    );
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