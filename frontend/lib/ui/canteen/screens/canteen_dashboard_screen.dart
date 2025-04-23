  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../../../food_menu.dart';
  import '../../../models/cart_item.dart';
import '../../../services/order_service.dart';
import '../../../services/shop_service.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

  class CanteenDashboard extends StatefulWidget {
    const CanteenDashboard({super.key});

    @override
    State<CanteenDashboard> createState() => _CanteenDashboardState();
  }

  class _CanteenDashboardState extends State<CanteenDashboard> {
  final OrderService _orderService = OrderService();
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    // Refresh orders every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final shopId = await ShopService().getStoredShopId();
      if (shopId == null) return;

      final orders = await _orderService.fetchOrders(shopId);
      if (mounted) {
        setState(() {
          _orders = orders;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final success = await _orderService.updateOrderStatus(orderId, newStatus);
      if (success) {
        await _fetchOrders(); // Refresh orders after update
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

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
    return _orders.isEmpty
          ? _buildEmptyOrders()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length,
              itemBuilder: (context, index) {
              final order = _orders[index];
              return _buildOrderTile(order);
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
  Widget _buildOrderTile(Map<String, dynamic> order) {
    final orderId = order['order_id'].toString();
    final status = order['status'];
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final totalAmount = order['total_amount'] is String 
        ? double.tryParse(order['total_amount']) ?? 0.0
        : (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final otp = order['otp']?.toString() ?? '----';

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
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Order #$orderId - ${_getStatusText(status)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Items
            Column(
              children: items.map((item) {
                final quantity = item['quantity'] is String 
                    ? int.tryParse(item['quantity']) ?? 0
                    : (item['quantity'] as num?)?.toInt() ?? 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? '', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                    Text(
                      "Qty: $quantity", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // OTP & Cost
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "OTP: $otp", 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red[600])
                ),
                Text(
                  "₹${totalAmount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status Button
            _buildStatusButton(orderId, status),
          ],
        ),
      ),
    );
  }

    /// ✅ **Status Button**
    /// ✅ **Status Button (Updated)**
  Widget _buildStatusButton(String orderId, String currentStatus) {
  String buttonText;
  Color buttonColor;
    String nextStatus;

    switch (currentStatus) {
      case 'Pending':
      buttonText = "Confirm Order";
      buttonColor = Colors.red;
        nextStatus = 'Confirmed';
      break;
      case 'Confirmed':
        buttonText = "Start Preparing";
        buttonColor = Colors.orange;
        nextStatus = 'Preparing';
      break;
      case 'Preparing':
      buttonText = "Mark Ready";
        buttonColor = Colors.blue;
        nextStatus = 'Ready for Pickup';
      break;
      case 'Ready for Pickup':
        buttonText = "Complete Order";
      buttonColor = Colors.green;
        nextStatus = 'Completed';
      break;
    default:
        return const SizedBox(); // Hide button for completed orders
  }

  return ElevatedButton(
      onPressed: () => _updateOrderStatus(orderId, nextStatus),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.red;
      case 'Confirmed':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Ready for Pickup':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Pending';
      case 'Confirmed':
        return 'Confirmed';
      case 'Preparing':
        return 'Preparing';
      case 'Ready for Pickup':
        return 'Ready for Pickup';
      case 'Completed':
        return 'Completed';
      default:
        return status;
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
          paymentMode: Random().nextBool() ? "Cash" : "GPay", cartId: '',
        ),
      ],
      pickupTime: TimeOfDay.now(),
      orderPlacedTime: DateTime.now(), shopId: '',
    );

    // Add the entire Order object
    foodMenu.addOrder(newOrder);  // Pass Order, not CartItem
  }
  }
