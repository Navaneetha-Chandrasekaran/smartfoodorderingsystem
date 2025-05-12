import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../food_menu.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _cancelledOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrderHistory();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final foodMenu = Provider.of<FoodMenu>(context, listen: false);
      
      // Load completed orders from SharedPreferences
      final String? completedOrdersString = prefs.getString('completed_orders');
      
      print("🔄 Loading order history from SharedPreferences");
      
      if (completedOrdersString != null && completedOrdersString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(completedOrdersString);
        final allOrders = decoded
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
            .toList();
        
        print("📋 Loaded ${allOrders.length} total orders from completed_orders storage");
        
        // Debug log all orders status
        for (var order in allOrders) {
          final orderId = order['order_id']?.toString() ?? 'unknown';
          final status = order['status']?.toString()?.toLowerCase() ?? 'unknown';
          final isCancelled = order['is_cancelled'] == true;
          final hasReason = order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty;
          
          print("📊 Order #$orderId - Status: $status, Is Cancelled: $isCancelled, Has Reason: $hasReason");
        }
        
        // Enhance each order with additional info if needed
        for (var order in allOrders) {
          // Ensure shop name is available
          if (order['shop_name'] == null || order['shop_name'].toString().isEmpty || order['shop_name'] == 'Unknown Shop') {
            final shopId = order['shop_id']?.toString() ?? '';
            if (shopId.isNotEmpty) {
              // Get shop name from provider
              final shopName = foodMenu.getShopNameById(shopId);
              if (shopName != null) {
                order['shop_name'] = shopName;
                print("🏪 Added missing shop name '$shopName' for order #${order['order_id']}");
              }
            }
          }
        }
        
        // Separate into completed and cancelled orders - handle case insensitively
        _completedOrders = allOrders
            .where((order) => 
                ((order['status']?.toString()?.toLowerCase() == 'completed' || 
                order['status']?.toString()?.toLowerCase() == 'delivered') &&
                !(order['is_cancelled'] == true)) &&
                !(order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty)
            )
            .toList();
        
        _cancelledOrders = allOrders
            .where((order) => 
                order['status']?.toString()?.toLowerCase() == 'cancelled' || 
                order['is_cancelled'] == true ||
                (order['cancel_reason'] != null && order['cancel_reason'].toString().isNotEmpty)
            )
            .toList();
        
        print("📊 Categorized orders: ${_completedOrders.length} completed, ${_cancelledOrders.length} cancelled");
        
        // Debug log cancelled orders
        for (var order in _cancelledOrders) {
          final orderId = order['order_id']?.toString() ?? 'unknown';
          final reason = order['cancel_reason']?.toString() ?? 'No reason provided';
          print("🚫 Cancelled order #$orderId - Reason: $reason");
        }
        
        // Sort by date (newest first)
        _completedOrders.sort((a, b) {
          final dateA = _parseDate(a);
          final dateB = _parseDate(b);
          return dateB.compareTo(dateA);
        });
        
        _cancelledOrders.sort((a, b) {
          final dateA = _parseDate(a);
          final dateB = _parseDate(b);
          return dateB.compareTo(dateA);
        });
        
        // Save updated data back to shared preferences to persist shop names
        await prefs.setString('completed_orders', json.encode([..._completedOrders, ..._cancelledOrders]));
      } else {
        print("⚠️ No completed orders found in SharedPreferences");
      }
      
      setState(() {
        _isLoading = false;
      });
      
      print("📋 Final result: ${_completedOrders.length} completed orders and ${_cancelledOrders.length} cancelled orders");
    } catch (e) {
      print("❌ Error loading order history: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Error loading order history: $e";
      });
    }
  }
  
  DateTime _parseDate(Map<String, dynamic> order) {
    // Try to get date from different possible fields
    String? dateStr = order['completed_at'] ?? 
                     order['cancelled_at'] ?? 
                     order['delivered_at'] ?? 
                     order['created_at'] ?? 
                     order['updated_at'];
    
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print("⚠️ Error parsing date: $dateStr");
      }
    }
    
    // Default to current date if no valid date is found
    return DateTime.now();
  }
  
  double _getSafeOrderAmount(Map<String, dynamic> order) {
    // First try to get the total amount directly
    if (order['total_amount'] is num) {
      return (order['total_amount'] as num).toDouble();
    }
    
    // If that doesn't work, try to parse it as a string
    if (order['total_amount'] is String) {
      final parsed = double.tryParse(order['total_amount'] as String);
      if (parsed != null) return parsed;
    }
    
    // If still not available, calculate from items if possible
    final items = order['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      double total = 0.0;
      
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          final quantity = item['quantity'] is num 
              ? (item['quantity'] as num).toInt() 
              : (int.tryParse(item['quantity']?.toString() ?? '') ?? 1);
          
          final itemPrice = item['price'] is num 
              ? (item['price'] as num).toDouble() 
              : (double.tryParse(item['price']?.toString() ?? '') ?? 0.0);
          
          total += quantity * itemPrice;
        }
      }
      
      return total;
    }
    
    // Last resort: return 0
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: kLogoGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildOrderHistoryContent(screenWidth),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOrderHistory,
        backgroundColor: kLogoGreen,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kLogoGreen),
          SizedBox(height: 16),
          Text(
            'Loading order history...',
            style: TextStyle(color: kLogoGreen, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrderHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kLogoGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderHistoryContent(double screenWidth) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Completed Orders Tab
        _buildOrdersList(_completedOrders, 'completed', screenWidth),
        
        // Cancelled Orders Tab
        _buildOrdersList(_cancelledOrders, 'cancelled', screenWidth),
      ],
    );
  }
  
  Widget _buildOrdersList(List<Map<String, dynamic>> orders, String type, double screenWidth) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'completed' ? Icons.assignment_turned_in_outlined : Icons.cancel_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'completed'
                  ? 'Your completed orders will appear here'
                  : 'Your cancelled orders will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index], type, screenWidth),
    );
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order, String type, double screenWidth) {
    final orderId = order['order_id'] ?? 'Unknown';
    final amount = _getSafeOrderAmount(order);
    
    // Get shop name (if available)
    String shopName = order['shop_name']?.toString() ?? 'Unknown Shop';
    
    // Format date
    DateTime orderDate = _parseDate(order);
    String dateStr = DateFormat('MMM d, yyyy - h:mm a').format(orderDate);
    
    // Get cancel reason if applicable
    final cancelReason = order['cancel_reason']?.toString();
    final isCancelled = type == 'cancelled' || order['is_cancelled'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCancelled ? Colors.red.shade50 : kLogoGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCancelled ? Icons.cancel_outlined : Icons.check_circle_outlined,
                  color: isCancelled ? Colors.red : kLogoGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #$orderId',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.red.shade800 : kLogoGreen,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.red.shade100 : kLogoGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.red.shade800 : kLogoGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Order details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, size: 18, color: isCancelled ? Colors.red.shade300 : kLogoGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shopName,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                // Show cancellation reason if cancelled
                if (isCancelled && cancelReason != null && cancelReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Cancellation Reason:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cancelReason,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Order items
                _buildOrderItems(order, screenWidth),
                
                const SizedBox(height: 16),
                
                // Order status label
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCancelled ? 'Cancelled' : 'Completed',
                    style: TextStyle(
                      color: isCancelled ? Colors.red.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
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
  
  Widget _buildOrderItems(Map<String, dynamic> order, double screenWidth) {
    final items = order['items'] as List<dynamic>?;
    
    if (items == null || items.isEmpty) {
      return const Text(
        'No items available',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Items',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.take(3).map<Widget>((item) {
          if (item is! Map<String, dynamic>) {
            return const SizedBox();
          }
          
          final name = item['name']?.toString() ?? 'Unknown Item';
          final quantity = item['quantity'] is num 
              ? (item['quantity'] as num).toInt() 
              : (int.tryParse(item['quantity']?.toString() ?? '') ?? 1);
          
          final price = item['price'] is num 
              ? (item['price'] as num).toDouble() 
              : (double.tryParse(item['price']?.toString() ?? '') ?? 0.0);
          
          final totalPrice = quantity * price;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$quantity×',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: screenWidth * 0.5,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        // Show "more items" if there are more than 3
        if (items.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${items.length - 3} more items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
} 