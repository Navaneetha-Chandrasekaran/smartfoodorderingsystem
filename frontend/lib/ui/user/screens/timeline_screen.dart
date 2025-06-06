import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeline_tile/timeline_tile.dart';

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
import '../../../models/titles.dart';
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
      // Capitalize first letter of status
      final rawStatus = data['new_status'].toString();
      final newStatus = rawStatus.substring(0, 1).toUpperCase() + rawStatus.substring(1).toLowerCase();
      print("🔄 WebSocket update received: Order #$orderId status changed to $newStatus");
      
      if (mounted) {
        setState(() {
          for (var order in orders) {
            if (order['order_id'].toString() == orderId) {
              print("📝 Updating order #$orderId from ${order['status']} to $newStatus");
              order['status'] = newStatus;
            }
          }
          
          if (selectedOrder != null && selectedOrder!['order_id'].toString() == orderId) {
            selectedOrder = {
              ...selectedOrder!,
              'status': newStatus,
            };
            animatedOrders.add(orderId);
            print("🔄 Forcing timeline rebuild for order #$orderId");
          }
          _saveOrderDataToPrefs();
        });
      }
    });

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
    
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && mounted) {
          setState(() {
        _orderData = args;
      });
      _saveOrderData(args);
      } else {
        final foodMenu = Provider.of<FoodMenu>(context, listen: false);
        if (foodMenu.latestOrderData != null) {
            setState(() {
          _orderData = foodMenu.latestOrderData;
        });
      }
    }
    
                _initializeUserAndOrders();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _orderService.setOnStatusUpdate((_) {});
    _orderService.disconnect();
    super.dispose();
  }

  Future<void> _loadAllOrders() async {
    try {
      print('🔄 Loading all orders...');
      final prefs = await SharedPreferences.getInstance();
      
        final latestOrderString = prefs.getString('latest_order_data');
        if (latestOrderString != null) {
        print('📦 Found latest order data in preferences');
        final latestOrder = json.decode(latestOrderString);
        print('  - Order ID: ${latestOrder['order_id']}');
        print('  - Status: ${latestOrder['status']}');
        
        final existingOrdersString = prefs.getString('all_orders');
        List<Map<String, dynamic>> existingOrders = [];
        if (existingOrdersString != null) {
          print('📦 Found existing orders in preferences');
          final List<dynamic> decoded = json.decode(existingOrdersString);
          existingOrders = decoded.cast<Map<String, dynamic>>();
          print('  - Total existing orders: ${existingOrders.length}');
          for (var order in existingOrders) {
            print('  - Order #${order['order_id']} status: ${order['status']}');
          }
        }

        bool orderExists = existingOrders.any((order) => 
          order['order_id'] == latestOrder['order_id']);

        if (!orderExists) {
          print('📝 Adding latest order to existing orders');
          existingOrders.insert(0, latestOrder);
          await prefs.setString('all_orders', json.encode(existingOrders));
        }

          setState(() {
            orders = existingOrders;
          selectedOrder = existingOrders.isNotEmpty ? existingOrders[0] : null;
            isLoading = false;
          
          print('📊 Updated state:');
          print('  - Total orders: ${orders.length}');
          print('  - Selected order: ${selectedOrder != null ? '#${selectedOrder!['order_id']}' : 'null'}');
          if (selectedOrder != null) {
            print('  - Selected order status: ${selectedOrder!['status']}');
          }
          });
      } else {
        print('⚠️ No latest order data found in preferences');
          setState(() {
            isLoading = false;
          });
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
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
          // Process orders
          final List<Map<String, dynamic>> updatedOrders = [];
          final Set<String> processedOrderIds = {};
          
          for (var order in fetchedOrders) {
            final orderId = order['order_id'].toString();
            
            if (processedOrderIds.contains(orderId)) {
              continue;
            }
            processedOrderIds.add(orderId);
            
            String status = order['status']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'pending';
            print("📊 Processing order #$orderId with status: $status");
            
            // Skip cancelled orders
            if (status == 'cancelled' || order['is_cancelled'] == true || 
                (order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty)) {
              print("⏭️ Skipping cancelled order #$orderId");
              continue;
            }
            
            // Ensure items are properly formatted
            final List<Map<String, dynamic>> processedItems = (order['items'] as List<dynamic>? ?? []).map((item) {
              return {
                'id': item['id']?.toString() ?? '',
                'food_id': item['id']?.toString() ?? '',
                'name': item['name']?.toString() ?? 'Unknown Item',
                'quantity': item['quantity'] is num ? item['quantity'] : 1,
                'price': item['price'] is num ? item['price'] : 
                        (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
                'description': item['description']?.toString() ?? '',
                'image': item['image']?.toString() ?? '',
                'isVeg': item['type'] == 'veg' || item['isVeg'] == true,
                'category': item['category']?.toString() ?? '',
              };
            }).toList();

            final processedOrder = {
              'order_id': orderId,
              'user_id': order['user_id'],
              'pickup_time': order['pickup_time'],
              'payment_method': order['payment_method'],
              'total_amount': order['total_amount'] is num ? order['total_amount'] : 
                            (order['total_amount'] is String ? 
                             double.tryParse(order['total_amount']) ?? 0.0 : 0.0),
              'otp': order['otp'],
              'status': status,
              'items': processedItems,
            };
            
            // Calculate total if not present
            if (processedOrder['total_amount'] == 0.0 && processedItems.isNotEmpty) {
              double total = 0.0;
              for (var item in processedItems) {
                total += (item['price'] as double) * (item['quantity'] as int);
              }
              processedOrder['total_amount'] = total;
            }
            
            updatedOrders.add(processedOrder);
            print("📦 Processed order #$orderId with ${processedItems.length} items");
          }
          
          // Retain completed orders that weren't in the API response
          if (orders.isNotEmpty) {
            print("🔍 Checking for completed orders to retain...");
            for (var existingOrder in orders) {
              final existingOrderId = existingOrder['order_id'].toString();
              final existingStatus = existingOrder['status'].toString().toLowerCase();
              final isCancelled = existingOrder['is_cancelled'] == true || 
                                existingStatus == 'cancelled' ||
                                (existingOrder['cancel_reason'] != null && 
                                 existingOrder['cancel_reason'].toString().isNotEmpty);
              
              // Only retain completed (not cancelled) orders
              if (existingStatus == 'completed' && !isCancelled && 
                  !processedOrderIds.contains(existingOrderId)) {
                print("📋 Retaining completed order #$existingOrderId");
                updatedOrders.add(existingOrder);
              }
            }
          }
          
          // Sort orders by status priority
          updatedOrders.sort((a, b) {
            final getPriority = (String status) {
              final normalizedStatus = status.toLowerCase();
              if (normalizedStatus == 'pending') return 0;
              if (normalizedStatus == 'confirmed' || normalizedStatus == 'preparing') return 1;
              if (normalizedStatus == 'ready for pickup') return 2;
              if (normalizedStatus == 'delivered') return 3;
              if (normalizedStatus == 'cancelled') return 4;
              return 5;
            };
            
            final statusA = a['status'].toString().toLowerCase();
            final statusB = b['status'].toString().toLowerCase();
            return getPriority(statusA).compareTo(getPriority(statusB));
          });

          orders = updatedOrders;
          print("📱 Timeline now has ${orders.length} orders total");
          
          if (selectedOrder == null && orders.isNotEmpty) {
            selectedOrder = orders[0];
          }
          else if (selectedOrder != null) {
            final currentOrderId = selectedOrder!['order_id'].toString();
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

  Future<void> _saveOrderDataToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('all_orders', json.encode(orders));
      print("💾 Saved all orders data to SharedPreferences");
    } catch (e) {
      print("❌ Error saving order data: $e");
    }
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
              ? _buildEmptyState(screenWidth)
              : Column(
                  children: [
                    _buildOrderSelector(),
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
                                const SizedBox(height: 20),
                                _buildCancelButton(),
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

  Widget _buildEmptyState(double screenWidth) {
    return Center(
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
                        kLogoGreen,
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
                        kLogoGreen,
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
            _buildBrowseMenuButton(),
          ],
        ),
                ),
              );
            }

  Widget _buildBrowseMenuButton() {
    return TweenAnimationBuilder<double>(
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
    );
  }

  Widget _buildOrderSelector() {
    if (orders.isEmpty) return const SizedBox.shrink();
    
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
            kLogoGreen.withOpacity(0.1),
            kLogoGreen.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kLogoGreen.withOpacity(0.1),
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
                    Icon(Icons.receipt_long, color: kLogoGreen),
                    const SizedBox(width: 12),
                    Text(
                      'Select an order',
                      style: TextStyle(
                        color: kLogoGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              dropdownColor: Colors.white,
              style: TextStyle(
                color: const Color(0xFF008000),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: kLogoGreen,
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
                            color: kLogoGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: kLogoGreen,
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
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: kLogoGreen),
                const SizedBox(width: 8),
                Text(
                  'Ordered Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey[200],
              height: 1,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final itemPrice = (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
              
              // Debug print for image URL construction
              print('🖼️ Processing image for item: ${item['name']}');
              print('  - Raw image path: ${item['image']}');
              final imageUrl = getFullImageUrl(item['image']);
              print('  - Constructed URL: $imageUrl');
              
              return ListTile(
                leading: item['image'] != null && item['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("❌ Error loading image: $error");
                            print("  - URL attempted: $imageUrl");
                            print("  - Stack trace: $stackTrace");
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fastfood,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
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
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name']?.toString() ?? 'Unknown Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['isVeg'] == true ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 12,
                        color: item['isVeg'] == true ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Qty: ${item['quantity']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item['category'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['category'],
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${itemPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kLogoGreen,
                      ),
                    ),
                    Text(
                      '₹${item['price']?.toStringAsFixed(2) ?? '0.00'}/item',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kLogoGreen.withOpacity(0.8),
                        kLogoGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${selectedOrder!['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderStatus() {
    final status = selectedOrder?['status']?.toString().toLowerCase() ?? 'pending';
    print("🔍 Building order status for order with status: $status");
    
    int currentStep = 0;
    if (status == 'pending') currentStep = 1;
    else if (status == 'confirmed' || status == 'preparing') currentStep = 2;
    else if (status == 'ready for pickup') currentStep = 3;
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
    final animationKey = ValueKey('${title.toLowerCase().replaceAll(' ', '_')}-$isCompleted');

    return TimelineTile(
      key: animationKey,
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(
        color: isCompleted ? kLogoGreen : Colors.grey.shade300,
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
                  ? [kLogoGreen, const Color(0xFF00CC00)]
                  : [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: (isCompleted ? kLogoGreen : Colors.grey).withOpacity(0.3),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted 
              ? kLogoGreen.withOpacity(isCompleted ? 0.2 : 0.1) 
              : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isCompleted ? kLogoGreen : Colors.grey).withOpacity(0.1),
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
                  color: isCompleted ? kLogoGreen : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ),
        ),
    );
  }
  
  Widget _buildCancelButton() {
    print('🔍 Checking cancel button visibility conditions:');
    print('  - Orders count: ${orders.length}');
    print('  - Selected order: ${selectedOrder != null ? 'exists' : 'null'}');
    
    if (selectedOrder == null) {
      print('❌ Cancel button hidden - No order selected');
      return const SizedBox.shrink();
    }
    
    // Normalize the status: convert to lowercase and replace spaces with underscores
    final status = selectedOrder!['status']?.toString().toLowerCase().replaceAll(' ', '_') ?? '';
    print('📊 Order details:');
    print('  - Order ID: ${selectedOrder!['order_id']}');
    print('  - Status: $status');
    print('  - Raw status: ${selectedOrder!['status']}');
    print('  - Is cancelled flag: ${selectedOrder!['is_cancelled']}');
    print('  - Cancel reason: ${selectedOrder!['cancel_reason']}');

    // Check if order is already cancelled
    final isCancelled = selectedOrder!['is_cancelled'] == true || 
                       selectedOrder!['cancel_reason'] != null;

    // Only show cancel button for pending or confirmed orders that aren't already cancelled
    if (!['pending', 'confirmed'].contains(status)) {
      print('❌ Cancel button hidden - Invalid status: $status (must be pending or confirmed)');
      return const SizedBox.shrink();
    }
    
    if (isCancelled) {
      print('❌ Cancel button hidden - Order is already cancelled');
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
    // Store BuildContext locally
    final BuildContext dialogContext = context;
    
    showDialog(
      context: dialogContext,
      builder: (BuildContext context) => AlertDialog(
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
              // Close the confirmation dialog
              Navigator.pop(context);
              
              if (!mounted) return;

              // Store current order data before cancellation
              final orderToCancel = Map<String, dynamic>.from(selectedOrder!);
              final orderId = orderToCancel['order_id'].toString();
              
              try {
                // Optimistically update UI
                setState(() {
                  orders.removeWhere((order) => order['order_id'].toString() == orderId);
                  if (orders.isNotEmpty) {
                    selectedOrder = orders[0];
                  } else {
                    selectedOrder = null;
                  }
                });

                final success = await _orderService.cancelOrder(orderId, reason);
                
                if (success) {
                  if (!mounted) return;

                  // Move to completed orders in SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  final completedOrdersString = prefs.getString('completed_orders') ?? '[]';
                  List<dynamic> completedOrders = json.decode(completedOrdersString);
                  
                  orderToCancel['status'] = 'cancelled';
                  orderToCancel['is_cancelled'] = true;
                  orderToCancel['cancel_reason'] = reason;
                  orderToCancel['cancelled_at'] = DateTime.now().toIso8601String();
                  
                  completedOrders.add(orderToCancel);
                  await prefs.setString('completed_orders', json.encode(completedOrders));
                  
                  // Update FoodMenu provider
                  if (mounted) {
                    final foodMenu = Provider.of<FoodMenu>(dialogContext, listen: false);
                    await foodMenu.markOrderAsCancelled(orderId, reason);
                  }
                  
                  // Save updated orders list
                  await _saveOrderDataToPrefs();
                  
                  if (!mounted) return;
                  
                  // Navigate to order history screen
                  Navigator.of(dialogContext).pushReplacementNamed('/order_history').then((_) {
                    if (!mounted) return;
                    // Show success message after navigation is complete
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Order cancelled successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                } else {
                  if (!mounted) return;
                  
                  // Revert optimistic update on failure
                  setState(() {
                    if (!orders.contains(orderToCancel)) {
                      orders.add(orderToCancel);
                      orders.sort((a, b) => a['order_id'].toString().compareTo(b['order_id'].toString()));
                    }
                    selectedOrder = orderToCancel;
                  });
                  
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel order. Please try again.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error cancelling order: $e');
                if (!mounted) return;
                
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Error cancelling order: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
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

  // Helper method to get full image URL
  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      print('⚠️ Empty or null image path');
      return '';
    }
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      print('✅ Using full URL: $imagePath');
      return imagePath;
    }
    
    // Get base URL from environment
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null) {
      print('⚠️ API_BASE_URL not found in environment variables');
      return '';
    }
    
    // Clean up the image path and base URL
    final cleanImagePath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    // Construct the full URL
    final fullUrl = '$cleanBaseUrl/$cleanImagePath';
    print('🔄 Constructed image URL: $fullUrl');
    return fullUrl;
  }

  // Constants
  static const Color kLogoGreen = Color(0xFF00CC00);
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




