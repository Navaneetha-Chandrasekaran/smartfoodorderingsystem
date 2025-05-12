  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../../../food_menu.dart';
  import '../../../models/cart_item.dart';
import '../../../services/order_service.dart';
import '../../../services/shop_service.dart';
import '../../../services/canteen_order_service.dart';
import 'dart:async';
import '../../../food.dart';
import '../../../models/buttons.dart';
import '../../../models/event_card.dart';
import '../../../models/timeline.dart';
import '../../../services/auth/login_auth.dart';
import '../../../services/utils.dart';
import '../../../models/common_lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../../animations/timeline_animation.dart';
import '../../../models/constants.dart';
import '../../../models/titles.dart';
import 'dart:ui';
import '../../../services/order_status_service.dart';
import 'package:google_fonts/google_fonts.dart';

  class CanteenDashboard extends StatefulWidget {
    const CanteenDashboard({super.key});

    @override
    State<CanteenDashboard> createState() => _CanteenDashboardState();
  }

class _CanteenDashboardState extends State<CanteenDashboard> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final CanteenOrderService _canteenOrderService = CanteenOrderService();
  final OrderStatusService _orderStatusService = OrderStatusService();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;
  late AnimationController _floatingController;
  String? _currentShopId;

  @override
  void initState() {
    super.initState();
    _initializeFloatingController();
    _initializeShopAndOrders();
  }

  void _initializeFloatingController() {
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _orderService.disconnect();
    super.dispose();
  }

  Future<void> _initializeShopAndOrders() async {
    try {
      final shopService = ShopService();
      final shopId = await shopService.getStoredShopId();
      if (shopId == null) {
        print("⚠️ No shop ID found");
        return;
      }

      setState(() {
        _currentShopId = shopId;
        isLoading = true;
      });

      await _fetchOrders();
    } catch (e) {
      print("❌ Error initializing orders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchOrders() async {
    if (_currentShopId == null) return;

    try {
      print("🔄 Fetching orders for shop ID: $_currentShopId");
      final fetchedOrders = await _canteenOrderService.fetchCanteenOrders(_currentShopId!);
      print("✅ Fetched ${fetchedOrders.length} orders from backend");

      if (mounted) {
        setState(() {
          // Store existing completed orders before updating
          final existingCompletedOrders = orders.where((order) => 
            order['status'].toString().toLowerCase() == 'completed' ||
            order['status'].toString().toLowerCase() == 'cancelled'
          ).toList();
          
          // Process new orders
          orders = fetchedOrders.map((order) {
            // Normalize status: lowercase, replace spaces with underscores
            final rawStatus = order['status']?.toString() ?? '';
            final normalizedStatus = rawStatus.toLowerCase().replaceAll(' ', '_');
            return {
              ...order,
              'status': normalizedStatus,
            };
          }).toList();
          
          // Add back completed orders that weren't in the API response
          final fetchedOrderIds = orders.map((o) => o['order_id'].toString()).toSet();
          for (final completedOrder in existingCompletedOrders) {
            final orderId = completedOrder['order_id'].toString();
            if (!fetchedOrderIds.contains(orderId)) {
              print("📋 Retaining completed order #$orderId in dashboard");
              orders.add(completedOrder);
            }
          }
          
          // Sort orders by status priority
          orders.sort((a, b) {
            final statusA = a['status'].toString().toLowerCase();
            final statusB = b['status'].toString().toLowerCase();
            
            // Define status priority (lower number = higher priority)
            final getPriority = (String status) {
              if (status == 'pending') return 0;
              if (status == 'confirmed' || status == 'preparing') return 1;
              if (status == 'ready_for_pickup') return 2;
              if (status == 'completed') return 3;
              if (status == 'cancelled') return 4;
              return 5; // unknown status
            };
            
            return getPriority(statusA).compareTo(getPriority(statusB));
          });

          print("📊 Dashboard now has ${orders.length} orders total (including completed)");
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching orders: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

    @override
    Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kLogoGreen,
                Color(0xFF4AE578), // Lighter green
                Color(0xFF5DF5A0), // Even lighter green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: kLogoGreen.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: 1,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Center(child: SubTitles(title:'Canteen Dashboard', color: Colors.white,)),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Refresh button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: kLogoGreen,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        _fetchOrders().then((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dashboard refreshed'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          ? Center(child: CommonLottie.loading())
          : orders.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CommonLottie.noOrders(),
                        const SizedBox(height: 24),
                        AnimatedBuilder(
                          animation: _floatingController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 10 * sin(_floatingController.value * pi)),
                              child: child,
                            );
                          },
          child: Column(
            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [kLogoGreen, kLogoGreen.withOpacity(0.7)],
                                ).createShader(bounds),
                                child: const Titles(
                                  title: 'No Orders Yet!',
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [kLogoGreen.withOpacity(0.7), kLogoGreen],
                                ).createShader(bounds),
                                child: const Description(
                                  description: 'New orders will appear here',
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildOrderSummary(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Row(
                        children: const [
                          SubTitles(title: 'Recent Orders'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                              _buildOrdersList(),
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

  Widget _buildOrderSummary() {
    final pendingOrders = orders.where((order) => 
      order['status'].toString().toLowerCase() == 'pending').length;
    final confirmedOrders = orders.where((order) => 
      order['status'].toString().toLowerCase() == 'confirmed').length;
    final completedOrders = orders.where((order) => 
      order['status'].toString().toLowerCase() == 'completed').length;
    final cancelledOrders = orders.where((order) => 
      order['status'].toString().toLowerCase() == 'cancelled').length;
    
    // Total orders for percentage calculation
    final totalOrders = pendingOrders + confirmedOrders + completedOrders + cancelledOrders;
    
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row with title and row of stats
          Row(
            children: [
              // Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: kLogoGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "ORDERS",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: kLogoGreen,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Horizontal status bar
              if (totalOrders > 0)
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        if (pendingOrders > 0)
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5 * (pendingOrders / totalOrders),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        if (confirmedOrders > 0)
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5 * (confirmedOrders / totalOrders),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade500,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        if (completedOrders > 0)
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5 * (completedOrders / totalOrders),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        if (cancelledOrders > 0)
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5 * (cancelledOrders / totalOrders),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Compact status counters row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactStatusCounter('Pending', pendingOrders, Colors.amber.shade600, Icons.pending_actions_rounded),
              _buildCompactStatusCounter('Confirmed', confirmedOrders, Colors.blue.shade500, Icons.check_circle_outline_rounded),
              _buildCompactStatusCounter('Completed', completedOrders, Colors.green.shade500, Icons.done_all_rounded),
              _buildCompactStatusCounter('Cancelled', cancelledOrders, Colors.red.shade400, Icons.cancel_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusCounter(String label, int count, Color color, IconData icon) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label orders: $count'),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: orders.map((order) => _buildOrderCard(order)).toList(),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'].toString().toLowerCase();
    final statusInfo = _getStatusInfo(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: kLogoGreen.withOpacity(0.10), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: kLogoGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Order number and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                    SubTitles(
                      title: 'Order #${order['order_id']}',
                      color: Colors.black87,
                      fontSize: 17,
                    ),
                    if (statusInfo != null)
              Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                          color: statusInfo['color'].withOpacity(0.13),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(statusInfo['icon'], color: statusInfo['color'], size: 16),
                            const SizedBox(width: 4),
                            Description(
                              description: statusInfo['label'],
                              color: statusInfo['color'],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Row 2: OTP and Total price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Description(
                      description: 'OTP: ${order['otp']}',
                      color: Colors.grey[700],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: kLogoGreen.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SubTitles(
                        title: '₹${order['total_amount']}',
                        color: kLogoGreen,
                    fontSize: 16,
                  ),
                ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Row 3: Pickup Time
                if (order['pickup_time'] != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Description(
                        description: 'Pickup at ${_formatPickupTime(order['pickup_time'])}',
                        color: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Divider(color: Colors.grey[200], thickness: 1, height: 0),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubTitles(
                  title: 'Ordered Items',
                  color: Colors.black87,
                  fontSize: 15,
            ),
              const SizedBox(height: 10),
                ...(order['items'] as List<dynamic>).map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: item['image'] != null && item['image'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            getFullImageUrl(item['image']),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 52,
                                height: 52,
                                color: Colors.grey[200],
                                child: const Icon(Icons.fastfood, color: Colors.grey),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                  title: FoodName(
                    foodName: item['name']?.toString() ?? 'Unknown Item',
                  ),
                  subtitle: Description(
                    description: 'Quantity: ${item['quantity']}',
                    color: Colors.grey[600],
                  ),
                  trailing: FoodPrice(
                    foodPrice: '₹${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                  ),
                )).toList(),
                const SizedBox(height: 16),
                _buildStatusButton(order),
              ],
            ),
          ),
        ],
        ),
  );
}

  // Returns a map with label, color, and icon for the four main statuses
  Map<String, dynamic>? _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {'label': 'Confirm Order', 'color': Colors.orange, 'icon': Icons.pending_actions, 'next': 'preparing', 'button': 'Start Preparing'};
      case 'confirmed': // treat as preparing
      case 'preparing':
        return {'label': 'Preparing', 'color': Colors.blue, 'icon': Icons.restaurant, 'next': 'ready_for_pickup', 'button': 'Ready for Pickup'};
      case 'ready_for_pickup':
        return {'label': 'Ready for Pickup', 'color': Colors.purple, 'icon': Icons.takeout_dining, 'next': 'completed', 'button': 'Mark as Completed'};
      case 'completed':
        return {'label': 'Completed', 'color': Colors.green, 'icon': Icons.done_all, 'button': 'Order Completed', 'next': 'completed'};
    default:
        return null;
    }
  }

  Widget _buildStatusButton(Map<String, dynamic> order) {
    final status = order['status'].toString().toLowerCase();
    final statusInfo = _getStatusInfo(status);
    if (statusInfo == null) {
      return const SizedBox.shrink();
    }
    
    // Different styling for completed orders
    final isCompleted = status == 'completed';
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isCompleted ? null : () async {
          final orderId = order['order_id'].toString();
          final newStatus = statusInfo['next'];

          // Convert frontend status format (lowercase_with_underscores) to 
          // backend format (Title Case With Spaces)
          final backendStatus = _convertToBackendStatusFormat(newStatus);
          
          // If moving to completed status, show OTP verification dialog
          if (newStatus == 'completed') {
            _showOtpVerificationDialog(order);
            return;
          }
          
          // Show a loading indicator while updating the status
          setState(() {
            // Add a temporary 'updating' field to the order
            order['updating'] = true;
          });
          
          print("🔄 Updating order #$orderId status from $status to $newStatus (backend: $backendStatus)");
          final success = await _orderStatusService.updateOrderStatus(orderId, backendStatus);
          
          if (success) {
            setState(() {
              // Remove the temporary 'updating' field
              order.remove('updating');
              
              final idx = orders.indexWhere((o) => o['order_id'].toString() == orderId);
              if (idx != -1) {
                orders[idx]['status'] = newStatus;
              }
              
              // If the order is now completed, ensure it stays visible in the dashboard
              if (newStatus == 'completed') {
                print("📋 Order #$orderId marked as completed - keeping it visible");
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order status updated to $newStatus'), backgroundColor: Colors.green),
            );
          } else {
            setState(() {
              // Remove the temporary 'updating' field
              order.remove('updating');
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error updating order status'), backgroundColor: Colors.red),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.grey.shade300 : statusInfo['color'],
          foregroundColor: isCompleted ? Colors.black87 : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: order['updating'] == true 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20, 
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "Updating...",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isCompleted ? Icons.check_circle : Icons.update),
                SizedBox(width: 8),
                Text(
                  statusInfo['button'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // Helper method to convert frontend status format to backend format
  String _convertToBackendStatusFormat(String frontendStatus) {
    // Map of frontend status (lowercase_with_underscores) to backend status (Title Case With Spaces)
    final statusMap = {
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready_for_pickup': 'Ready for Pickup',
      'completed': 'Delivered', // Backend uses "Delivered" instead of "Completed"
    };
    
    return statusMap[frontendStatus] ?? frontendStatus;
  }

  String _formatPickupTime(dynamic pickupTime) {
    if (pickupTime == null) return 'No pickup time';
    
    try {
      // Print the raw pickup time for debugging
      print('Raw pickup time from backend: $pickupTime (${pickupTime.runtimeType})');
      
      // Normalize the pickup time to a string
      final String timeStr = pickupTime.toString();
      
      // Check if the time is in ISO format (with T and possibly Z for UTC)
      if (timeStr.contains('T')) {
        try {
          // Parse the ISO timestamp as UTC
          DateTime utcDateTime = DateTime.parse(timeStr);
          
          // Convert to IST (UTC+5:30) regardless of local timezone
          final istOffset = Duration(hours: 5, minutes: 30);
          final istDateTime = utcDateTime.toUtc().add(istOffset);
          print('Converted to IST: $istDateTime');
          
          // Format the time in 12-hour format with AM/PM
          final hour = istDateTime.hour;
          final minute = istDateTime.minute;
          final period = hour < 12 ? 'AM' : 'PM';
          final hour12 = hour % 12 == 0 ? 12 : hour % 12;
          final formattedTime = '$hour12:${minute.toString().padLeft(2, '0')} $period';
          print('Formatted IST time: $formattedTime');
          return formattedTime;
        } catch (e) {
          print('Error parsing ISO date: $e');
        }
      }
      
      // Handle standard format with space separator (YYYY-MM-DD HH:MM:SS)
      if (timeStr.contains(' ') && timeStr.contains('-') && timeStr.contains(':')) {
        try {
          // Try to parse the datetime string as UTC
          DateTime utcDateTime = DateTime.parse(timeStr.replaceAll(' ', 'T'));
          
          // Convert to IST (UTC+5:30)
          final istOffset = Duration(hours: 5, minutes: 30);
          final istDateTime = utcDateTime.toUtc().add(istOffset);
          
          // Format the time in 12-hour format with AM/PM
          final hour = istDateTime.hour;
          final minute = istDateTime.minute;
          final period = hour < 12 ? 'AM' : 'PM';
          final hour12 = hour % 12 == 0 ? 12 : hour % 12;
          final formattedTime = '$hour12:${minute.toString().padLeft(2, '0')} $period';
          print('Formatted IST time from standard format: $formattedTime');
          return formattedTime;
        } catch (e) {
          print('Error parsing standard date: $e');
        }
      }
      
      // Handle simple time format "HH:MM" or "HH:MM:SS"
      if (timeStr.contains(':') && !timeStr.contains('-') && !timeStr.contains('T')) {
        print('Simple time format detected: $timeStr');
        // For simple time formats, assume they're already in IST
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          final int? hour = int.tryParse(timeParts[0]);
          final String minutes = timeParts[1].replaceAll(RegExp(r'[^\d]'), '');
          
          if (hour != null) {
            final period = hour < 12 ? 'AM' : 'PM';
            final hour12 = hour % 12 == 0 ? 12 : hour % 12;
            final formattedTime = '$hour12:$minutes $period';
            print('Formatted simple time (assumed IST): $formattedTime');
            return formattedTime;
          }
        }
      }
      
      // If we couldn't parse it, show the raw value
      print('Could not parse time format, returning raw: $timeStr');
      return timeStr;
    } catch (e) {
      print('Error formatting pickup time: $e');
      return 'Time available';
    }
  }

  // Complete the order after OTP verification
  Future<void> _completeOrderAfterOtpVerification(Map<String, dynamic> order) async {
    final orderId = order['order_id'].toString();
    final enteredOtp = order['verified_otp'].toString();
    
    // Show a loading indicator while updating the status
    setState(() {
      // Add a temporary 'updating' field to the order
      order['updating'] = true;
    });
    
    // Convert to backend status format
    final backendStatus = _convertToBackendStatusFormat('completed');
    
    print("🔄 Completing order #$orderId after OTP verification with OTP: $enteredOtp");
    final success = await _orderStatusService.verifyOtpAndUpdateStatus(orderId, enteredOtp, backendStatus);
    
    if (success) {
      setState(() {
        // Remove the temporary 'updating' field
        order.remove('updating');
        order.remove('verified_otp');
        
        final idx = orders.indexWhere((o) => o['order_id'].toString() == orderId);
        if (idx != -1) {
          orders[idx]['status'] = 'completed';
        }
        
        print("📋 Order #$orderId marked as completed after OTP verification");
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        // Remove the temporary fields
        order.remove('updating');
        order.remove('verified_otp');
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error completing order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialog to verify OTP before completing an order
  void _showOtpVerificationDialog(Map<String, dynamic> order) {
    final orderId = order['order_id'].toString();
    final orderOtp = order['otp']?.toString() ?? '';
    final TextEditingController otpController = TextEditingController();
    String errorText = '';
    
    // Debug the order data to ensure OTP is available
    print("🔍 Order data for OTP verification:");
    print("   Order ID: $orderId");
    print("   OTP available: ${orderOtp.isNotEmpty ? 'Yes' : 'No'}");
    print("   OTP: ${orderOtp.isNotEmpty ? orderOtp : 'Missing!'}");
    
    // Show the dialog with OTP verification
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Verify OTP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please ask the customer for the OTP to complete this order.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Enter OTP',
                      hintText: 'Ask customer for 4-digit OTP',
                      errorText: errorText.isNotEmpty ? errorText : null,
                      prefixIcon: const Icon(Icons.pin, color: Colors.green),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final enteredOtp = otpController.text.trim();
                    
                    // Verify OTP
                    if (enteredOtp.isEmpty) {
                      setState(() {
                        errorText = 'Please enter OTP';
                      });
                      return;
                    }
                    
                    if (orderOtp.isEmpty) {
                      print("⚠️ Order OTP is empty, fetching details again...");
                      // Could potentially fetch order details again here
                      setState(() {
                        errorText = 'Could not verify OTP. Please try again.';
                      });
                      return;
                    }
                    
                    if (enteredOtp != orderOtp) {
                      setState(() {
                        errorText = 'Invalid OTP';
                      });
                      return;
                    }
                    
                    // Store the verified OTP in the order
                    order['verified_otp'] = enteredOtp;
                    
                    // OTP verified, close dialog
                    Navigator.of(dialogContext).pop();
                    
                    // Now update order status
                    await _completeOrderAfterOtpVerification(order);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Verify & Complete', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
  }
