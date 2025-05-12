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
import '../../../models/constants.dart';


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
    isLoading = true;
    _loadAllOrders();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Register WebSocket status update callback
    _orderService.setOnStatusUpdate((data) {
      if (data == null) {
        print("⚠️ Received null WebSocket data");
        return;
      }
      
      final orderId = data['order_id']?.toString() ?? '';
      if (orderId.isEmpty) {
        print("⚠️ Received WebSocket data with empty order_id");
        return;
      }
      
      // Convert from backend format (Title Case With Spaces) to frontend format (lowercase_with_underscores)
      final rawStatus = data['new_status']?.toString() ?? '';
      final newStatus = _convertToFrontendStatusFormat(rawStatus);
      
      // Check for cancellation flag
      final isCancelled = data['is_cancelled'] == true || newStatus == 'cancelled';
      final cancelReason = data['cancel_reason']?.toString();
      
      print("🔄 WebSocket update received: Order #$orderId status changed to $newStatus (raw: $rawStatus)");
      if (isCancelled) {
        print("🚫 Order #$orderId has been cancelled. Reason: $cancelReason");
      }
      
      // Always use setState to trigger UI update
      if (mounted) {
        setState(() {
          // Update all orders with this ID
          for (var order in orders) {
            if (order['order_id'].toString() == orderId) {
              print("📝 Updating order #$orderId from ${order['status']} to $newStatus");
              order['status'] = newStatus;
              
              // If cancelled, add the necessary fields
              if (isCancelled) {
                order['is_cancelled'] = true;
                if (cancelReason != null) {
                  order['cancel_reason'] = cancelReason;
                }
                
                // Mark for removal on next refresh
                animatedOrders.add(orderId);
              }
            }
          }
          
          // If the selected order is the one updated, update its status too
          if (selectedOrder != null && selectedOrder!['order_id'].toString() == orderId) {
            print("🔄 Updating selected order #$orderId status from ${selectedOrder!['status']} to $newStatus");
            selectedOrder = {
              ...selectedOrder!,
              'status': newStatus,
            };
            
            // If cancelled, add the necessary fields
            if (isCancelled) {
              selectedOrder!['is_cancelled'] = true;
              if (cancelReason != null) {
                selectedOrder!['cancel_reason'] = cancelReason;
              }
            }
            
            // Force refresh by adding to animatedOrders set
            animatedOrders.add(orderId);
            
            // Force the timeline to rebuild
            print("🔄 Forcing timeline rebuild for order #$orderId");
          }
          
          // Save changes to SharedPreferences
          _saveOrderDataToPrefs();
          
          // If the order was cancelled, immediately save to history and remove from timeline
          if (isCancelled) {
            print("🚫 Order #$orderId was cancelled - saving to history and removing from timeline");
            
            // Find the cancelled order
            Map<String, dynamic>? cancelledOrder;
            
            // Check if it's the selected order
            if (selectedOrder != null && selectedOrder!['order_id'].toString() == orderId) {
              cancelledOrder = Map<String, dynamic>.from(selectedOrder!);
            } else {
              // Try to find it in the orders list
              final index = orders.indexWhere((order) => order['order_id'].toString() == orderId);
              if (index >= 0) {
                cancelledOrder = Map<String, dynamic>.from(orders[index]);
              }
            }
            
            if (cancelledOrder != null) {
              // Add cancellation details if missing
              cancelledOrder['status'] = 'cancelled';
              cancelledOrder['is_cancelled'] = true;
              if (cancelReason != null) {
                cancelledOrder['cancel_reason'] = cancelReason;
              }
              cancelledOrder['cancelled_at'] = DateTime.now().toIso8601String();
              
              // Save to history (outside setState to avoid nested setState calls)
              Future.microtask(() => _saveCancelledOrderToHistory(cancelledOrder!));
            }
            
            // Remove from the orders list immediately
            final beforeCount = orders.length;
            orders.removeWhere((order) => order['order_id'].toString() == orderId);
            print("🗑️ Removed cancelled order from timeline (${beforeCount} → ${orders.length} orders)");
            
            // If selected order was cancelled, select a new one
            if (selectedOrder != null && selectedOrder!['order_id'].toString() == orderId) {
              if (orders.isNotEmpty) {
                selectedOrder = Map<String, dynamic>.from(orders.first);
                print("🔍 Selected new order #${selectedOrder!['order_id']}");
              } else {
                selectedOrder = null;
                print("ℹ️ No orders remaining - cleared selection");
              }
            }
          }
        });
      }
    });

    // Initialize WebSocket connection (userId/shopId)
    _initializeWebSocketConnection();
  }
  
  // Check if order is cancelled via the cancel_reason field and is_cancelled flag
  bool _isOrderCancelled(Map<String, dynamic> order) {
    final hasCancelReason = order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty;
    final isCancelled = order['is_cancelled'] == true;
    final status = order['status']?.toString()?.toLowerCase() ?? '';
    
    // Consider the order cancelled if any of these conditions are true:
    // 1. It has a cancel_reason
    // 2. The is_cancelled flag is true
    // 3. The status is 'cancelled' (legacy support)
    return hasCancelReason || isCancelled || status == 'cancelled';
  }

  // Helper method to convert backend status to frontend format
  String _convertToFrontendStatusFormat(String backendStatus) {
    // Map of backend status (Title Case With Spaces) to frontend status (lowercase_with_underscores)
    final String normalized = backendStatus.toLowerCase();
    
    if (normalized == 'pending') return 'pending';
    if (normalized == 'confirmed') return 'confirmed';
    if (normalized == 'preparing') return 'preparing';
    if (normalized == 'ready for pickup') return 'ready_for_pickup';
    if (normalized == 'delivered') return 'completed'; // Backend uses "Delivered" instead of "Completed"
    if (normalized == 'cancelled') return 'cancelled'; // Handle both 'Cancelled' and 'cancelled'
    
    // If we can't match exactly, try to normalize by replacing spaces with underscores
    return normalized.replaceAll(' ', '_');
  }
  
  // Format datetime string to IST
  String _formatPickupTimeToIST(String pickupTimeStr) {
    try {
      // Parse the date time string as UTC
      DateTime dateTime = DateTime.parse(pickupTimeStr);
      
      // Convert to IST (UTC+5:30)
      final istOffset = const Duration(hours: 5, minutes: 30);
      final istDateTime = dateTime.toUtc().add(istOffset);
      
      // Format the time in 12-hour format with AM/PM and IST indicator
      final hour = istDateTime.hour;
      final minute = istDateTime.minute;
      final period = hour < 12 ? 'AM' : 'PM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      
      // Create formatted date and time
      final day = istDateTime.day.toString().padLeft(2, '0');
      final month = _getMonthAbbr(istDateTime.month);
      
      return '$day $month, $hour12:${minute.toString().padLeft(2, '0')} $period (IST)';
    } catch (e) {
      print("❌ Error formatting pickup time to IST: $e");
      return pickupTimeStr;
    }
  }
  
  // Helper method to get month abbreviation
  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  // Initialize WebSocket connection with retry logic
  Future<void> _initializeWebSocketConnection() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      final shopId = await ShopService().getStoredShopId();
      
      if (userId != null && shopId != null) {
        print("🔌 Initializing WebSocket connection for user $userId and shop $shopId");
        _orderService.initializeWebSocket(userId.toString(), shopId);
        
        // Store for reconnection if needed
        _currentUserId = userId.toString();
        _currentShopId = shopId;
      } else {
        print("⚠️ Cannot initialize WebSocket: Missing user ID or shop ID");
      }
    } catch (e) {
      print("❌ Error initializing WebSocket connection: $e");
      
      // Retry after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _initializeWebSocketConnection();
      }
    });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check and remove cancelled orders first - this is critical to prevent cancelled orders from appearing
    _checkAndRemoveCancelledOrders().then((_) {
      // Get arguments from navigation
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && mounted) {
        print("📦 Received order data from navigation: ${args['order_id']}");
        
        final orderId = args['order_id']?.toString() ?? '';
        
        // First check if this order is in our cancelled orders list
        _isOrderCancelledInStorage(orderId).then((isCancelled) {
          if (isCancelled) {
            print("🚫 Order #$orderId from navigation was previously cancelled - ignoring");
            // Initialize empty orders immediately
            _initializeUserAndOrders();
            return;
          }
          
          // Check if items exist in the args
          final items = args['items'] as List<dynamic>?;
          final totalAmount = args['total_amount'] as num? ?? 0.0;
          final status = args['status']?.toString()?.toLowerCase() ?? 'pending';
          
          // Skip completed or cancelled orders that might be passed from navigation
          if (status == 'completed' || status == 'cancelled' || status == 'delivered') {
            print("⏭️ Skipping completed/cancelled order #$orderId from navigation");
            // Initialize empty orders immediately
            _initializeUserAndOrders();
            return;
          }
          
          // Create a deep copy to ensure all nested data is preserved
          final argsCopy = Map<String, dynamic>.from(args);
          
          if (items == null || items.isEmpty) {
            print("⚠️ Warning: Order data from navigation has no items! Order ID: $orderId");
            
            // Create a placeholder item with total amount until we can fetch from backend
            if (totalAmount > 0) {
              final placeholderItem = {
                'id': 'placeholder',
                'food_id': 'placeholder',
                'name': 'Order Item',
                'quantity': 1,
                'price': totalAmount,
                'total_price': totalAmount,
                'total_item_price': totalAmount,
                'description': '',
                'image': '',
                'isVeg': true,
                'category': '',
              };
              
              argsCopy['items'] = [placeholderItem];
              print("📊 Created placeholder item with total amount: $totalAmount until backend data is available");
            } else {
              argsCopy['items'] = [];
            }
            
            // Since we don't have real items, try to fetch them from the backend immediately
            Future.microtask(() => _fetchOrderDetailsFromBackend(orderId));
          } else {
            print("✅ Order data has ${items.length} items");
            // Debug items content
            for (var item in items) {
              print("   📝 Item: ${item['name']}, price: ${item['price']}, quantity: ${item['quantity']}");
            }
            
            if (items.isNotEmpty) {
              argsCopy['items'] = List<dynamic>.from(items.map((item) => Map<String, dynamic>.from(item)));
            }
          }
          
          setState(() {
            _orderData = argsCopy;
          });
          _saveOrderData(argsCopy);
          
          // Select this order immediately
          if (orders.isEmpty || selectedOrder == null || 
              selectedOrder!['order_id'].toString() != orderId) {
            setState(() {
              selectedOrder = argsCopy;
            });
          }
          
          // Add a longer delay before initializing all orders to give the backend time to register the new order
          // This helps prevent race conditions where backend data might overwrite complete local data
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted) {
              _initializeUserAndOrders();
            }
          });
        });
      } else {
        // If no navigation arguments, try to load from stored data
        final foodMenu = Provider.of<FoodMenu>(context, listen: false);
        if (foodMenu.latestOrderData != null) {
          print("📦 Loading latest order from FoodMenu provider");
          
          final latestOrderData = foodMenu.latestOrderData!;
          final orderId = latestOrderData['order_id']?.toString() ?? '';
          
          // Check if this order is in our cancelled orders list
          _isOrderCancelledInStorage(orderId).then((isCancelled) {
            if (isCancelled) {
              print("🚫 Latest order #$orderId was previously cancelled - ignoring");
              foodMenu.clearLatestOrderData(); // Clear it from provider
              // Initialize empty orders immediately
              _initializeUserAndOrders();
              return;
            }
            
            final items = latestOrderData['items'] as List<dynamic>?;
            final totalAmount = latestOrderData['total_amount'] as num? ?? 0.0;
            final status = latestOrderData['status']?.toString()?.toLowerCase() ?? 'pending';
            
            // Skip completed or cancelled orders that might be stored
            if (status == 'completed' || status == 'cancelled' || status == 'delivered') {
              print("⏭️ Skipping completed/cancelled order #$orderId from provider");
              // Initialize empty orders immediately
              _initializeUserAndOrders();
              return;
            }
            
            // Create a deep copy to ensure all nested data is preserved
            final latestOrderCopy = Map<String, dynamic>.from(latestOrderData);
            
            if (items == null || items.isEmpty) {
              print("⚠️ Warning: Latest order data from provider has no items! Order ID: $orderId");
              
              // Create a placeholder item with total amount until we can fetch from backend
              if (totalAmount > 0) {
                final placeholderItem = {
                  'id': 'placeholder',
                  'food_id': 'placeholder',
                  'name': 'Order Item',
                  'quantity': 1,
                  'price': totalAmount,
                  'total_price': totalAmount,
                  'total_item_price': totalAmount,
                  'description': '',
                  'image': '',
                  'isVeg': true,
                  'category': '',
                };
                
                latestOrderCopy['items'] = [placeholderItem];
                print("📊 Created placeholder item with total amount: $totalAmount until backend data is available");
              } else {
                latestOrderCopy['items'] = [];
              }
              
              // Try to fetch the order details from the backend
              if (orderId.isNotEmpty) {
                Future.microtask(() => _fetchOrderDetailsFromBackend(orderId));
              }
            } else {
              print("✅ Latest order has ${items.length} items");
              // Debug items content
              for (var item in items) {
                print("   📝 Item: ${item['name']}, price: ${item['price']}, quantity: ${item['quantity']}");
              }
              
              if (items.isNotEmpty) {
                latestOrderCopy['items'] = List<dynamic>.from(items.map((item) => Map<String, dynamic>.from(item)));
              }
            }
            
            setState(() {
              _orderData = latestOrderCopy;
            });
            
            // Select this order immediately if no order is selected
            if (selectedOrder == null && _orderData != null) {
              setState(() {
                selectedOrder = _orderData;
              });
            }
            
            // Add a longer delay before initializing orders to give the backend time to register the new order
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) {
                _initializeUserAndOrders();
              }
            });
          });
        } else {
          // No order data from navigation or provider, initialize orders immediately
          _initializeUserAndOrders();
        }
      }
    });
  }

  // Helper to check if an order has been cancelled in storage
  Future<bool> _isOrderCancelledInStorage(String orderId) async {
    // Skip if order ID is empty
    if (orderId.isEmpty) return false;
    
    try {
      // First check in the FoodMenu provider
      final foodMenu = Provider.of<FoodMenu>(context, listen: false);
      final isCancelledInProvider = await foodMenu.checkIfOrderIsCancelled(orderId);
      
      if (isCancelledInProvider) {
        print("🚫 Order #$orderId found cancelled in FoodMenu provider");
        return true;
      }
      
      // Check in SharedPreferences for completed_orders
      final prefs = await SharedPreferences.getInstance();
      final cancelledOrdersJson = prefs.getString('completed_orders') ?? '[]';
      final cancelledOrdersList = _safelyParseCancelledOrders(cancelledOrdersJson);
      
      // Check if the order ID is in the cancelled orders list
      return cancelledOrdersList.any((order) {
        if (order is Map) {
          final storedOrderId = order['order_id']?.toString() ?? '';
          final storedStatus = order['status']?.toString()?.toLowerCase() ?? '';
          final isCancelled = order['is_cancelled'] == true;
          
          return storedOrderId == orderId && 
                 (storedStatus == 'cancelled' || isCancelled || 
                  order['cancel_reason'] != null);
        }
        return false;
      });
    } catch (e) {
      print("❌ Error checking if order #$orderId is cancelled: $e");
      return false;
    }
  }
  
  // Helper to check and remove any cancelled orders from current orders list
  Future<void> _checkAndRemoveCancelledOrders() async {
    try {
      // Get cancelled orders from multiple sources
      final Set<String> cancelledOrderIds = <String>{};
      
      // 1. First check FoodMenu provider
      try {
        final foodMenu = Provider.of<FoodMenu>(context, listen: false);
        if (foodMenu.isOrderCancelled && foodMenu.latestOrderData != null) {
          final cancelledOrderId = foodMenu.latestOrderData!['order_id']?.toString();
          if (cancelledOrderId != null && cancelledOrderId.isNotEmpty) {
            cancelledOrderIds.add(cancelledOrderId);
            print("🚫 Found cancelled order #$cancelledOrderId in FoodMenu provider");
          }
        }
      } catch (e) {
        print("⚠️ Error checking FoodMenu provider for cancelled orders: $e");
      }
      
      // 2. Check SharedPreferences for all completed and cancelled orders
      final prefs = await SharedPreferences.getInstance();
      final cancelledOrdersJson = prefs.getString('completed_orders') ?? '[]';
      final cancelledOrdersList = _safelyParseCancelledOrders(cancelledOrdersJson);
      
      // Add from completed_orders storage
      for (var order in cancelledOrdersList) {
        if (order is Map) {
          final orderId = order['order_id']?.toString() ?? '';
          if (orderId.isNotEmpty) {
            final status = order['status']?.toString()?.toLowerCase() ?? '';
            final isCancelled = order['is_cancelled'] == true || 
                                order['cancel_reason'] != null;
            
            if (status == 'cancelled' || isCancelled) {
              cancelledOrderIds.add(orderId);
            }
          }
        }
      }
      
      print("🚫 Found total of ${cancelledOrderIds.length} cancelled orders to filter out");
      
      if (cancelledOrderIds.isNotEmpty && mounted) {
        // Check if selected order is cancelled
        if (selectedOrder != null && 
            cancelledOrderIds.contains(selectedOrder!['order_id'].toString())) {
          print("🚫 Selected order #${selectedOrder!['order_id']} is cancelled - removing");
          
          setState(() {
            // Remove from orders list
            orders.removeWhere((order) => 
              cancelledOrderIds.contains(order['order_id'].toString()));
            
            // Update selected order
            if (orders.isEmpty) {
              selectedOrder = null;
            } else {
              selectedOrder = orders.first;
            }
          });
        } else if (orders.isNotEmpty) {
          // Filter out cancelled orders
          final filteredOrders = orders.where((order) => 
            !cancelledOrderIds.contains(order['order_id'].toString())).toList();
          
          // Only update state if there were actually orders removed
          if (filteredOrders.length != orders.length) {
            print("🚫 Removed ${orders.length - filteredOrders.length} cancelled orders from the timeline");
            
            if (mounted) {
              setState(() {
                orders = filteredOrders;
                
                // Check if we need to update selected order
                if (selectedOrder != null && !filteredOrders.any((order) => 
                  order['order_id'].toString() == selectedOrder!['order_id'].toString())) {
                  selectedOrder = filteredOrders.isNotEmpty ? filteredOrders.first : null;
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print("❌ Error checking for cancelled orders: $e");
    }
  }
  
  // Fetch detailed order data directly from backend
  Future<void> _fetchOrderDetailsFromBackend(String orderId) async {
    try {
      print("🔄 Fetching order #$orderId from backend...");
      setState(() {
        isLoading = true;
      });
      
      final orderData = await _orderService.fetchOrderById(orderId);
      
      if (orderData != null && mounted) {
        print("✅ Successfully fetched order #$orderId with ${(orderData['items'] as List?)?.length ?? 0} items");
        
        // Debug the raw items data to check for image paths
        final rawItems = orderData['items'] as List<dynamic>? ?? [];
        for (var item in rawItems) {
          final rawImagePath = item['image']?.toString() ?? '';
          final fullImageUrl = getFullImageUrl(rawImagePath);
          print("🖼️ Raw Item Image Path: $rawImagePath → Full URL: $fullImageUrl");
        }
        
        // Normalize status from backend format
        final rawStatus = orderData['status']?.toString()?.toLowerCase() ?? 'pending';
        final status = _convertToFrontendStatusFormat(rawStatus);
        
        // Check if the order is cancelled via either status or cancel_reason
        final isCancelled = status == 'cancelled' || _isOrderCancelled(orderData);
        
        // Skip the order if it's completed or cancelled
        if (status == 'completed' || isCancelled || status == 'delivered') {
          print("⏭️ Skipping completed/cancelled order #$orderId with status: $status");
          if (mounted) {
            setState(() {
              // If this is the selected order, clear it
              if (selectedOrder != null && selectedOrder!['order_id'].toString() == orderId) {
                selectedOrder = null;
              }
              // Remove the order from the orders list
              orders.removeWhere((order) => order['order_id'].toString() == orderId);
              isLoading = false;
            });
          }
          return;
        }
        
        // Create a deep copy of the order data to avoid reference issues
        final Map<String, dynamic> normalizedOrderData = {
          'order_id': orderData['order_id']?.toString() ?? '',
          'otp': orderData['otp']?.toString() ?? '',
          'payment_method': orderData['payment_method']?.toString() ?? '',
          'pickup_time': orderData['pickup_time']?.toString() ?? '',
          'total_amount': orderData['total_amount'] is num ? orderData['total_amount'] : 0.0,
          'status': status,
          'shop_id': orderData['shop_id']?.toString() ?? '',
        };
        
        // Process items array with proper formatting
        final items = orderData['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          normalizedOrderData['items'] = items.map((item) => {
            'id': item['food_id']?.toString() ?? '',
            'food_id': item['food_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Unknown Item',
            'quantity': item['quantity'] is int ? item['quantity'] : 
                       (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
            'price': item['price'] is num ? item['price'] : 
                    (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
            'total_price': item['total_price'] is num ? item['total_price'] : 
                         (item['price'] is num && item['quantity'] is num ? 
                            (item['price'] as num) * (item['quantity'] as num) : 0.0),
            'total_item_price': item['total_item_price'] is num ? item['total_item_price'] :
                               (item['total_price'] is num ? item['total_price'] : 
                                (item['price'] is num && item['quantity'] is num ? 
                                 (item['price'] as num) * (item['quantity'] as num) : 0.0)),
            'description': item['description']?.toString() ?? '',
            'image': item['image']?.toString() ?? '',
            'isVeg': item['isVeg'] is bool ? item['isVeg'] : (item['type']?.toString()?.toLowerCase() == 'veg'),
            'category': item['category']?.toString() ?? '',
          }).toList();
          
          // Log the items for debugging
          print("📦 Processed ${normalizedOrderData['items'].length} items for order #$orderId");
          for (var item in normalizedOrderData['items']) {
            print("   📦 Item: ${item['name']}, price=${item['price']}, quantity=${item['quantity']}");
          }
        } else {
          print("⚠️ No items found for order #$orderId");
          normalizedOrderData['items'] = [];
        }
        
        if (mounted) {
          // Update the orders list with the new data
          bool orderFound = false;
          
          for (int i = 0; i < orders.length; i++) {
            if (orders[i]['order_id'].toString() == orderId) {
              // Keep existing items if they have more details
              final existingItems = orders[i]['items'] as List<dynamic>? ?? [];
              final newItems = normalizedOrderData['items'] as List<dynamic>? ?? [];
              
              if (existingItems.isNotEmpty && newItems.isEmpty) {
                print("🔄 Keeping existing items since new data has no items");
                normalizedOrderData['items'] = existingItems;
              }
              
              orders[i] = normalizedOrderData;
              orderFound = true;
              break;
            }
          }
          
          if (!orderFound) {
            orders.add(normalizedOrderData);
          }
          
          // Check if this is the selected order, and update it if so
          if (selectedOrder != null && selectedOrder!['order_id'].toString() == orderId) {
            selectedOrder = Map<String, dynamic>.from(normalizedOrderData);
          } else if (selectedOrder == null && orders.isNotEmpty) {
            // If no order was selected, select this one
            selectedOrder = Map<String, dynamic>.from(normalizedOrderData);
          }
          
          // Save the updated order data
          await _saveOrderDataToPrefs();
          
          setState(() {
            isLoading = false;
          });
          
          // Remove any error snackbars
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      } else {
        print("❌ Failed to fetch order #$orderId from backend");
        
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Could not fetch order details from server"),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Error fetching order #$orderId details: $e");
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unable to load order details. Please try again later."),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _fetchOrderDetailsFromBackend(orderId);
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadAllOrders() async {
    try {
      print("🔄 Loading all orders from SharedPreferences...");
      final prefs = await SharedPreferences.getInstance();
      
      // First try to load from args if available (passed from cart screen)
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      Map<String, dynamic>? latestOrder;

      // Check if args contain order data
      if (args != null && args.containsKey('order_id')) {
        print("📦 Using order data from navigation args: ${args['order_id']}");
        
        // Check if the order from arguments is completed or cancelled
        final status = args['status']?.toString().toLowerCase() ?? '';
        if (status == 'completed' || status == 'cancelled' || status == 'delivered') {
          print("⏭️ Skipping completed/cancelled order from navigation args");
          latestOrder = null;
        } else {
          latestOrder = args;
        }
      } else {
        // Load the latest order from SharedPreferences if no args
        final latestOrderString = prefs.getString('latest_order_data');
        if (latestOrderString != null) {
          final tempOrder = json.decode(latestOrderString);
          
          // Check if the latest order is completed or cancelled
          final status = tempOrder['status']?.toString().toLowerCase() ?? '';
          if (status == 'completed' || status == 'cancelled' || status == 'delivered') {
            print("⏭️ Skipping completed/cancelled latest order: ${tempOrder['order_id']}");
            latestOrder = null;
          } else {
            latestOrder = tempOrder;
            print("📦 Loaded latest order from SharedPreferences: ${latestOrder?['order_id']}");
          }
        }
      }
      
      // Validate the latest order data
      if (latestOrder != null && latestOrder.containsKey('order_id')) {
        // Ensure the items list exists and is properly formed
        final items = latestOrder['items'] as List<dynamic>? ?? [];
        print("📦 Latest order has ${items.length} items");
        
        // Debug items in the latest order
        for (var item in items) {
          try {
            print("   📝 Latest order item: name=${item['name'] ?? 'Unknown'}, price=${item['price'] ?? 0}, quantity=${item['quantity'] ?? 1}");
          } catch (e) {
            print("❌ Error parsing item: $e");
          }
        }
        
        // Load existing orders
        final existingOrdersString = prefs.getString('all_orders');
        List<Map<String, dynamic>> existingOrders = [];
        
        if (existingOrdersString != null) {
          final List<dynamic> decoded = json.decode(existingOrdersString);
          
          // Filter out completed and cancelled orders
          for (var order in decoded) {
            if (order is! Map<String, dynamic>) continue;
            
            final status = order['status']?.toString().toLowerCase() ?? '';
            if (status == 'completed' || status == 'cancelled' || status == 'delivered') {
              print("⏭️ Filtering out completed/cancelled order #${order['order_id']} from timeline");
              continue;
            }
            
            existingOrders.add(Map<String, dynamic>.from(order));
          }
          
          print("📋 Loaded ${existingOrders.length} active orders after filtering out completed orders");
          
          // Process each existing order to ensure items are properly parsed
          for (var i = 0; i < existingOrders.length; i++) {
            final order = existingOrders[i];
            final orderItems = order['items'] as List<dynamic>? ?? [];
            
            print("📋 Loaded order #${order['order_id']} with ${orderItems.length} items from SharedPreferences");
            
            // Ensure all items have proper data
            if (orderItems.isNotEmpty) {
              try {
                for (var j = 0; j < orderItems.length; j++) {
                  final item = orderItems[j];
                  // Ensure item is a Map
                  if (item is Map) {
                    // Check for required fields
                    if (!item.containsKey('name') || !item.containsKey('price')) {
                      print("⚠️ Order #${order['order_id']} has incomplete item data at index $j");
                    }
                  }
                }
              } catch (e) {
                print("❌ Error processing items in order #${order['order_id']}: $e");
              }
            }
          }
        }

        // Check if the latest order is already in the list
        final String latestOrderId = latestOrder['order_id'].toString();
        bool orderExists = existingOrders.any((order) => 
          order['order_id']?.toString() == latestOrderId);

        if (!orderExists) {
          print("📋 Adding latest order to order list");
          // Create a proper deep copy with full data structure
          final latestOrderCopy = Map<String, dynamic>.from(latestOrder);
          
          // Properly copy items list with full structure
          if (items.isNotEmpty) {
            latestOrderCopy['items'] = items.map((item) => {
              'id': item['id']?.toString() ?? '',
              'food_id': item['food_id']?.toString() ?? item['id']?.toString() ?? '',
              'name': item['name']?.toString() ?? 'Unknown Item',
              'quantity': item['quantity'] is int ? item['quantity'] : 
                         (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
              'price': item['price'] is num ? item['price'] : 
                      (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
              'total_price': item['total_price'] is num ? item['total_price'] :
                            (item['total_item_price'] is num ? item['total_item_price'] : 
                             (item['price'] is num && item['quantity'] is num ? 
                              (item['price'] as num) * (item['quantity'] as num) : 0.0)),
              'total_item_price': item['total_item_price'] is num ? item['total_item_price'] :
                                 (item['total_price'] is num ? item['total_price'] : 
                                  (item['price'] is num && item['quantity'] is num ? 
                                   (item['price'] as num) * (item['quantity'] as num) : 0.0)),
              'description': item['description']?.toString() ?? '',
              'image': item['image']?.toString() ?? '',
              'isVeg': item['isVeg'] is bool ? item['isVeg'] : true,
              'category': item['category']?.toString() ?? '',
            }).toList();
          }
          
          // Add the latest order to the beginning of the list
          existingOrders.insert(0, latestOrderCopy);
          
          // Save updated orders list
          await prefs.setString('all_orders', json.encode(existingOrders));
          print("💾 Saved updated order list with ${existingOrders.length} orders");
        } else {
          print("ℹ️ Latest order ${latestOrder['order_id']} already exists in order list");
          
          // Update the existing order with latest data if needed
          for (var i = 0; i < existingOrders.length; i++) {
            if (existingOrders[i]['order_id']?.toString() == latestOrderId) {
              // Update order status if needed
              if (latestOrder['status'] != null && 
                  latestOrder['status'] != existingOrders[i]['status']) {
                existingOrders[i]['status'] = latestOrder['status'];
              }
              
              // Check if we need to update items
              final existingItems = existingOrders[i]['items'] as List<dynamic>? ?? [];
              if (existingItems.isEmpty && items.isNotEmpty) {
                print("🔄 Updating items for order #$latestOrderId");
                existingOrders[i]['items'] = items.map((item) => {
                  'id': item['id']?.toString() ?? '',
                  'food_id': item['food_id']?.toString() ?? item['id']?.toString() ?? '',
                  'name': item['name']?.toString() ?? 'Unknown Item',
                  'quantity': item['quantity'] is int ? item['quantity'] : 
                             (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
                  'price': item['price'] is num ? item['price'] : 
                          (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
                  'total_price': item['total_price'] is num ? item['total_price'] :
                                (item['total_item_price'] is num ? item['total_item_price'] : 
                                 (item['price'] is num && item['quantity'] is num ? 
                                  (item['price'] as num) * (item['quantity'] as num) : 0.0)),
                  'total_item_price': item['total_item_price'] is num ? item['total_item_price'] :
                                     (item['total_price'] is num ? item['total_price'] : 
                                      (item['price'] is num && item['quantity'] is num ? 
                                       (item['price'] as num) * (item['quantity'] as num) : 0.0)),
                  'description': item['description']?.toString() ?? '',
                  'image': item['image']?.toString() ?? '',
                  'isVeg': item['isVeg'] is bool ? item['isVeg'] : true,
                  'category': item['category']?.toString() ?? '',
                }).toList();
                
                // Save updated orders list
                await prefs.setString('all_orders', json.encode(existingOrders));
              }
              break;
            }
          }
        }

        if (mounted) {
          setState(() {
            orders = existingOrders;
            print("📋 Loaded ${orders.length} orders total");
            
            // Set selectedOrder to the latest order (from navigation or first in list)
            if (latestOrder != null) {
              // Create a proper deep copy
              selectedOrder = Map<String, dynamic>.from(latestOrder);
            
              // Properly copy items with full structure
              if (items.isNotEmpty) {
                selectedOrder!['items'] = items.map((item) => {
                  'id': item['id']?.toString() ?? '',
                  'food_id': item['food_id']?.toString() ?? item['id']?.toString() ?? '',
                  'name': item['name']?.toString() ?? 'Unknown Item',
                  'quantity': item['quantity'] is int ? item['quantity'] : 
                             (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
                  'price': item['price'] is num ? item['price'] : 
                          (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
                  'total_price': item['total_price'] is num ? item['total_price'] :
                                (item['total_item_price'] is num ? item['total_item_price'] : 
                                 (item['price'] is num && item['quantity'] is num ? 
                                  (item['price'] as num) * (item['quantity'] as num) : 0.0)),
                  'total_item_price': item['total_item_price'] is num ? item['total_item_price'] :
                                     (item['total_price'] is num ? item['total_price'] : 
                                      (item['price'] is num && item['quantity'] is num ? 
                                       (item['price'] as num) * (item['quantity'] as num) : 0.0)),
                  'description': item['description']?.toString() ?? '',
                  'image': item['image']?.toString() ?? '',
                  'isVeg': item['isVeg'] is bool ? item['isVeg'] : true,
                  'category': item['category']?.toString() ?? '',
                }).toList();
              }
              print("🔍 Set selectedOrder to #${selectedOrder!['order_id']} with ${(selectedOrder!['items'] as List?)?.length ?? 0} items");
            } else if (existingOrders.isNotEmpty) {
              // If no latest order, use the first order in the list
              final firstOrder = existingOrders[0];
              selectedOrder = Map<String, dynamic>.from(firstOrder);
              
              // Copy items
              final firstOrderItems = firstOrder['items'] as List<dynamic>? ?? [];
              if (firstOrderItems.isNotEmpty) {
                selectedOrder!['items'] = List<dynamic>.from(firstOrderItems);
              }
              print("🔍 Selected first order #${selectedOrder!['order_id']} from list");
            }
            
            isLoading = false;
          });
        }
      } else {
        print("⚠️ No valid order data available or all orders are completed");
        if (mounted) {
          setState(() {
            orders = [];
            selectedOrder = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    
    // Always initialize from backend after loading from local storage
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _initializeUserAndOrders();
      }
    });
  }

  Future<void> _saveOrderData(Map<String, dynamic> orderData) async {
    try {
      // Ensure the items list is properly preserved
      final items = orderData['items'] as List<dynamic>? ?? [];
      print("💾 Saving order data: ${orderData['order_id']} with ${items.length} items");
      
      // Create a deep copy to ensure all nested data is preserved
      final orderDataCopy = Map<String, dynamic>.from(orderData);
      if (items.isNotEmpty) {
        // Deep copy each item in the list to avoid reference issues
        orderDataCopy['items'] = items.map((item) => {
          'id': item['id']?.toString() ?? '',
          'name': item['name']?.toString() ?? '',
          'quantity': item['quantity'] ?? 1,
          'price': item['price'] is num ? item['price'] : 0.0,
          'description': item['description']?.toString() ?? '',
          'image': item['image']?.toString() ?? '',
          'isVeg': item['isVeg'] ?? false,
          'total_item_price': item['total_item_price'] ?? 0.0,
          'category': item['category']?.toString() ?? '',
        }).toList();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('latest_order_data', json.encode(orderDataCopy));
      print("✅ Successfully saved order data with ${(orderDataCopy['items'] as List).length} items to SharedPreferences");
      
      // Also update the all_orders list with this order
      final existingOrdersString = prefs.getString('all_orders');
      List<Map<String, dynamic>> existingOrders = [];
      if (existingOrdersString != null) {
        final List<dynamic> decoded = json.decode(existingOrdersString);
        existingOrders = decoded.cast<Map<String, dynamic>>();
      }
      
      // Check if this order already exists in the list
      final orderId = orderData['order_id']?.toString();
      final orderIndex = existingOrders.indexWhere((order) => 
        order['order_id']?.toString() == orderId);
        
      if (orderIndex >= 0) {
        // Update the existing order with new data
        existingOrders[orderIndex] = orderDataCopy;
        print("🔄 Updated existing order #$orderId in all_orders list");
      } else if (orderId != null) {
        // Add as a new order at the beginning
        existingOrders.insert(0, orderDataCopy);
        print("➕ Added new order #$orderId to all_orders list");
      }
      
      // Save updated orders list
      await prefs.setString('all_orders', json.encode(existingOrders));
      
    } catch (e) {
      print("❌ Error saving order data: $e");
    }
  }

  Future<void> _initializeUserAndOrders() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        print("⚠️ No user ID found");
        if (mounted) {
          setState(() {
            isLoading = false;
            orders = [];
            selectedOrder = null;
          });
        }
        return;
      }

      final shopService = ShopService();
      final shopId = await shopService.getStoredShopId();
      if (shopId == null) {
        print("⚠️ No shop ID found");
        if (mounted) {
          setState(() {
            isLoading = false;
            orders = [];
            selectedOrder = null;
          });
        }
        return;
      }
      
      // Store the current selected order ID before fetching new data
      final String? currentSelectedOrderId = selectedOrder?['order_id']?.toString();
      
      // Store a deep copy of the current selected order to preserve it 
      // if it's a newly placed order that might not be in the backend yet
      Map<String, dynamic>? currentSelectedOrderCopy;
      if (selectedOrder != null) {
        currentSelectedOrderCopy = Map<String, dynamic>.from(selectedOrder!);
        final items = selectedOrder!['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          currentSelectedOrderCopy['items'] = List<dynamic>.from(
            items.map((item) => Map<String, dynamic>.from(item))
          );
        }
        print("📦 Preserved local copy of order #${currentSelectedOrderId} with ${items.length} items");
        
        // Skip backend fetch completely for very newly placed orders
        // Check if the order was received via navigation args in last 30 seconds
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final isVeryRecentNavigation = args != null && 
                                       args['order_id'] == currentSelectedOrderId &&
                                       DateTime.now().difference(DateTime.now()).inSeconds < 30;
                                       
        if (isVeryRecentNavigation) {
          // This is a new order that just came from the cart screen
          print("🔍 Detected very newly placed order #$currentSelectedOrderId - skipping backend fetch entirely");
          
          // Make sure the order appears in our order list
          if (!orders.any((order) => order['order_id'].toString() == currentSelectedOrderId)) {
            setState(() {
              orders = [currentSelectedOrderCopy!, ...orders];
              print("📋 Added newly placed order to orders list");
            });
          }
          
          return; // Skip the network request entirely for very new orders
        }
      }

      print("🔄 Fetching orders from backend...");
      final fetchedOrders = await _orderService.fetchOrders(shopId);
      print("✅ Fetched ${fetchedOrders.length} orders from backend");
      
      // Create set of valid order IDs from backend to verify existence
      final Set<String> validOrderIds = fetchedOrders
          .map((order) => order['order_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      
      // If current selected order exists but is not in backend, verify it with direct fetch
      if (currentSelectedOrderId != null && !validOrderIds.contains(currentSelectedOrderId)) {
        print("⚠️ Currently selected order #${currentSelectedOrderId} not found in backend data - verifying directly");
        try {
          final orderData = await _orderService.fetchOrderById(currentSelectedOrderId);
          if (orderData == null) {
            print("🚫 Order #$currentSelectedOrderId verified as deleted from database");
            
            // Remove from local storage since it no longer exists in database
            _markOrderAsDeletedInStorage(currentSelectedOrderId);
            
            // If we had a selected order that's now deleted, we'll need to select a different one
            if (selectedOrder != null && selectedOrder!['order_id'].toString() == currentSelectedOrderId) {
              setState(() {
                selectedOrder = null;
              });
            }
          } else {
            // The order does exist in backend, add to valid IDs
            validOrderIds.add(currentSelectedOrderId);
            print("✅ Order #$currentSelectedOrderId exists in database after direct verification");
          }
        } catch (e) {
          print("❌ Error verifying order #$currentSelectedOrderId: $e");
          // We'll assume it doesn't exist for safety
        }
      }
      
      // Check if the current selected order is in the fetched orders
      bool selectedOrderInFetched = false;
      if (currentSelectedOrderId != null) {
        selectedOrderInFetched = validOrderIds.contains(currentSelectedOrderId);
        
        if (!selectedOrderInFetched) {
          print("⚠️ Currently selected order #${currentSelectedOrderId} not found in backend data");
        }
      }
      
      // Get the list of cancelled orders from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final cancelledOrdersJson = prefs.getString('completed_orders') ?? '[]';
      final cancelledOrdersList = _safelyParseCancelledOrders(cancelledOrdersJson);
      
      final cancelledOrderIds = cancelledOrdersList
          .map((order) => order is Map ? order['order_id']?.toString() ?? '' : '')
          .where((id) => id.isNotEmpty)
          .toSet();
      
      print("🚫 Found ${cancelledOrderIds.length} cancelled orders in storage");
      
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
              'food_id': orderData['food_id']?.toString() ?? '',
              'name': orderData['name']?.toString() ?? '',
              'quantity': orderData['quantity'] ?? 1,
              'price': double.tryParse(orderData['price']?.toString() ?? '0') ?? 0.0,
              'total_price': (double.tryParse(orderData['price']?.toString() ?? '0') ?? 0.0) * (orderData['quantity'] ?? 1),
              'total_item_price': (double.tryParse(orderData['price']?.toString() ?? '0') ?? 0.0) * (orderData['quantity'] ?? 1),
              'description': orderData['description']?.toString() ?? '',
              'image': orderData['image']?.toString() ?? '',
              'isVeg': orderData['isVeg'] ?? true,
              'category': orderData['category']?.toString() ?? '',
            });
          }
          
          // Second pass: Create processed orders with grouped items
          final List<Map<String, dynamic>> updatedOrders = [];
          final Set<String> processedOrderIds = {}; // Track processed order IDs
          
          // First check if we need to prioritize our locally stored order data
          // This is critical for newly placed orders that might have more complete item data locally
          if (currentSelectedOrderCopy != null) {
            final localOrderId = currentSelectedOrderCopy['order_id'].toString();
            
            print("🔍 Checking if local order #$localOrderId should be prioritized");
            
            // Skip if not found in valid backend IDs (deleted from database)
            if (!validOrderIds.contains(localOrderId)) {
              print("⏭️ Skipping locally stored order #$localOrderId as it's not found in database");
            }
            // Don't add completed/cancelled orders to timeline view
            else if ((currentSelectedOrderCopy['status'] ?? '').toString().toLowerCase() != 'completed' && 
                (currentSelectedOrderCopy['status'] ?? '').toString().toLowerCase() != 'cancelled' && 
                (currentSelectedOrderCopy['status'] ?? '').toString().toLowerCase() != 'delivered' && 
                !_isOrderCancelled(currentSelectedOrderCopy) && 
                !cancelledOrderIds.contains(localOrderId)) {
                
              // Prioritize our local data if it contains item details
              final localItems = currentSelectedOrderCopy['items'] as List<dynamic>? ?? [];
              if (localItems.isNotEmpty) {
                print("📋 Local order #$localOrderId has ${localItems.length} items - prioritizing local data");
                
                // Add local order data first, before backend data
                updatedOrders.add(currentSelectedOrderCopy);
                processedOrderIds.add(localOrderId);
              }
            } else {
              print("⏭️ Skipping completed/cancelled local order #$localOrderId in timeline view");
            }
          }
          
          // Add backend-fetched orders next
          for (var orderData in fetchedOrders) {
            final orderId = orderData['order_id'].toString();
            
            // Skip if we've already processed this order
            if (processedOrderIds.contains(orderId)) {
              continue;
            }
            
            // Skip if this order is in the cancelled orders list
            if (cancelledOrderIds.contains(orderId)) {
              print("🚫 Skipping previously cancelled order #$orderId from backend data");
              continue;
            }
            
            processedOrderIds.add(orderId);
            
            // Ensure status is properly formatted
            String status = orderData['status']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'pending';
            print("📊 Processing order #$orderId with status: $status");
            
            // Skip completed or cancelled orders in timeline view
            if (status == 'completed' || status == 'cancelled' || status == 'delivered' || _isOrderCancelled(orderData)) {
              print("⏭️ Skipping completed/cancelled order #$orderId in timeline view");
              continue;
            }
            
            final processedOrder = {
              'order_id': orderId,
              'user_id': orderData['user_id'],
              'pickup_time': orderData['pickup_time'],
              'payment_method': orderData['payment_method'],
              'total_amount': double.tryParse(orderData['total_amount']?.toString() ?? '0') ?? 0.0,
              'otp': orderData['otp'],
              'status': status,
              'items': orderItemsMap[orderId] ?? [],
              'shop_id': shopId,
            };
            
            updatedOrders.add(processedOrder);
          }
          
          // Sort orders: pending first, then preparing, then ready_for_pickup
          updatedOrders.sort((a, b) {
            final statusA = a['status'].toString().toLowerCase();
            final statusB = b['status'].toString().toLowerCase();
            
            // Define status priority (lower number = higher priority)
            final getPriority = (String status) {
              if (status == 'pending') return 0;
              if (status == 'confirmed' || status == 'preparing') return 1;
              if (status == 'ready_for_pickup') return 2;
              return 3; // Other statuses
            };
            
            return getPriority(statusA).compareTo(getPriority(statusB));
          });

          // Update the orders list
          orders = updatedOrders;
          print("📱 Timeline now has ${orders.length} active orders");
          
          // Handle selected order
          if (selectedOrder != null) {
            final currentOrderId = selectedOrder!['order_id'].toString();
            final currentStatus = selectedOrder!['status']?.toString()?.toLowerCase() ?? '';
            final isCancelled = _isOrderCancelled(selectedOrder!);
            
            // Check if selected order no longer exists in database
            if (!validOrderIds.contains(currentOrderId)) {
              print("🚫 Currently selected order #$currentOrderId no longer exists in database");
              
              // Select a new order if available
              if (orders.isNotEmpty) {
                print("🔄 Selecting first available order from list of ${orders.length} orders");
                selectedOrder = orders[0];
              } else {
                print("🚫 No active orders available, clearing selection");
                selectedOrder = null;
              }
            }
            // If current selected order is completed/cancelled, and we have other orders, select the first active one
            else if ((currentStatus == 'completed' || currentStatus == 'cancelled' || currentStatus == 'delivered' || isCancelled || cancelledOrderIds.contains(currentOrderId)) && orders.isNotEmpty) {
              print("🔄 Currently selected order is completed/cancelled, selecting first active order instead");
              selectedOrder = orders[0];
            } else {
              // Try to find the selected order in the updated orders list
              final matchingOrderIndex = orders.indexWhere(
                (order) => order['order_id'].toString() == currentOrderId
              );
              
              if (matchingOrderIndex != -1) {
                final updatedOrderData = orders[matchingOrderIndex];
                
                // Get both sets of items
                final currentItems = selectedOrder!['items'] as List<dynamic>? ?? [];
                final updatedItems = updatedOrderData['items'] as List<dynamic>? ?? [];
                
                print("🔄 Updating selected order #$currentOrderId: Currently has ${currentItems.length} items, updated data has ${updatedItems.length} items");
                
                // ALWAYS PRIORITIZE ITEMS WITH MORE DETAILS
                final List<dynamic> mergedItems;
                if (currentItems.length >= updatedItems.length || updatedItems.isEmpty) {
                  print("📦 Keeping current items since they have more details (${currentItems.length} >= ${updatedItems.length})");
                  mergedItems = List<dynamic>.from(currentItems);
                } else {
                  print("📦 Using updated items from backend since they have more details (${updatedItems.length} > ${currentItems.length})");
                  mergedItems = List<dynamic>.from(updatedItems);
                }
                    
                setState(() {
                  // Update selected order with merged data
                  selectedOrder = {
                    ...updatedOrderData,
                    'items': mergedItems,
                  };
                });
              } else if (orders.isNotEmpty) {
                // If selected order not found, select the first available order
                print("📋 Selected order not found, selecting first available order");
                selectedOrder = orders[0];
              } else {
                // No orders available in the timeline view, clear selection
                print("📋 No active orders available, clearing selection");
                selectedOrder = null;
              }
            }
          } else if (selectedOrder == null && orders.isNotEmpty) {
            final orderData = orders[0];
            final items = orderData['items'] as List<dynamic>? ?? [];
            print("📋 Setting initial selected order #${orderData['order_id']} with ${items.length} items");
            
            setState(() {
              selectedOrder = Map<String, dynamic>.from(orderData);
              if (items.isNotEmpty) {
                selectedOrder!['items'] = List<dynamic>.from(items);
              }
            });
          }
        });
      }
      
      // Save the updated orders to persistent storage
      _saveOrderDataToPrefs();
      
    } catch (e) {
      print("❌ Error initializing orders: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _initializeUserAndOrders();
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      // Make sure we clear the loading state
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenWidth * 0.17),
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
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(screenWidth * 0.05),
              bottomRight: Radius.circular(screenWidth * 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: kLogoGreen.withOpacity(0.2),
                blurRadius: screenWidth * 0.03,
                offset: Offset(0, screenWidth * 0.007),
                spreadRadius: screenWidth * 0.002,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                      children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/menu');
          }, 
                  ),
                  
                  const SizedBox(width: 12),
                  Row(
                            children: [
                      const SizedBox(width: 10),
                      Center(child: SubTitles(title:'Order Timeline', color: Colors.white)),
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
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        
                        try {
                          // Check cancelled orders in local storage first
                          final prefs = await SharedPreferences.getInstance();
                          final cancelledOrdersJson = prefs.getString('completed_orders') ?? '[]';
                          final cancelledOrdersList = _safelyParseCancelledOrders(cancelledOrdersJson);
                          final cancelledOrderIds = cancelledOrdersList
                              .map((order) => order is Map ? order['order_id']?.toString() ?? '' : '')
                              .where((id) => id.isNotEmpty)
                              .toSet();
                              
                          // Check if currently selected order is cancelled
                          if (selectedOrder != null) {
                            final orderId = selectedOrder!['order_id'].toString();
                            
                            if (cancelledOrderIds.contains(orderId)) {
                              print("🚫 Selected order #$orderId was found in cancelled orders list");
                              setState(() {
                                // Remove from orders list if it exists there
                                orders.removeWhere((order) => order['order_id'].toString() == orderId);
                                
                                // Select a new order if available
                                if (orders.isNotEmpty) {
                                  selectedOrder = orders[0];
                                } else {
                                  selectedOrder = null;
                                }
                              });
                            } else {
                              // First refresh the current order if selected
                              final orderId = selectedOrder!['order_id'].toString();
                              print("🔄 Refreshing order #$orderId...");
                              
                              // Set the refreshing flag to trigger animation
                              setState(() {
                                selectedOrder!['refreshing'] = true;
                              });
                              
                              // Fetch the latest order details first
                              final orderData = await _orderService.fetchOrderById(orderId);
                              
                              if (orderData != null) {
                                final newStatus = orderData['status']?.toString().toLowerCase() ?? '';
                                final frontendStatus = _convertToFrontendStatusFormat(newStatus);
                                
                                // Check if the order is completed/cancelled
                                if (frontendStatus == 'completed' || frontendStatus == 'cancelled' || frontendStatus == 'delivered') {
                                  print("🔄 Order #$orderId has status $frontendStatus - removing from timeline");
                                  
                                  setState(() {
                                    // Remove from the orders list
                                    orders.removeWhere((order) => order['order_id'].toString() == orderId);
                                    
                                    // Save to completed/cancelled history
                                    _saveOrderToHistory({
                                      ...orderData,
                                      'status': frontendStatus
                                    });
                                  });
                                  
                                  // Show info message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Order #$orderId removed from timeline (status: $frontendStatus)'),
                                      backgroundColor: Colors.blue,
                                      duration: Duration(seconds: 2),
                                    )
                                  );
                                }
                              }
                            }
                          }
                          
                          // Then do a full refresh of all orders
                          await _initializeUserAndOrders();

                          // Remove any error snackbars that might be showing
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Orders refreshed successfully'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            )
                          );
                        } catch (e) {
                          print("❌ Error refreshing data: $e");
                          
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error refreshing orders: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'Retry',
                                onPressed: () => _initializeUserAndOrders(),
                                textColor: Colors.white,
                              ),
                            )
                          );
                        } finally {
                          // Clear any remaining refreshing flags
                          if (selectedOrder != null && mounted) {
                            setState(() {
                              selectedOrder!.remove('refreshing');
                              isLoading = false;
                            });
                          } else if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
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
              ? _buildNoOrdersView()
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
                                _buildOrderInfoCard(),
                                const SizedBox(height: 20),
                                _buildOrderedItems(),
                                const SizedBox(height: 20),
                                _buildOrderStatus(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // If there's no selected order but orders list is not empty, show a hint
                    if (selectedOrder == null && orders.isNotEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Please select an order from the dropdown above',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Cancel Button - only show if an order is selected
                    if (selectedOrder != null)
                      _buildCancelButton(),
                  ],
                ),
      ),
      // Add a refresh button to the bottom right to make it easier to refresh orders
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show loading indicator
          setState(() {
            isLoading = true;
          });
          
          try {
            // Clear any error snackbars
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            // First check for cancelled orders in local storage
            final prefs = await SharedPreferences.getInstance();
            final cancelledOrdersJson = prefs.getString('completed_orders') ?? '[]';
            final cancelledOrdersList = _safelyParseCancelledOrders(cancelledOrdersJson);
            final cancelledOrderIds = cancelledOrdersList
                .map((order) => order is Map ? order['order_id']?.toString() ?? '' : '')
                .where((id) => id.isNotEmpty)
                .toSet();
            
            // Check if currently selected order is in cancelled list
            if (selectedOrder != null) {
              final orderId = selectedOrder!['order_id']?.toString() ?? '';
              if (orderId.isNotEmpty) {
                if (cancelledOrderIds.contains(orderId)) {
                  print("🚫 Selected order #$orderId found in cancelled orders list - removing from timeline");
                  setState(() {
                    // Remove from orders list
                    orders.removeWhere((order) => order['order_id']?.toString() == orderId);
                    
                    // Select new order
                    if (orders.isNotEmpty) {
                      selectedOrder = orders[0];
                    } else {
                      selectedOrder = null;
                    }
                  });
                } else {
                  // Check if we have a selected order and verify its status
                  print("🔄 Checking status of selected order #$orderId");
                  
                  final orderData = await _orderService.fetchOrderById(orderId);
                  if (orderData != null) {
                    final newStatus = orderData['status']?.toString()?.toLowerCase() ?? '';
                    final frontendStatus = _convertToFrontendStatusFormat(newStatus);
                    
                    // If completed or cancelled, remove from timeline
                    if (frontendStatus == 'completed' || frontendStatus == 'cancelled' || frontendStatus == 'delivered') {
                      print("🔄 Order #$orderId is now $frontendStatus - removing from timeline");
                      
                      if (mounted) {
                        // Create safe copy for history
                        final orderDataCopy = Map<String, dynamic>.from(orderData);
                        orderDataCopy['status'] = frontendStatus;
                        
                        // Update state
                        setState(() {
                          // Remove from orders list
                          orders.removeWhere((order) => order['order_id']?.toString() == orderId);
                          
                          // Save to completed orders history if needed
                          _saveOrderToHistory(orderDataCopy);
                          
                          // Select a new order if available
                          if (orders.isNotEmpty) {
                            selectedOrder = orders[0];
                          } else {
                            selectedOrder = null;
                          }
                        });
                      }
                    }
                  }
                }
              }
            }
            
            // Force a complete refresh of all orders
            await _initializeUserAndOrders();
            
            if (mounted) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orders refreshed successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            print("❌ Error refreshing orders: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Unable to refresh orders. Please try again later.'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () => _initializeUserAndOrders(),
                    textColor: Colors.white,
                  ),
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          }
        },
        backgroundColor: kLogoGreen,
        child: const Icon(Icons.refresh, color: Colors.white),
        heroTag: 'timelineRefreshButton',
      ),
    );
  }

  Widget _buildOrderSelector() {
    // If we have no orders, return an empty container
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }
    
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Ensure we have a valid selected order
    final currentOrderId = selectedOrder?['order_id']?.toString();
    if (currentOrderId != null && !orders.any((order) => order['order_id'].toString() == currentOrderId)) {
      setState(() {
        selectedOrder = orders.isNotEmpty ? orders[0] : null;
      });
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, 
        vertical: screenWidth * 0.03
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF00).withOpacity(0.1),
            const Color(0xFF00FF00).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF00).withOpacity(0.1),
            spreadRadius: screenWidth * 0.005,
            blurRadius: screenWidth * 0.02,
            offset: Offset(0, screenWidth * 0.01),
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, 
                      color: const Color(0xFF00CC00),
                      size: screenWidth * 0.06),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      'Select an order',
                      style: TextStyle(
                        color: const Color(0xFF00CC00),
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              dropdownColor: Colors.white,
              style: TextStyle(
                color: const Color(0xFF008000),
                fontSize: screenWidth * 0.042,
                fontWeight: FontWeight.w500,
              ),
              icon: Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.04),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: const Color(0xFF00CC00),
                  size: screenWidth * 0.07,
                ),
              ),
              items: orders.map((order) {
                final orderId = order['order_id'].toString();
                return DropdownMenuItem<String>(
                  value: orderId,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: const Color(0xFF00CC00),
                            size: screenWidth * 0.05,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                            'Order #$orderId',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF008000),
                              fontSize: screenWidth * 0.038,
                            ),
                              ),
                              if (order['pickup_time'] != null)
                                Text(
                                  _formatPickupTimeToIST(order['pickup_time'].toString()),
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03, 
                            vertical: screenWidth * 0.015
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF8C00),
                                const Color(0xFFFF8C00).withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withOpacity(0.2),
                                spreadRadius: screenWidth * 0.002,
                                blurRadius: screenWidth * 0.01,
                                offset: Offset(0, screenWidth * 0.005),
                              ),
                            ],
                          ),
                          child: FoodPrice(
                            foodPrice: '₹${_getSafeOrderAmount(order).toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) async {
                if (newValue != null) {
                  // Immediately show loading to provide feedback
                  setState(() {
                    isLoading = true;
                  });
                  
                  print("🔍 Selected order #$newValue from dropdown");
                  
                  try {
                    // First, create a placeholder with the current data we have
                    // to avoid UI jumping between orders
                    final tempOrder = orders.firstWhere(
                    (order) => order['order_id'].toString() == newValue,
                      orElse: () => <String, dynamic>{},
                    );
                    
                    if (tempOrder.isNotEmpty) {
                      // Temporarily set the selected order to the one from our list
                      // while we fetch the complete data
                      setState(() {
                        selectedOrder = Map<String, dynamic>.from(tempOrder);
                      });
                    }
                    
                    // Directly fetch fresh order data from backend
                    final orderData = await _orderService.fetchOrderById(newValue);
                    
                    if (orderData != null && mounted) {
                      print("✅ Successfully fetched order #$newValue with ${(orderData['items'] as List?)?.length ?? 0} items");
                      
                      // Preserve existing data from our local cache
                      Map<String, dynamic>? existingOrder;
                      for (var order in orders) {
                        if (order['order_id'].toString() == newValue) {
                          existingOrder = order;
                          break;
                        }
                      }
                      
                      // Get items from both sources
                      final existingItems = existingOrder?['items'] as List<dynamic>? ?? [];
                      final newItems = orderData['items'] as List<dynamic>? ?? [];
                      
                      // Get total amounts from both sources
                      final existingTotalAmount = existingOrder?['total_amount'];
                      final newTotalAmount = orderData['total_amount'];
                      
                      print("💰 Total amount comparison: Existing=${existingTotalAmount}, New=${newTotalAmount}");
                      
                      // Decide which items to use - prioritize existing items if they have better data
                      final List<dynamic> mergedItems;
                      if (existingItems.isNotEmpty && (newItems.isEmpty || existingItems.length >= newItems.length)) {
                        print("📦 Using existing ${existingItems.length} items since they have more details");
                        mergedItems = List<dynamic>.from(existingItems);
                      } else if (newItems.isNotEmpty) {
                        print("📦 Using ${newItems.length} new items from backend");
                        // Create proper deep copies of the items
                        mergedItems = newItems.map((item) => {
                          'id': item['food_id']?.toString() ?? '',
                          'food_id': item['food_id']?.toString() ?? '',
                          'name': item['name']?.toString() ?? 'Unknown Item',
                          'quantity': item['quantity'] is num ? item['quantity'] : 1,
                          'price': item['price'] is num ? item['price'] : 
                                  (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
                          'total_price': item['total_price'] is num ? item['total_price'] : 
                                        (item['price'] is num && item['quantity'] is num ? 
                                          item['price'] * item['quantity'] : 0.0),
                          'total_item_price': item['total_price'] is num ? item['total_price'] : 
                                             (item['price'] is num && item['quantity'] is num ? 
                                               item['price'] * item['quantity'] : 0.0),
                          'description': item['description']?.toString() ?? '',
                          'image': item['image']?.toString() ?? '',
                          'isVeg': item['isVeg'] is bool ? item['isVeg'] : true,
                          'category': item['category']?.toString() ?? '',
                        }).toList();
                      } else {
                        // Fallback: empty list
                        mergedItems = [];
                      }
                      
                      // Decide which total_amount to use
                      var finalTotalAmount = 0.0;
                      
                      // First try to use the new total amount from API if valid
                      if (newTotalAmount != null && newTotalAmount is num && newTotalAmount > 0) {
                        finalTotalAmount = newTotalAmount.toDouble();
                      } 
                      // Then try existing total amount if available
                      else if (existingTotalAmount != null && existingTotalAmount is num && existingTotalAmount > 0) {
                        finalTotalAmount = existingTotalAmount.toDouble();
                      } 
                      // Fallback: Calculate from merged items
                      else if (mergedItems.isNotEmpty) {
                        for (var item in mergedItems) {
                          final price = item['price'] is num ? (item['price'] as num).toDouble() : 0.0;
                          final quantity = item['quantity'] is num ? (item['quantity'] as num).toInt() : 1;
                          finalTotalAmount += price * quantity;
                        }
                      }
                      
                      print("💰 Final total amount: $finalTotalAmount");
                      
                      // Create a normalized, deep-copied version of the order data
                      final normalizedOrderData = {
                        'order_id': orderData['order_id']?.toString() ?? '',
                        'otp': orderData['otp']?.toString() ?? '',
                        'payment_method': orderData['payment_method']?.toString() ?? '',
                        'pickup_time': orderData['pickup_time']?.toString() ?? '',
                        'total_amount': finalTotalAmount,
                        'status': orderData['status']?.toString()?.toLowerCase() ?? 'pending',
                        'shop_id': orderData['shop_id']?.toString() ?? '',
                        'items': mergedItems,
                      };
                      
                      // Log the final items we're using
                      print("🔍 Order #$newValue has ${mergedItems.length} items after merging");
                      for (var item in mergedItems) {
                        print("   📝 Item: ${item['name']}, price=${item['price']}, quantity=${item['quantity']}");
                      }
                      
                      if (mounted) {
                        // Update the orders list with the new data
                        bool orderFound = false;
                        final updatedOrders = List<Map<String, dynamic>>.from(orders);
                        
                        for (int i = 0; i < updatedOrders.length; i++) {
                          if (updatedOrders[i]['order_id'].toString() == newValue) {
                            updatedOrders[i] = normalizedOrderData;
                            orderFound = true;
                            break;
                          }
                        }
                        
                        // If the order isn't in our list, add it
                        if (!orderFound) {
                          updatedOrders.add(normalizedOrderData);
                        }
                        
                        // Update state with new order and possibly updated orders list
                  setState(() {
                          selectedOrder = normalizedOrderData;
                          orders = updatedOrders;
                          isLoading = false;
                        });
                        
                        // Save the updated order data to persist between sessions
                        await _saveOrderData(normalizedOrderData);
                      }
                    } else {
                      print("❌ Failed to fetch order #$newValue from backend or component unmounted");
                      
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Could not fetch order details from server"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print("❌ Error selecting order #$newValue: $e");
                    
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                      
                      // Show error to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Unable to load order details. Please try again later."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    if (selectedOrder == null) return const SizedBox.shrink();
    
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Get the price with improved safety
    final totalAmount = _getSafeOrderAmount(selectedOrder!);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, 
        vertical: screenWidth * 0.02
      ),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade100,
            Colors.green.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
            spreadRadius: screenWidth * 0.005,
            blurRadius: screenWidth * 0.02,
            offset: Offset(0, screenWidth * 0.01),
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
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03, 
                  vertical: screenWidth * 0.015
                ),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add missing methods
  Widget _buildNoOrdersView() {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: screenWidth * 0.2,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: screenWidth * 0.05),
          Text(
            'No active orders',
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'Your orders will appear here once you place them',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenWidth * 0.08),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/menu');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kLogoGreen,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenWidth * 0.03,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
            ),
            child: Text(
              'Browse Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
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
    
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ordered Items',
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: screenWidth * 0.01,
                blurRadius: screenWidth * 0.02,
                offset: Offset(0, screenWidth * 0.01),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              
              // Extract values with fallbacks
              final name = item['name']?.toString() ?? 'Unknown Item';
              final quantity = item['quantity'] is num ? item['quantity'] : 1;
              final price = item['price'] is num ? item['price'] : 0.0;
              final isVeg = item['isVeg'] == true;
              
              return Padding(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg/Non-veg indicator
                    Container(
                      margin: EdgeInsets.only(top: screenWidth * 0.01),
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isVeg ? Colors.green : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: screenWidth * 0.02,
                          height: screenWidth * 0.02,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isVeg ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: screenWidth * 0.03),
                    
                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Quantity
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenWidth * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Text(
                        'x$quantity',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    SizedBox(width: screenWidth * 0.03),
                    
                    // Total price
                    Text(
                      '₹${(price * (quantity as num)).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildOrderStatus() {
    if (selectedOrder == null) return const SizedBox.shrink();
    
    final String status = selectedOrder!['status']?.toString() ?? 'pending';
    final isCancelled = _isOrderCancelled(selectedOrder!);
    
    // If order is cancelled, show the cancellation view instead
    if (isCancelled || status == 'cancelled') {
      final cancelReason = selectedOrder!['cancel_reason']?.toString() ?? 'No reason provided';
      return _buildCancellationView(cancelReason);
    }
    
    // Get the current step based on status
    int currentStep = 1;
    if (status == 'confirmed') currentStep = 2;
    if (status == 'preparing') currentStep = 3;
    if (status == 'ready_for_pickup') currentStep = 4;
    if (status == 'completed' || status == 'delivered') currentStep = 5;
    
    // A way to trigger animation on refresh
    final isRefreshing = selectedOrder!['refreshing'] == true;
    
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status',
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        Container(
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.05,
            horizontal: screenWidth * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: screenWidth * 0.01,
                blurRadius: screenWidth * 0.02,
                offset: Offset(0, screenWidth * 0.01),
              ),
            ],
          ),
          child: Column(
            children: [
              // Step 1: Order Placed
              Timeline(
                isFirst: true,
                isLast: false,
                isPast: currentStep >= 1,
                orderNumber: selectedOrder!['order_id']?.toString() ?? '',
                animatedOrders: animatedOrders,
                isRefreshing: isRefreshing && currentStep == 1,
                eventCard: EventCard(
                  title: 'Order Placed',
                  subtitle: 'Your order has been received',
                  time: 'Step 1',
                ),
              ),
              
              // Step 2: Order Confirmed
              Timeline(
                isFirst: false,
                isLast: false,
                isPast: currentStep >= 2,
                orderNumber: selectedOrder!['order_id']?.toString() ?? '',
                animatedOrders: animatedOrders,
                isRefreshing: isRefreshing && currentStep == 2,
                eventCard: EventCard(
                  title: 'Order Confirmed',
                  subtitle: 'Your order has been confirmed by the canteen',
                  time: 'Step 2',
                ),
              ),
              
              // Step 3: Preparing
              Timeline(
                isFirst: false,
                isLast: false,
                isPast: currentStep >= 3,
                orderNumber: selectedOrder!['order_id']?.toString() ?? '',
                animatedOrders: animatedOrders,
                isRefreshing: isRefreshing && currentStep == 3,
                eventCard: EventCard(
                  title: 'Preparing',
                  subtitle: 'The canteen is preparing your food',
                  time: 'Step 3',
                ),
              ),
              
              // Step 4: Ready for Pickup
              Timeline(
                isFirst: false,
                isLast: false,
                isPast: currentStep >= 4,
                orderNumber: selectedOrder!['order_id']?.toString() ?? '',
                animatedOrders: animatedOrders,
                isRefreshing: isRefreshing && currentStep == 4,
                eventCard: EventCard(
                  title: 'Ready for Pickup',
                  subtitle: 'Your food is ready for pickup',
                  time: 'Step 4',
                ),
              ),
              
              // Step 5: Completed
              Timeline(
                isFirst: false,
                isLast: true,
                isPast: currentStep >= 5,
                orderNumber: selectedOrder!['order_id']?.toString() ?? '',
                animatedOrders: animatedOrders,
                isRefreshing: isRefreshing && currentStep == 5,
                eventCard: EventCard(
                  title: 'Completed',
                  subtitle: 'You have received your order',
                  time: 'Step 5',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCancelButton() {
    if (selectedOrder == null) return const SizedBox.shrink();
    
    final String status = selectedOrder!['status']?.toString().toLowerCase() ?? 'pending';
    
    // Don't show cancel button for completed or already cancelled orders
    if (status == 'completed' || status == 'cancelled' || status == 'delivered' || 
        _isOrderCancelled(selectedOrder!)) {
      return const SizedBox.shrink();
    }
    
    // Don't show cancel button for orders that have progressed beyond 'confirmed'
    if (status != 'pending' && status != 'confirmed') {
      return const SizedBox.shrink();
    }
    
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: screenWidth * 0.01,
            blurRadius: screenWidth * 0.02,
            offset: Offset(0, -screenWidth * 0.01),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _showCancellationModal();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade500,
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
        ),
        child: Text(
          'Cancel Order',
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  void _showCancellationModal() {
    if (selectedOrder == null) return;
    
    final orderId = selectedOrder!['order_id'].toString();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CancelReasonSheet(
        orderId: orderId,
        onConfirm: (reason) {
          _cancelOrder(reason);
        },
      ),
    );
  }
  
  void _cancelOrder(String reason) async {
    if (selectedOrder == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    final orderId = selectedOrder!['order_id'].toString();
    
    try {
      print("🚫 Cancelling order #$orderId. Reason: $reason");
      final result = await _orderService.cancelOrder(orderId, reason);
      
      if (result) {
        print("✅ Order cancelled successfully");
        
        // Update our local data
        setState(() {
          // Mark as cancelled in the current selected order
          selectedOrder!['status'] = 'cancelled';
          selectedOrder!['is_cancelled'] = true;
          selectedOrder!['cancel_reason'] = reason;
          selectedOrder!['cancelled_at'] = DateTime.now().toIso8601String();
          
          // Save to history
          _saveCancelledOrderToHistory(selectedOrder!);
          
          // Remove from orders list
          orders.removeWhere((order) => order['order_id'].toString() == orderId);
          
          // Update selectedOrder
          if (orders.isNotEmpty) {
            selectedOrder = orders[0];
          } else {
            selectedOrder = null;
          }
          
          // Update provider
          final foodMenu = Provider.of<FoodMenu>(context, listen: false);
          foodMenu.markOrderAsCancelled(orderId, reason);
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // If no orders left, refresh the screen
        if (orders.isEmpty) {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("❌ Failed to cancel order");
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error cancelling order: $e");
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to mark an order as deleted in storage to prevent it from reappearing
  Future<void> _markOrderAsDeletedInStorage(String orderId) async {
    try {
      print("🚫 Marking order #$orderId as deleted in storage");
      
      // Create a placeholder deleted order
      final deletedOrder = {
        'order_id': orderId,
        'status': 'cancelled',
        'is_cancelled': true,
        'cancel_reason': 'Order deleted from database',
        'cancelled_at': DateTime.now().toIso8601String(),
      };
      
      // Save to cancelled orders history
      await _saveCancelledOrderToHistory(deletedOrder);
      
      // Also update the FoodMenu provider
      final foodMenu = Provider.of<FoodMenu>(context, listen: false);
      await foodMenu.markOrderAsCancelled(orderId, 'Order deleted from database');
      
      print("✅ Successfully marked order #$orderId as deleted in storage");
    } catch (e) {
      print("❌ Error marking order #$orderId as deleted: $e");
    }
  }

  // Add a method to build cancellation view
  Widget _buildCancellationView(String reason) {
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
                  Colors.red.shade50,
                  Colors.red.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const Spacer(),
                Icon(Icons.cancel_outlined, color: Colors.red.shade800),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This order has been cancelled.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Cancellation Reason:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can place a new order from the menu screen.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/menu');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  // Helper method to safely parse cancelled orders from SharedPreferences
  List<dynamic> _safelyParseCancelledOrders(String jsonString) {
    try {
      final decodedJson = json.decode(jsonString);
      if (decodedJson is List) {
        return decodedJson;
      } else if (decodedJson is Map) {
        return [decodedJson];
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Error decoding cancelled orders: $e");
      return [];
    }
  }

  // Helper function to safely get total amount
  double _getSafeOrderAmount(Map<String, dynamic>? order) {
    if (order == null) return 0.0;
    
    // First try to get from total_amount field
    if (order['total_amount'] != null) {
      final totalAmount = order['total_amount'];
      if (totalAmount is num && totalAmount > 0) {
        return totalAmount.toDouble();
      }
    }
    
    // If not available or zero, try to calculate from items
    final items = order['items'] as List<dynamic>? ?? [];
    double calculatedTotal = 0.0;
    
    if (items.isEmpty) {
      // No items available, return 0
      return 0.0;
    }
    
    // Calculate from items
    for (var item in items) {
      if (item is Map) {
        // Extract quantity, default to 1 if not available
        final quantity = item['quantity'] is num 
            ? (item['quantity'] as num).toInt() 
            : (item['quantity'] is String 
                ? int.tryParse(item['quantity']) ?? 1 
                : 1);
                
        // Extract price, default to 0 if not available
        final price = item['price'] is num 
            ? (item['price'] as num).toDouble() 
            : (item['price'] is String 
                ? double.tryParse(item['price']) ?? 0.0 
                : 0.0);
                
        // Add to total
        calculatedTotal += price * quantity;
      }
    }
    
    return calculatedTotal > 0 ? calculatedTotal : 0.0;
  }
  
  // Save order to history when completed or cancelled
  Future<void> _saveOrderToHistory(Map<String, dynamic> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderId = order['order_id']?.toString() ?? '';
      
      if (orderId.isEmpty) {
        print("⚠️ Cannot save order with empty ID to history");
        return;
      }
      
      print("💾 Saving order #$orderId to history");
      
      // Add timestamp if missing
      final Map<String, dynamic> orderCopy = Map<String, dynamic>.from(order);
      
      // Ensure shop name is set if we have shop_id
      if ((orderCopy['shop_name'] == null || orderCopy['shop_name'].toString().isEmpty) && 
         orderCopy['shop_id'] != null && orderCopy['shop_id'].toString().isNotEmpty) {
         final shopId = orderCopy['shop_id'].toString();
         try {
           // Try to get shop name from provider
           final foodMenu = Provider.of<FoodMenu>(context, listen: false);
           orderCopy['shop_name'] = foodMenu.getShopNameById(shopId);
           print("🏪 Adding shop name '${orderCopy['shop_name']}' for shop ID $shopId to history order");
         } catch (e) {
           print("❌ Error getting shop name for shop ID $shopId: $e");
           orderCopy['shop_name'] = 'Shop #$shopId';
         }
      }
      
      if (!orderCopy.containsKey('completed_at') && !orderCopy.containsKey('cancelled_at')) {
        orderCopy['completed_at'] = DateTime.now().toIso8601String();
      }
      
      // First try to get existing completed orders
      final String? completedOrdersString = prefs.getString('completed_orders');
      List<Map<String, dynamic>> completedOrders = [];
      
      if (completedOrdersString != null && completedOrdersString.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(completedOrdersString);
          completedOrders = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        } catch (e) {
          print("⚠️ Error parsing completed orders: $e");
          // Continue with empty list if parsing fails
        }
      }
      
      // Check if this order is already in the completed orders
      final existingIndex = completedOrders.indexWhere(
        (order) => order['order_id']?.toString() == orderId
      );
      
      if (existingIndex >= 0) {
        // Update existing entry
        completedOrders[existingIndex] = orderCopy;
        print("🔄 Updated existing order #$orderId in completed_orders");
      } else {
        // Add new entry
        completedOrders.add(orderCopy);
        print("➕ Added order #$orderId to completed_orders");
      }
      
      // Save back to shared preferences
      await prefs.setString('completed_orders', json.encode(completedOrders));
      print("💾 Saved updated completed_orders with ${completedOrders.length} orders");
      
      // Update all_orders list too to ensure consistency
      final String? allOrdersString = prefs.getString('all_orders');
      if (allOrdersString != null && allOrdersString.isNotEmpty) {
        try {
          final List<dynamic> allOrders = json.decode(allOrdersString);
          bool updated = false;
          
          // Find and update the order in all_orders
          for (int i = 0; i < allOrders.length; i++) {
            if (allOrders[i] is Map && 
                allOrders[i]['order_id']?.toString() == orderId) {
              allOrders[i] = orderCopy;
              updated = true;
              break;
            }
          }
          
          // If not found, add it
          if (!updated && orderCopy.isNotEmpty) {
            allOrders.add(orderCopy);
          }
          
          // Save back to shared preferences
          await prefs.setString('all_orders', json.encode(allOrders));
          print("💾 Updated order #$orderId in all_orders");
        } catch (e) {
          print("⚠️ Error updating all_orders: $e");
        }
      }
    } catch (e) {
      print("❌ Error saving order to history: $e");
    }
  }
  
  // Save order data to SharedPreferences
  Future<void> _saveOrderDataToPrefs() async {
    try {
      if (!mounted) return;
      
      // Make a deep copy of all orders to ensure all nested data is preserved
      final List<Map<String, dynamic>> ordersCopy = [];
      
      for (var order in orders) {
        if (order == null) continue;
        
        try {
          final orderCopy = Map<String, dynamic>.from(order);
          final items = order['items'] as List<dynamic>? ?? [];
          
          if (items.isNotEmpty) {
            orderCopy['items'] = items.map((item) {
              if (item == null) return <String, dynamic>{};
              
              try {
                return {
                  'id': item['id']?.toString() ?? '',
                  'food_id': item['food_id']?.toString() ?? item['id']?.toString() ?? '',
                  'name': item['name']?.toString() ?? 'Unknown Item',
                  'quantity': item['quantity'] is int ? item['quantity'] : 
                           (item['quantity'] is String ? int.tryParse(item['quantity']) ?? 1 : 1),
                  'price': item['price'] is num ? item['price'] : 
                          (item['price'] is String ? double.tryParse(item['price']) ?? 0.0 : 0.0),
                  'total_price': item['total_price'] is num ? item['total_price'] :
                                (item['total_item_price'] is num ? item['total_item_price'] : 
                                 (item['price'] is num && item['quantity'] is num ? 
                                  (item['price'] as num) * (item['quantity'] as num) : 0.0)),
                  'total_item_price': item['total_item_price'] is num ? item['total_item_price'] :
                                     (item['total_price'] is num ? item['total_price'] : 
                                      (item['price'] is num && item['quantity'] is num ? 
                                       (item['price'] as num) * (item['quantity'] as num) : 0.0)),
                  'description': item['description']?.toString() ?? '',
                  'image': item['image']?.toString() ?? '',
                  'isVeg': item['isVeg'] is bool ? item['isVeg'] : true,
                  'category': item['category']?.toString() ?? '',
                };
              } catch (e) {
                print("❌ Error processing order item: $e");
                return <String, dynamic>{};
              }
            }).toList();
          }
          ordersCopy.add(orderCopy);
        } catch (e) {
          print("❌ Error processing order: $e");
          // Skip this order if it causes an error
        }
      }
      
      if (ordersCopy.isEmpty && orders.isNotEmpty) {
        print("⚠️ Warning: All orders were skipped due to processing errors");
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('all_orders', json.encode(ordersCopy));
      print("💾 Saved ${ordersCopy.length} orders with their items to SharedPreferences");
    } catch (e) {
      print("❌ Error saving order data: $e");
    }
  }
  
  // Helper to safely parse cancelled orders
  List<dynamic> _safelyParseCancelledOrders(String json) {
    try {
      return jsonDecode(json);
    } catch (e) {
      print("❌ Error parsing cancelled orders JSON: $e");
      return [];
    }
  }
  
  // Save cancelled order to history storage
  Future<void> _saveCancelledOrderToHistory(Map<String, dynamic> cancelledOrder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderId = cancelledOrder['order_id']?.toString() ?? '';
      
      if (orderId.isEmpty) {
        print("⚠️ Cannot save cancelled order with empty ID to history");
        return;
      }
      
      print("💾 Saving cancelled order #$orderId to history");
      
      // First try to get existing completed orders
      final String? completedOrdersString = prefs.getString('completed_orders');
      List<Map<String, dynamic>> completedOrders = [];
      
      if (completedOrdersString != null && completedOrdersString.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(completedOrdersString);
          completedOrders = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        } catch (e) {
          print("⚠️ Error parsing completed orders: $e");
          // Continue with empty list if parsing fails
        }
      }
      
      // Check if this order is already in the completed orders
      final existingIndex = completedOrders.indexWhere(
        (order) => order['order_id']?.toString() == orderId
      );
      
      // Make sure status is set to 'cancelled'
      final Map<String, dynamic> cancelledOrderCopy = Map<String, dynamic>.from(cancelledOrder);
      cancelledOrderCopy['status'] = 'cancelled';
      
      // Add timestamp if missing
      if (!cancelledOrderCopy.containsKey('cancelled_at')) {
        cancelledOrderCopy['cancelled_at'] = DateTime.now().toIso8601String();
      }
      
      // Add is_cancelled flag explicitly
      cancelledOrderCopy['is_cancelled'] = true;
      
      if (existingIndex >= 0) {
        // Update existing entry
        completedOrders[existingIndex] = cancelledOrderCopy;
        print("🔄 Updated existing order #$orderId in completed_orders");
      } else {
        // Add new entry
        completedOrders.add(cancelledOrderCopy);
        print("➕ Added cancelled order #$orderId to completed_orders");
      }
      
      // Save back to shared preferences
      await prefs.setString('completed_orders', json.encode(completedOrders));
      print("💾 Saved updated completed_orders with ${completedOrders.length} orders");
      
      // Update all_orders list too to ensure consistency
      final String? allOrdersString = prefs.getString('all_orders');
      if (allOrdersString != null && allOrdersString.isNotEmpty) {
        try {
          final List<dynamic> allOrders = json.decode(allOrdersString);
          bool updated = false;
          
          // Find and update the order in all_orders
          for (int i = 0; i < allOrders.length; i++) {
            if (allOrders[i] is Map && 
                allOrders[i]['order_id']?.toString() == orderId) {
              allOrders[i]['status'] = 'cancelled';
              allOrders[i]['cancel_reason'] = cancelledOrderCopy['cancel_reason'];
              allOrders[i]['cancelled_at'] = cancelledOrderCopy['cancelled_at'];
              allOrders[i]['is_cancelled'] = true;
              updated = true;
              break;
            }
          }
          
          // If not found, add it
          if (!updated && cancelledOrderCopy.isNotEmpty) {
            allOrders.add(cancelledOrderCopy);
          }
          
          // Save back to shared preferences
          await prefs.setString('all_orders', json.encode(allOrders));
          print("💾 Updated order #$orderId status in all_orders");
        } catch (e) {
          print("⚠️ Error updating all_orders: $e");
        }
      }
      
      // Only modify state if component is still mounted
      if (mounted) {
        // Remove from active orders list in memory immediately
        setState(() {
          print("🗑️ Removing cancelled order #$orderId from timeline view");
          
          // Remove the order from the active orders list
          final int beforeRemoveCount = orders.length;
          orders.removeWhere((order) => order['order_id']?.toString() == orderId);
          final int afterRemoveCount = orders.length;
          
          if (beforeRemoveCount == afterRemoveCount) {
            print("⚠️ Warning: Order #$orderId was not found in the orders list for removal");
          } else {
            print("✅ Successfully removed order #$orderId from timeline (${beforeRemoveCount} → ${afterRemoveCount} orders)");
          }
          
          // If this was the selected order, select another one or clear
          if (selectedOrder != null && selectedOrder!['order_id']?.toString() == orderId) {
            print("🔄 Selected order was cancelled - selecting a new order");
            if (orders.isNotEmpty) {
              selectedOrder = Map<String, dynamic>.from(orders[0]); // Create a copy to avoid reference issues
              print("🔍 Selected new order #${selectedOrder!['order_id']}");
            } else {
              selectedOrder = null;
              print("ℹ️ No orders remaining - cleared selection");
            }
          }
        });
        
        // Force refresh data to get updated UI
        _saveOrderDataToPrefs();
        
        // If we have no more orders, ensure a clean view
        if (orders.isEmpty) {
          // Wait a moment to let the setState above complete
          Future.microtask(() {
            if (mounted) {
              setState(() {
                // Confirm selectedOrder is null
                selectedOrder = null;
                // Ensure loading is complete
                isLoading = false;
              });
            }
          });
        }
      }
      
    } catch (e) {
      print("❌ Error saving cancelled order to history: $e");
    }
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




