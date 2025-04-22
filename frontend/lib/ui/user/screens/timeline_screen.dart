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
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../../animations/timeline_animation.dart';


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
  Map<String, dynamic>? selectedOrder;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;
  final Set<String> animatedOrders = {};
  final OrderService _orderService = OrderService();
  String? _currentUserId;
  String? _currentShopId;
  Map<String, dynamic>? _orderData;

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments from navigation
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && mounted) {
      setState(() {
        _orderData = args;
      });
      _saveOrderData(args);
    } else {
      // If no navigation arguments, try to load from stored data
  final foodMenu = Provider.of<FoodMenu>(context, listen: false);
      if (foodMenu.latestOrderData != null) {
        setState(() {
          _orderData = foodMenu.latestOrderData;
        });
      }
    }
    
    _initializeUserAndOrders();
  }

  Future<void> _loadAllOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load the latest order
      final latestOrderString = prefs.getString('latest_order_data');
      if (latestOrderString != null) {
        final latestOrder = json.decode(latestOrderString);
        
        // Load existing orders
        final existingOrdersString = prefs.getString('all_orders');
        List<Map<String, dynamic>> existingOrders = [];
        if (existingOrdersString != null) {
          final List<dynamic> decoded = json.decode(existingOrdersString);
          existingOrders = decoded.cast<Map<String, dynamic>>();
        }

        // Check if the latest order is already in the list
        bool orderExists = existingOrders.any((order) => 
          order['order_id'] == latestOrder['order_id']);

        if (!orderExists) {
          existingOrders.insert(0, latestOrder); // Add new order at the beginning
          // Save updated orders list
          await prefs.setString('all_orders', json.encode(existingOrders));
        }

        setState(() {
          orders = existingOrders;
          selectedOrder = existingOrders.isNotEmpty ? existingOrders[0] : null;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveOrderData(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('latest_order_data', json.encode(orderData));
      print("💾 Saved order data: $orderData");
    } catch (e) {
      print("❌ Error saving order data: $e");
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

      final fetchedOrders = await _orderService.fetchOrders(shopId);
      if (mounted) {
        setState(() {
          // Create a new list to avoid concurrent modification
          final List<Map<String, dynamic>> updatedOrders = [];
          
          // Process fetched orders
          for (var orderData in fetchedOrders) {
            try {
              print("📦 Processing order data: $orderData");
              
              final orderId = orderData['order_id'].toString();
              final existingOrder = orders.firstWhereOrNull((o) => o['order_id'] == orderId);
              
              if (existingOrder != null) {
                // Update existing order with API data
                existingOrder['status'] = orderData['status']?.toString() ?? 'pending';
                existingOrder['shopId'] = shopId;
                updatedOrders.add(existingOrder);
                print("✅ Updated existing order with API data");
              } else {
                // Add new order
                updatedOrders.add(orderData);
                print("✅ Added new order from API data");
              }
            } catch (e) {
              print("❌ Error processing order: $e");
            }
          }
          
          // Update the orders list
          orders = updatedOrders;
          
          // Set selected order if none is selected
          if (selectedOrder == null && orders.isNotEmpty) {
            selectedOrder = orders[0];
          }
        });
      }
    } catch (e) {
      print("❌ Error initializing orders: $e");
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
        title: const Text('Order Timeline', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders available'))
              : Column(
                  children: [
                    // Order Selection Dropdown
                    _buildOrderSelector(),
                    // Order Details
                    if (selectedOrder != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOtpCard(),
                                const SizedBox(height: 20),
                                _buildOrderedItems(),
                                const SizedBox(height: 20),
                                _buildOrderStatus(),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  Widget _buildOrderSelector() {
    if (orders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedOrder?['order_id']?.toString(),
          hint: const Text(
            'Select an order',
            style: TextStyle(color: Colors.white70),
          ),
          dropdownColor: Colors.purple[50],
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          items: orders
              .where((order) => order['order_id'] != null)
              .map((order) => DropdownMenuItem<String>(
                    value: order['order_id'].toString(),
                    child: Text(
                      'Order #${order['order_id']}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                selectedOrder = orders.firstWhere(
                  (order) => order['order_id'].toString() == newValue,
                );
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade100,
            Colors.purple.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${selectedOrder!['order_id']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'OTP: ${selectedOrder!['otp']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '₹${selectedOrder!['total_amount']}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedItems() {
    final items = List<Map<String, dynamic>>.from(selectedOrder!['items'] ?? []);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.purple.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'Ordered Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      getFullImageUrl(item['image']),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.fastfood, color: Colors.purple.shade200),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Quantity: ${item['quantity']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.purple.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 400,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildStatusStep(
                            'Order Placed',
                            'Your order has been received',
                            Icons.receipt_long,
                            true,
                            isFirst: true,
                          ),
                          _buildStatusStep(
                            'Preparing',
                            'Chef is preparing your food',
                            Icons.restaurant,
                            false,
                          ),
                          _buildStatusStep(
                            'Ready for Pickup',
                            'Your order is ready to collect',
                            Icons.takeout_dining,
                            false,
                          ),
                          _buildStatusStep(
                            'Completed',
                            'Order has been delivered',
                            Icons.check_circle,
                            false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String title, String subtitle, IconData icon, bool isCompleted, {bool isFirst = false, bool isLast = false}) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(
        color: isCompleted ? Colors.green : Colors.grey.shade300,
        thickness: 4,
      ),
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted 
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.grey.shade300, Colors.grey.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isCompleted ? Colors.green : Colors.grey).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? Colors.green : Colors.grey).withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCompleted ? Colors.green.shade800 : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isCompleted ? Colors.green.shade600 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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



