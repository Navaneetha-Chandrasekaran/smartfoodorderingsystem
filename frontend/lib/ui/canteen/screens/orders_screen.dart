import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/titles.dart';
import '../../../services/auth/login_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../services/shop_service.dart';
import '../../../services/utils.dart';
import '../../../models/constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _completedOrders = [];
  final Map<String, bool> _expandedOrders = {};
  String? _currentShopId;
  String? _errorMessage;
  final DateFormat _dateFormat = DateFormat('dd MMM, hh:mm a (\'IST\')');

  @override
  void initState() {
    super.initState();
    _fetchCompletedOrders();
  }

  // Format datetime string to IST
  String _formatDateTime(String dateTimeStr) {
    try {
      // Parse the date time string as UTC
      DateTime dateTime = DateTime.parse(dateTimeStr);
      
      // Convert to IST (UTC+5:30)
      final istOffset = const Duration(hours: 5, minutes: 30);
      final istDateTime = dateTime.toUtc().add(istOffset);
      
      // Format the date and time in IST format
      return _dateFormat.format(istDateTime);
    } catch (e) {
      // Return the original if parsing fails
      print("❌ Error formatting datetime to IST: $e");
      return dateTimeStr;
    }
  }

  Future<void> _fetchCompletedOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get shop ID from storage
      final shopService = ShopService();
      _currentShopId = await shopService.getStoredShopId();

      if (_currentShopId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Shop ID not found. Please log in again.";
        });
        return;
      }

      // Prepare API URL
      final baseUrl = dotenv.env['API_BASE_URL'];
      final host = dotenv.env['API_HOST'] ?? '10.0.2.2:5000';
      final isSecure = dotenv.env['API_USE_HTTPS'] == 'true';

      final url = baseUrl != null
          ? Uri.parse('$baseUrl/orders/pastorder/$_currentShopId')
          : (isSecure
              ? Uri.https(host, '/api/orders/pastorder/$_currentShopId')
              : Uri.http(host, '/api/orders/pastorder/$_currentShopId'));

      print("🔄 Fetching completed orders from: $url");

      // Get auth headers
      final headers = await AuthService.getAuthHeaders();

      // Make API request
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("✅ Fetched ${data.length} completed orders");

        // Group items by order_id
        final Map<String, List<Map<String, dynamic>>> orderItemsMap = {};
        for (var item in data) {
          final orderId = item['order_id']?.toString() ?? item['id']?.toString() ?? '';
          orderItemsMap.putIfAbsent(orderId, () => []);
          orderItemsMap[orderId]!.add({
            'id': item['food_id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'quantity': item['quantity'] ?? 1,
            'price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
            'description': item['description']?.toString() ?? '',
            'image': item['image']?.toString() ?? '',
          });
        }

        // Build orders list
        final List<Map<String, dynamic>> orders = [];
        final Set<String> processedOrderIds = {};

        for (var item in data) {
          final orderId = item['order_id']?.toString() ?? item['id']?.toString() ?? '';
          if (processedOrderIds.contains(orderId)) continue;
          processedOrderIds.add(orderId);

          final orderItems = orderItemsMap[orderId] ?? [];
          double totalAmount = 0;
          for (var item in orderItems) {
            totalAmount += (item['price'] as double) * (item['quantity'] as int);
          }

          orders.add({
            'order_id': orderId,
            'user_id': item['user_id'],
            'pickup_time': item['pickup_time'],
            'payment_method': item['payment_method'],
            'total_amount': totalAmount,
            'otp': item['otp'],
            'status': item['status'],
            'items': orderItems,
          });
        }

        // Sort orders by newest first
        orders.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['pickup_time'].toString());
            final dateB = DateTime.parse(b['pickup_time'].toString());
            return dateB.compareTo(dateA); // Newest first
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          _completedOrders = orders;
          // Initialize all orders as collapsed
          for (var order in orders) {
            _expandedOrders[order['order_id'].toString()] = false;
          }
          _isLoading = false;
        });
      } else {
        print("❌ Error fetching completed orders: ${response.statusCode}");
        print("Response body: ${response.body}");
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load completed orders (${response.statusCode})";
        });
      }
    } catch (e) {
      print("❌ Exception fetching completed orders: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Center(child: SubTitles(title:'Completed Orders', color: Colors.white)),
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
                      onPressed: _fetchCompletedOrders,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  Description(
                    description: "Loading orders...",
                    color: Colors.grey[600],
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Description(
                        description: _errorMessage!,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchCompletedOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Description(
                          description: "Try Again",
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                )
              : _completedOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          SubTitles(
                            title: "No completed orders yet!",
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    )
                  : _buildOrdersContent(),
    );
  }

  Widget _buildOrdersContent() {
    return Column(
      children: [
        // Highlight title section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.teal.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SubTitles(
                    title: "Completed Orders",
                  ),
                  const SizedBox(height: 2),
                  FoodDescription(
                    description: "Past order history of the canteen",
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildOrderSummary(),
        _buildFilterAndSort(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            itemCount: _completedOrders.length,
            itemBuilder: (context, index) {
              return _buildCompactOrderCard(_completedOrders[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSort() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Expanded(
            child: FoodDescription(
              description: 'Showing ${_completedOrders.length} orders',
              color: Colors.grey[700],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.unfold_more, size: 16),
            label: FoodDescription(
              description: 'Expand All',
              color: Colors.teal,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              setState(() {
                for (var orderId in _expandedOrders.keys) {
                  _expandedOrders[orderId] = true;
                }
              });
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.unfold_less, size: 16),
            label: FoodDescription(
              description: 'Collapse',
              color: Colors.teal,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              setState(() {
                for (var orderId in _expandedOrders.keys) {
                  _expandedOrders[orderId] = false;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final totalOrders = _completedOrders.length;
    final totalRevenue = _completedOrders.fold<double>(
      0,
      (sum, order) => sum + (order['total_amount'] as double),
    );
    final totalItems = _completedOrders.fold<int>(
      0,
      (sum, order) => sum + (order['items'] as List).length,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.teal.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAnimatedSummaryCard(
            "Total Orders",
            "$totalOrders",
            Icons.receipt_long,
            Colors.blue,
            screenWidth,
          ),
          _buildAnimatedSummaryCard(
            "Total Items",
            "$totalItems",
            Icons.shopping_bag,
            Colors.amber,
            screenWidth,
          ),
          _buildAnimatedSummaryCard(
            "Revenue",
            "₹${totalRevenue.toStringAsFixed(0)}",
            Icons.currency_rupee,
            Colors.green,
            screenWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSummaryCard(String title, String value, IconData icon, Color color, double screenWidth) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: screenWidth * 0.26,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            FoodDescription(
              description: title,
              color: Colors.grey[800],
            ),
            const SizedBox(height: 2),
            FoodPrice(
              foodPrice: value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactOrderCard(Map<String, dynamic> order) {
    final String orderId = order['order_id'].toString();
    final bool isExpanded = _expandedOrders[orderId] ?? false;
    final items = order['items'] as List<dynamic>;
    final otp = order['otp']?.toString() ?? '';
    final totalAmount = order['total_amount'];
    final paymentMethod = order['payment_method']?.toString() ?? 'Cash';
    final pickupTime = _formatDateTime(order['pickup_time']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Order Header - Always visible
          InkWell(
            onTap: () {
              setState(() {
                _expandedOrders[orderId] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Order status and ID
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle, 
                                           color: Color(0xFF00CC00), size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FoodName(
                                foodName: "Order #$orderId",
                              ),
                              FoodDescription(
                                description: pickupTime,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Order amount
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FoodPrice(foodPrice: "₹${totalAmount.toStringAsFixed(0)}"),
                            FoodDescription(
                              description: "${items.length} ${items.length == 1 ? 'item' : 'items'}",
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF00CC00),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Items Section
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubTitles(
                    title: "Order Details",
                    fontSize: 13,
                    color: const Color(0xFF008000),
                  ),
                  const SizedBox(height: 8),
                  
                  // Items grid to save vertical space
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                getFullImageUrl(item['image']),
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 24,
                                    height: 24,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, color: Colors.grey, size: 14),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FoodName(
                                    foodName: item['name'],
                                  ),
                                  FoodDescription(
                                    description: "${item['quantity']} × ₹${item['price'].toStringAsFixed(0)}",
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Order info with OTP and payment
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(Icons.pin, "OTP: $otp", const Color(0xFFFF8C00)),
                        _buildInfoChip(Icons.payment, paymentMethod, const Color(0xFF00CC00)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          FoodDescription(
            description: label,
            color: color,
          ),
        ],
      ),
    );
  }
}
