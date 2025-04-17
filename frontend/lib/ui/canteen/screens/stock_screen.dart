import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../food.dart';
import '../../../services/utils.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final Map<Food, int> updatedStock = {}; // Track updated stock values
  bool _isLoading = true;
  List<Food> _foodMenu = [];

  @override
  void initState() {
    super.initState();
    _fetchStockData();
  }

  // Fetch stock data from the API
  Future<void> _fetchStockData() async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'];
      print("🌍 API URL: $apiUrl");

      final response = await http.get(
        Uri.parse('$apiUrl/food/stocks?shop_id=2'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> foodData = json.decode(response.body);
        print("Raw API Response: $foodData");

        setState(() {
          _foodMenu = foodData.map((item) {
            var foodItem = Food.fromJson(item);
            return foodItem;
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching stock: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load stock data.")),
      );
    }
  }

  // Update stock in the API
  Future<bool> updateStockData(Food food, int change) async {
    if (food.id == 0) {
      return false; // Skip the update if the food ID is invalid
    }

    try {
      final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api/food/stocks';
      final response = await http.put(
        Uri.parse('$apiBaseUrl/food/stocks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'shop_id': 2,
          'food_id': food.id,
          'change': food.availableQuantity + change,
        }),
      );

      if (response.statusCode == 200) {
        return true;  // Stock update successful
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stock for ${food.name}.')),
        );
        return false;  // Stock update failed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stock. Please try again later.')),
      );
      return false;  // Stock update failed due to exception
    }
  }

  // Function to handle "Save" button click
  Future<void> _saveStockChanges() async {
    bool allUpdatesSuccessful = true;
    final failedUpdates = <String>[];

    for (var food in _foodMenu) {
      final newQuantity = updatedStock[food] ?? food.availableQuantity;
      final change = newQuantity - food.availableQuantity;

      if (change != 0) {
        bool updateSuccessful = await updateStockData(food, change);
        if (updateSuccessful) {
          setState(() {
            food.availableQuantity = newQuantity;
            updatedStock.remove(food);
          });
        } else {
          allUpdatesSuccessful = false;
          failedUpdates.add(food.name);
        }
      }
    }

    if (allUpdatesSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ All stock updates successful!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Some updates failed: ${failedUpdates.join(', ')}.")),
      );
    }
  }

  // Stock Item UI
  Widget _buildStockItem(Food food) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                getFullImageUrl(food.image),
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 75, color: Colors.grey);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 75,
                    height: 75,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 5),
                  Text("Available: ${food.availableQuantity}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                ],
              ),
            ),
            _buildStockStepper(food),
          ],
        ),
      ),
    );
  }

  // Stock Counter Stepper
  Widget _buildStockStepper(Food food) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if ((updatedStock[food] ?? food.availableQuantity) > 0) {
                updatedStock[food] = (updatedStock[food] ?? food.availableQuantity) - 1;
              }
            });
          },
          child: _iconButton(Icons.remove_circle, Colors.redAccent),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              (updatedStock[food] ?? food.availableQuantity).toString(),
              key: ValueKey<int>(updatedStock[food] ?? food.availableQuantity),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              updatedStock[food] = (updatedStock[food] ?? food.availableQuantity) + 1;
            });
          },
          child: _iconButton(Icons.add_circle, Colors.green),
        ),
      ],
    );
  }

  // Circular Icon Button for Stepper
  Widget _iconButton(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
      child: Icon(icon, color: color, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Stock Management"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveStockChanges, // Call the save function
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _foodMenu.length,
                itemBuilder: (context, index) {
                  final food = _foodMenu[index];
                  return _buildStockItem(food);
                },
              ),
            ),
    );
  }
}
