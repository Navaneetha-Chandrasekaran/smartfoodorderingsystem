import 'dart:async';
import 'dart:math';
import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
import '../../../models/common_lottie.dart';
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

class _TimelineScreenState extends State<TimelineScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? selectedOrder;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;
  final Set<String> animatedOrders = {};
  final OrderService _orderService = OrderService();
  String? _currentUserId;
  String? _currentShopId;
  Map<String, dynamic>? _orderData;
  String? _selectedCancelReason;
  late AnimationController _floatingController;
  VoidCallback? _wsCleanup;

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Register WebSocket status update callback
    _orderService.setOnStatusUpdate((data) {
      final orderId = data['order_id'].toString();
      final newStatus = data['new_status'].toString().toLowerCase().replaceAll(' ', '_');
      print("🔄 WebSocket update received: Order #$orderId status changed to $newStatus");
      
      // Always use setState to trigger UI update
      if (mounted) {
        setState(() {
          // Update all orders with this ID
          for (var order in orders) {
            if (order['order_id'].toString() == orderId) {
              print("📝 Updating order #$orderId from ${order['status']} to $newStatus");
              order['status'] = newStatus;
            }
          }
          
          // If the selected order is the one updated, update its status too
          if (selectedOrder != null && selectedOrder!['order_id'].toString() == orderId) {
            selectedOrder = {
              ...selectedOrder!,
              'status': newStatus,
            };
            
            // Force refresh by adding to animatedOrders set
            animatedOrders.add(orderId);
            
            // Force the timeline to rebuild
            print("🔄 Forcing timeline rebuild for order #$orderId");
          }
          
          // Save changes to SharedPreferences
          _saveOrderDataToPrefs();
        });
      }
    });

    // Initialize WebSocket connection (userId/shopId)
    AuthService.getCurrentUserId().then((userId) async {
      final shopId = await ShopService().getStoredShopId();
      if (userId != null && shopId != null) {
        _orderService.initializeWebSocket(userId.toString(), shopId);
      }
    });
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

      print("🔄 Fetching orders from backend...");
      final fetchedOrders = await _orderService.fetchOrders(shopId);
      print("✅ Fetched ${fetchedOrders.length} orders from backend");
      
      if (mounted) {
        setState(() {
          // Create a map to group items by order ID
          final Map<String, List<Map<String, dynamic>>> orderItemsMap = {};
          
          // First pass: Group items by order ID
          for (var orderData in fetchedOrders) {
            final orderId = orderData['order_id'].toString();
            if (!orderItemsMap.containsKey(orderId)) {
              orderItemsMap[orderId] = [];
            }
            
            // Add item to the order's items list with all food details
            orderItemsMap[orderId]!.add({
              'id': orderData['food_id']?.toString() ?? '',
              'name': orderData['name']?.toString() ?? '',
              'quantity': orderData['quantity'] ?? 1,
              'price': double.tryParse(orderData['price']?.toString() ?? '0') ?? 0.0,
              'description': orderData['description']?.toString() ?? '',
              'image': orderData['image']?.toString() ?? '',
              'isVeg': orderData['isVeg'] ?? false,
            });
          }
          
          // Second pass: Create processed orders with grouped items
          final List<Map<String, dynamic>> updatedOrders = [];
          final Set<String> processedOrderIds = {}; // Track processed order IDs
          
          for (var orderData in fetchedOrders) {
            final orderId = orderData['order_id'].toString();
            
            // Skip if we've already processed this order
            if (processedOrderIds.contains(orderId)) {
              continue;
            }
            processedOrderIds.add(orderId);
            
            // Ensure status is properly formatted
            String status = orderData['status']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'pending';
            print("📊 Processing order #$orderId with status: $status");
            
            final processedOrder = {
              'order_id': orderId,
              'user_id': orderData['user_id'],
              'pickup_time': orderData['pickup_time'],
              'payment_method': orderData['payment_method'],
              'total_amount': double.tryParse(orderData['total_amount']?.toString() ?? '0') ?? 0.0,
              'otp': orderData['otp'],
              'status': status,
              'items': orderItemsMap[orderId] ?? [],
            };
            
            updatedOrders.add(processedOrder);
          }
          
          // Keep existing completed/cancelled orders that might not be returned by the API
          if (orders.isNotEmpty) {
            print("🔍 Checking for completed orders to retain...");
            for (var existingOrder in orders) {
              final existingOrderId = existingOrder['order_id'].toString();
              final existingStatus = existingOrder['status'].toString().toLowerCase();
              
              // Keep completed orders that might not be returned by the API
              if ((existingStatus == 'completed' || existingStatus == 'cancelled') && 
                  !processedOrderIds.contains(existingOrderId)) {
                print("📋 Retaining completed order #$existingOrderId with status: $existingStatus");
                updatedOrders.add(existingOrder);
              }
            }
          }
          
          // Sort orders: pending first, then preparing, then ready_for_pickup, then completed
          updatedOrders.sort((a, b) {
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

          // Update the orders list
          orders = updatedOrders;
          print("📱 Timeline now has ${orders.length} orders total (including completed)");
          
          // Set selected order if none is selected
          if (selectedOrder == null && orders.isNotEmpty) {
            selectedOrder = orders[0];
          }
          // If the selected order exists in the updated orders, update it
          else if (selectedOrder != null) {
            final currentOrderId = selectedOrder!['order_id'].toString();
            // Try to find the selected order in the updated orders list
            final matchingOrderIndex = orders.indexWhere(
              (order) => order['order_id'].toString() == currentOrderId
            );
            
            if (matchingOrderIndex != -1) {
              selectedOrder = orders[matchingOrderIndex];
            }
          }
        });
      }
    } catch (e) {
      print("❌ Error initializing orders: $e");
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _orderService.setOnStatusUpdate((_) {}); // Remove callback by setting a no-op function
    _orderService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Timeline', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/menu');
          }, 
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
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
                                  colors: [
                                    const Color(0xFF00FF00),
                                    const Color(0xFF008000),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'No Orders Yet!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    const Color(0xFF00CC00),
                                    const Color(0xFF00FF00),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Your order history will appear here',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.1),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/menu');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8C00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restaurant_menu, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Browse Menu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
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
                    // Cancel Button
                    _buildCancelButton(),
                  ],
                ),
      ),
    );
  }

  Widget _buildOrderSelector() {
    if (orders.isEmpty) return const SizedBox.shrink();

    // Ensure we have a valid selected order
    final currentOrderId = selectedOrder?['order_id']?.toString();
    if (currentOrderId != null && !orders.any((order) => order['order_id'].toString() == currentOrderId)) {
      setState(() {
        selectedOrder = orders.isNotEmpty ? orders[0] : null;
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF00).withOpacity(0.1),
            const Color(0xFF00FF00).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF00).withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedOrder?['order_id']?.toString(),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, 
                      color: const Color(0xFF00CC00)),
                    const SizedBox(width: 12),
                    Text(
                      'Select an order',
                      style: TextStyle(
                        color: const Color(0xFF00CC00),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF008000),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: const Color(0xFF00CC00),
                  size: 28,
                ),
              ),
              items: orders.map((order) {
                final orderId = order['order_id'].toString();
                return DropdownMenuItem<String>(
                  value: orderId,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: const Color(0xFF00CC00),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Order #$orderId',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF008000),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF8C00),
                                const Color(0xFFFF8C00).withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FoodPrice(
                            foodPrice: '₹${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
            Colors.teal.shade100,
            Colors.green.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
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
                  color: Colors.teal.withOpacity(0.2),
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
                color: Colors.teal.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedItems() {
    if (selectedOrder == null) return const SizedBox.shrink();

    final items = selectedOrder!['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ordered Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
        itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item['image'] != null && item['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          getFullImageUrl(item['image']),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("❌ Error loading image: $error");
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.fastfood, color: Colors.grey),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                title: Text(
                  item['name']?.toString() ?? 'Unknown Item',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Quantity: ${item['quantity']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Text(
                  '₹${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
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
    final status = selectedOrder?['status']?.toString().toLowerCase() ?? 'pending';
    print("🔍 Building order status for order with status: $status");
    
    // Calculate how many steps are completed based on status
    int currentStep = 0;
    if (status == 'pending') currentStep = 1;
    else if (status == 'confirmed' || status == 'preparing') currentStep = 2;
    else if (status == 'ready_for_pickup') currentStep = 3;
    else if (status == 'completed') currentStep = 4;
    else if (status == 'cancelled') currentStep = 0;

    return Container(
      key: ValueKey('order-status-$currentStep-${selectedOrder?['order_id']}'),
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
                  Colors.teal.shade50,
                  Colors.green.shade100,
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
                color: Colors.teal,
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
                            currentStep >= 1,
                            isFirst: true,
                          ),
                          _buildStatusStep(
                            'Preparing',
                            'Chef is preparing your food',
                            Icons.restaurant,
                            currentStep >= 2,
                          ),
                          _buildStatusStep(
                            'Ready for Pickup',
                            'Your order is ready to collect',
                            Icons.takeout_dining,
                            currentStep >= 3,
                          ),
                          _buildStatusStep(
                            'Completed',
                            'Order has been delivered',
                            Icons.check_circle,
                            currentStep >= 4,
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
    // Add a ValueKey to force complete rebuild when animation state changes
    final animationKey = ValueKey('${title.toLowerCase().replaceAll(' ', '_')}-$isCompleted');

    return TimelineTile(
      key: animationKey,
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(
        color: isCompleted ? const Color(0xFF00CC00) : Colors.grey.shade300,
        thickness: 4,
      ),
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: AnimatedScale(
          scale: isCompleted ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted 
                  ? [const Color(0xFF00FF00), const Color(0xFF00CC00)]
                  : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isCompleted ? const Color(0xFF00FF00) : Colors.grey).withOpacity(0.3),
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
      ),
      endChild: Container(
        // Add visual animation when status changes
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted 
              ? const Color(0xFF00FF00).withOpacity(isCompleted ? 0.2 : 0.1) 
              : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isCompleted ? const Color(0xFF00FF00) : Colors.grey).withOpacity(0.1),
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
                  color: isCompleted ? const Color(0xFF008000) : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? const Color(0xFF00CC00) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    if (selectedOrder == null) {
      print('❌ Cancel button hidden - No order selected');
      return const SizedBox.shrink();
    }

    final status = selectedOrder!['status']?.toString().toLowerCase() ?? '';
    print('📊 Order details:');
    print('  - Order ID: ${selectedOrder!['order_id']}');
    print('  - Status: $status');
    print('  - Raw status: ${selectedOrder!['status']}');

    // Show cancel button for pending or confirmed orders
    if (status != 'pending' && status != 'confirmed') {
      print('❌ Cancel button hidden - Invalid status: $status');
      return const SizedBox.shrink();
    }

    print('✅ Showing cancel button for order ${selectedOrder!['order_id']} with status: $status');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () => _showCancelDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red[300]!),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_outlined),
            const SizedBox(width: 8),
            const Text(
              'Cancel Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    final reasons = [
      'Class got extended',
      'Emergency meeting',
      'Forgot about another commitment',
      'Food allergy concern',
      'Price too high',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select a reason for cancellation:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedCancelReason,
              onChanged: (value) {
                setState(() {
                  _selectedCancelReason = value;
                });
                Navigator.pop(context);
                if (value == 'Other') {
                  _showOtherReasonDialog();
                } else {
                  _confirmCancellation(value!);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showOtherReasonDialog() {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Other Reason'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Please specify your reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                _confirmCancellation(reasonController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _confirmCancellation(String reason) {
    final BuildContext dialogContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 8),
            Text(
              'Reason: $reason',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Order'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final orderId = selectedOrder!['order_id'].toString();
              
              try {
                final success = await _orderService.cancelOrder(orderId, reason);
                if (mounted) {
                  setState(() {
                    // Remove the cancelled order from the list
                    orders.removeWhere((order) => order['order_id'].toString() == orderId);
                    // Clear selected order if it was the cancelled one
                    if (selectedOrder!['order_id'].toString() == orderId) {
                      selectedOrder = orders.isNotEmpty ? orders[0] : null;
                    }
                  });
                  
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Order cancelled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error cancelling order: $e');
                if (mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Error cancelling order'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }

  // New method to save orders to SharedPreferences
  Future<void> _saveOrderDataToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('all_orders', json.encode(orders));
      print("💾 Saved all orders data to SharedPreferences");
    } catch (e) {
      print("❌ Error saving order data: $e");
    }
  }

  Widget _buildOrderTimeline(Map<String, dynamic> order) {
    final status = order['status'].toString().toLowerCase();
    print("🔍 Building timeline for order #${order['order_id']} with status: $status");
    
    // Calculate how many steps are completed based on status
    int currentStep = 0;
    if (status == 'pending') currentStep = 1;
    else if (status == 'confirmed' || status == 'preparing') currentStep = 2;
    else if (status == 'ready_for_pickup') currentStep = 3;
    else if (status == 'completed') currentStep = 4;
    else if (status == 'cancelled') currentStep = 0;

    final List<Map<String, dynamic>> timelineSteps = [
      {
        'title': 'Order Placed',
        'subtitle': 'Your order has been received',
        'time': 'Just now',
        'isPast': currentStep >= 1,
      },
      {
        'title': 'Order Confirmed',
        'subtitle': 'Your order is being prepared',
        'time': '5 mins',
        'isPast': currentStep >= 2,
      },
      {
        'title': 'Ready for Pickup',
        'subtitle': 'Your food is ready to collect',
        'time': '15 mins',
        'isPast': currentStep >= 3,
      },
      {
        'title': 'Order Completed',
        'subtitle': 'Enjoy your meal!',
        'time': '20 mins',
        'isPast': currentStep >= 4,
      },
    ];

    if (status == 'cancelled') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 80),
            SizedBox(height: 20),
            Text('Order Cancelled', style: TextStyle(color: Colors.red, fontSize: 24)),
            SizedBox(height: 10),
            Text('This order has been cancelled.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Build the timeline with animation
    return Column(
      children: List.generate(
        timelineSteps.length,
        (index) => Timeline(
          isFirst: index == 0,
          isLast: index == timelineSteps.length - 1,
          isPast: timelineSteps[index]['isPast'] as bool,
          eventCard: EventCard(
            title: timelineSteps[index]['title'] as String,
            subtitle: timelineSteps[index]['subtitle'] as String,
            time: timelineSteps[index]['time'] as String,
            isPast: timelineSteps[index]['isPast'] as bool,
          ),
          orderNumber: order['order_id'].toString(),
          animatedOrders: animatedOrders,
        ),
      ),
    );
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




