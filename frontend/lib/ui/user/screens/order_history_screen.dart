import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../food_menu.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../models/titles.dart';
import 'package:http/http.dart' as http;

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
        try {
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
        
          // Ensure shop name is available
          if (order['shop_name'] == null || order['shop_name'].toString().isEmpty || order['shop_name'] == 'Unknown Shop') {
              final shopId = order['shop_id']?.toString();
              if (shopId != null && shopId.isNotEmpty) {
                // Try to get shop name from provider
                final shopName = await _getShopName(shopId, foodMenu);
                if (shopName != null && shopName.isNotEmpty) {
                order['shop_name'] = shopName;
                  print("🏪 Added shop name '$shopName' for order #$orderId");
              }
            }
          }
        }
        
          // Separate into completed and cancelled orders
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
      
      setState(() {
        _isLoading = false;
      });
      
      print("📋 Final result: ${_completedOrders.length} completed orders and ${_cancelledOrders.length} cancelled orders");
        } catch (e) {
          print("❌ Error processing order data: $e");
          setState(() {
            _isLoading = false;
            _errorMessage = "Error processing order data. Please try again.";
          });
        }
      } else {
        print("⚠️ No completed orders found in SharedPreferences");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error loading order history: $e");
      String errorMessage = "Error loading order history";
      
      if (e.toString().contains("SocketException")) {
        errorMessage = "Network error. Please check your internet connection and try again.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "Connection timed out. Please try again.";
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    }
  }

  Future<String?> _getShopName(String shopId, FoodMenu foodMenu) async {
    // First try to get from FoodMenu provider
    final shopName = foodMenu.getShopNameById(shopId);
    if (shopName != null && shopName.isNotEmpty && shopName != 'Unknown Shop') {
      return shopName;
    }

    // If not found in provider, try to fetch from backend
    try {
      final baseUrl = dotenv.env['API_BASE_URL'];
      if (baseUrl == null) throw Exception('API_BASE_URL not found in environment variables');

      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['name'] != null) {
          return data['name'].toString();
        }
      }
    } catch (e) {
      print('❌ Error fetching shop name from backend: $e');
    }

    return null;
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

  // Add this helper function to handle image URLs
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Titles(
          title: 'Order History',
          color: Colors.white,
        ),
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
      child: Container(
        padding: const EdgeInsets.all(24.0),
        margin: const EdgeInsets.all(16.0),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage?.contains("Network error") == true
                ? Icons.wifi_off_rounded
                : Icons.error_outline_rounded,
              color: Colors.red[300],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrderHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kLogoGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/menu');
              },
              child: Text(
                'Return to Menu',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
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
            SubTitles(
              title: 'No ${type} orders found',
                color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Description(
              description: type == 'completed'
                  ? 'Your completed orders will appear here'
                  : 'Your cancelled orders will appear here',
                color: Colors.grey[500],
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
    final orderId = order['order_id'] ?? 'Unknown';
    final amount = _getSafeOrderAmount(order);
        final shopId = order['shop_id']?.toString();
        final foodMenu = Provider.of<FoodMenu>(context, listen: false);
    String shopName = order['shop_name']?.toString() ?? 'Unknown Shop';
    
        // Try to get shop name from FoodMenu if not available in order data
        if (shopName == 'Unknown Shop' && shopId != null) {
          final menuShopName = foodMenu.getShopNameById(shopId);
          if (menuShopName != null && menuShopName.isNotEmpty) {
            shopName = menuShopName;
            // Update the order data with the shop name
            order['shop_name'] = shopName;
          }
        }
        
        final orderDate = _parseDate(order);
        final dateStr = DateFormat('MMM d, yyyy - h:mm a').format(orderDate);
    final cancelReason = order['cancel_reason']?.toString();
    final isCancelled = type == 'cancelled' || order['is_cancelled'] == true;
        final items = order['items'] as List<dynamic>? ?? [];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isCancelled ? Colors.red.shade50 : Colors.green.shade50,
              child: Icon(
                isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
                color: isCancelled ? Colors.red : Colors.green,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                    'Order #$orderId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        shopName,
                    style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                    ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
              children: [
              if (isCancelled && cancelReason != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cancelled: $cancelReason',
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final itemPrice = (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
                  final imageUrl = getFullImageUrl(item['image']);
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.fastfood, color: Colors.grey[400]),
                                );
                              },
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: Icon(Icons.fastfood, color: Colors.grey[400]),
                            ),
                  ),
                    title: Text(
                      item['name']?.toString() ?? 'Unknown Item',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                    subtitle: Text(
                      '${item['quantity']} × ₹${item['price']?.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      '₹${itemPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCancelled ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCancelled ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ],
            ),
          );
      },
    );
  }
} 