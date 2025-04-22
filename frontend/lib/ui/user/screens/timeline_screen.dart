import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';
import '../../../food.dart';
import '../../../models/buttons.dart';
import '../../../models/event_card.dart';
import '../../../models/timeline.dart';
import '../../../models/cart_item.dart';
import '../../../food_menu.dart';
import '../../../services/order_service.dart';
import '../../../services/shop_service.dart';
import '../../../services/auth/login_auth.dart';
import '../../../services/utils.dart';


class OrderTimeline {
  final String orderId;
  final List<CartItem> items;
  final DateTime pickupTime;
  final DateTime orderPlacedTime;
  String shopId;  // Removed final to allow updates
  final String orderOtp;
  final String paymentMode;
  final double totalAmount;
  int currentStep;
  String status;

  OrderTimeline({
    required this.orderId,
    required this.items,
    required this.pickupTime,
    required this.orderPlacedTime,
    required this.shopId,
    required this.orderOtp,
    required this.paymentMode,
    required this.totalAmount,
    this.currentStep = 1,
    this.status = 'pending',
  });
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final List<OrderTimeline> _orders = [];
  final Set<String> _animatedOrders = {};
  final OrderService _orderService = OrderService();
  String? _currentUserId;
  String? _currentShopId;

  @override
  void initState() {
    super.initState();
    _initializeUserAndOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      print("📦 Received navigation arguments: $args");
      try {
        final itemsList = args['items'] as List<dynamic>;
        final orderId = args['order_id']?.toString() ?? '';
        final otp = args['otp']?.toString() ?? '';
        final paymentMode = args['payment_mode']?.toString() ?? '';
        final pickupTime = args['pickup_time']?.toString() ?? '';
        final totalAmount = double.tryParse(args['total_amount']?.toString() ?? '0.0') ?? 0.0;

        if (!_orders.any((o) => o.orderId == orderId)) {
          setState(() {
            _orders.add(OrderTimeline(
              orderId: orderId,
              items: itemsList.map((item) {
                return CartItem(
                  cartId: '',
                  food: Food(
                    id: int.tryParse(item['id']?.toString() ?? '0') ?? 0,
                    name: item['name']?.toString() ?? '',
                    description: item['description']?.toString() ?? '',
                    price: double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0,
                    image: getFullImageUrl(item['image_path']?.toString()),
                    category: FoodCategory.lunch,
                    isVeg: item['isVeg'] as bool? ?? true,
                    availableQuantity: 0,
                  ),
                  quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
                  paymentMode: paymentMode,
                  otp: otp,
                );
              }).toList(),
              pickupTime: _parsePickupTime(pickupTime),
              orderPlacedTime: DateTime.now(),
              shopId: '',  // Will be set by API data
              orderOtp: otp,
              paymentMode: paymentMode,
              totalAmount: totalAmount,
            ));
          });
          print("✅ Successfully added order from navigation arguments");
        }
      } catch (e, stackTrace) {
        print("❌ Error processing navigation arguments: $e");
        print("📝 Stack trace: $stackTrace");
      }
    }
    _initializeUserAndOrders();
  }

  DateTime _parsePickupTime(String timeStr) {
    try {
      // Handle ISO format
      if (timeStr.contains('T')) {
        return DateTime.parse(timeStr);
      }
      
      // Handle AM/PM format
      final parts = timeStr.split(' ');
      if (parts.length != 2) {
        print("⚠️ Invalid time format: $timeStr");
        return DateTime.now().add(const Duration(minutes: 30));
      }

      final timePart = parts[0];
      final period = parts[1].toUpperCase();
      
      final timeComponents = timePart.split(':');
      if (timeComponents.length != 2) {
        print("⚠️ Invalid time components: $timeStr");
        return DateTime.now().add(const Duration(minutes: 30));
      }

      var hours = int.parse(timeComponents[0]);
      final minutes = int.parse(timeComponents[1]);

      if (period == 'PM' && hours != 12) {
        hours += 12;
      } else if (period == 'AM' && hours == 12) {
        hours = 0;
      }

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hours, minutes);
    } catch (e) {
      print("⚠️ Error parsing time: $e");
      return DateTime.now().add(const Duration(minutes: 30));
    }
  }

  Future<void> _initializeUserAndOrders() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        print("⚠️ No user ID found");
        return;
      }

      final shopService = ShopService();
      final shopId = await shopService.getStoredShopId();
      if (shopId == null) {
        print("⚠️ No shop ID found");
        return;
      }

      final orders = await _orderService.fetchOrders(shopId);
      if (mounted) {
        setState(() {
          // Update existing orders with API data
          for (var orderData in orders) {
            try {
              print("📦 Processing order data: $orderData");
              
              final orderId = orderData['order_id'].toString();
              final existingOrder = _orders.firstWhereOrNull((o) => o.orderId == orderId);
              
              if (existingOrder != null) {
                // Update existing order with API data
                existingOrder.status = orderData['status']?.toString() ?? 'pending';
                existingOrder.shopId = shopId;
                print("✅ Updated existing order with API data");
              } else {
                // Create new order from API data
                final itemsList = (orderData['items'] ?? []) as List<dynamic>;
                final totalAmountStr = orderData['total_amount']?.toString() ?? '0.00';
                final totalAmount = double.tryParse(totalAmountStr) ?? 0.0;
                
                _orders.add(OrderTimeline(
                  orderId: orderId,
                  items: itemsList.map((item) {
                    return CartItem(
                      cartId: '',
                      food: Food(
                        id: int.tryParse(item['food_id']?.toString() ?? '0') ?? 0,
                        name: item['name']?.toString() ?? '',
                        description: item['description']?.toString() ?? '',
                        price: double.tryParse(item['price']?.toString() ?? '0.00') ?? 0.0,
                        image: getFullImageUrl(item['image_path']?.toString()),
                        category: FoodCategory.lunch,
                        isVeg: item['isVeg'] as bool? ?? true,
                        availableQuantity: 0,
                      ),
                      quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
                      paymentMode: orderData['payment_method']?.toString() ?? '',
                      otp: orderData['otp']?.toString() ?? '',
                    );
                  }).toList(),
                  pickupTime: _parsePickupTime(orderData['pickup_time']?.toString() ?? ''),
                  orderPlacedTime: DateTime.now(),
                  shopId: shopId,
                  orderOtp: orderData['otp']?.toString() ?? '',
                  paymentMode: orderData['payment_method']?.toString() ?? '',
                  totalAmount: totalAmount,
                ));
                print("✅ Added new order from API data");
              }
            } catch (e, stackTrace) {
              print("❌ Error processing order: $e");
              print("📝 Stack trace: $stackTrace");
              print("📦 Failed order data: $orderData");
            }
          }
        });
      }
    } catch (e) {
      print("❌ Error initializing timeline: $e");
    }
  }

  @override
  void dispose() {
    _orderService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Timeline'),
        backgroundColor: Colors.green,
      ),
      body: _orders.isEmpty
          ? const Center(
              child: Text(
                'No current orders',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildOrderCard(OrderTimeline order) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOtpDisplay(order),
            const SizedBox(height: 20),
            _buildOrderedFoodList(order),
            const SizedBox(height: 20),
            _buildTimelineSteps(order.currentStep, order.orderId),
            if (order.currentStep == 4) _buildPickupTimer(order),
            const SizedBox(height: 20),
            if (order.currentStep != 5)
              Center(
                child: CustomButton(
                  label: "Cancel Order",
                  gradientColors: [Colors.redAccent, Colors.red],
                  onPressed: () => _showCancelReasonSheet(context, order),
                  hasBorder: true,
                  borderColor: Colors.white,
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpDisplay(OrderTimeline order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1)],
      ),
      child: Center(
        child: Text(
          "Order OTP: ${order.orderOtp}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTimelineSteps(int currentStep, String orderNumber) {
    return Column(
      children: [
        Timeline(
          isFirst: true,
          isLast: false,
          isPast: currentStep >= 1,
          eventCard: EventCard(isPast: currentStep >= 1, child: const Text('Order Placed')),
          orderNumber: orderNumber,
          animatedOrders: _animatedOrders,
        ),
        Timeline(
          isFirst: false,
          isLast: false,
          isPast: currentStep >= 2,
          eventCard: EventCard(isPast: currentStep >= 2, child: const Text('Order Confirmed')),
          orderNumber: orderNumber,
          animatedOrders: _animatedOrders,
        ),
        Timeline(
          isFirst: false,
          isLast: false,
          isPast: currentStep >= 3,
          eventCard: EventCard(isPast: currentStep >= 3, child: const Text('Order Getting Ready')),
          orderNumber: orderNumber,
          animatedOrders: _animatedOrders,
        ),
        Timeline(
          isFirst: false,
          isLast: true,
          isPast: currentStep >= 4,
          eventCard: EventCard(isPast: currentStep >= 4, child: const Text('Ready for Pickup')),
          orderNumber: orderNumber,
          animatedOrders: _animatedOrders,
        ),
      ],
    );
  }

  Widget _buildPickupTimer(OrderTimeline order) {
    return Center(
      child: Text(
        "Order Delivered!",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
      ),
    );
  }

  Widget _buildOrderedFoodList(OrderTimeline order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ordered Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...order.items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  child: Image.network(
                    getFullImageUrl(item.food.image),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image for ${item.food.name}: $error');
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, size: 30, color: Colors.grey),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.food.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quantity: ${item.quantity}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${(item.food.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _showCancelReasonSheet(BuildContext context, OrderTimeline order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return CancelReasonSheet(
          orderId: order.orderId, 
          onConfirm: (reason) {
            Navigator.pop(context);
            _cancelOrder(order, reason);
          },
        );
      },
    );
  }

  void _cancelOrder(OrderTimeline order, String reason) {
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    int orderNum = int.tryParse(order.orderId) ?? -1;
    if (orderNum == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order not found!")));
      return;
    }

    foodMenu.cancelOrder(orderNum);

    setState(() {
      order.currentStep = 1;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order cancelled: $reason")));
    });
  }
}

class CancelReasonSheet extends StatefulWidget {
  final Function(String) onConfirm;
  final String orderId;

  const CancelReasonSheet({
    required this.onConfirm,
    required this.orderId,
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

          ElevatedButton(
            onPressed: _selectedReason == null
              ? null
              : () {
                  final reason = _selectedReason!;
                  Navigator.pop(context);
                  widget.onConfirm(reason);
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

