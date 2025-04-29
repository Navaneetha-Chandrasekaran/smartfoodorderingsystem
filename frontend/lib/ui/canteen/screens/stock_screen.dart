import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../food.dart';
import '../../../services/utils.dart';
import '../../../models/constants.dart';
import '../../../models/titles.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> with SingleTickerProviderStateMixin {
  final Map<Food, int> updatedStock = {}; // Track updated stock values
  bool _isLoading = true;
  List<Food> _foodMenu = [];
  Map<FoodCategory, List<Food>> _categorizedFoodMenu = {};
  bool _isSaving = false;
  String _activeCategory = '';
  
  // For animated save button
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchStockData();
  }

  void _initAnimations() {
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _saveButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _saveButtonController,
      curve: Curves.elasticInOut,
    ));
  }

  @override
  void dispose() {
    _saveButtonController.dispose();
    super.dispose();
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
          
          // Group foods by category
          _categorizedFoodMenu = {};
          for (var food in _foodMenu) {
            if (!_categorizedFoodMenu.containsKey(food.category)) {
              _categorizedFoodMenu[food.category] = [];
            }
            _categorizedFoodMenu[food.category]!.add(food);
          }
          
          // Set active category to first one if available
          if (_categorizedFoodMenu.isNotEmpty) {
            _activeCategory = _categorizedFoodMenu.keys.first.name;
          }
          
          _isLoading = false;
        });
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching stock: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load stock data."),
          backgroundColor: Colors.red,
        ),
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
          SnackBar(
            content: Text('Failed to update stock for ${food.name}.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;  // Stock update failed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating stock. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;  // Stock update failed due to exception
    }
  }

  // Function to handle "Save" button click
  Future<void> _saveStockChanges() async {
    setState(() => _isSaving = true);
    
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

    setState(() => _isSaving = false);
    
    if (allUpdatesSuccessful) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("All stock updates successful!"),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Some updates failed: ${failedUpdates.join(', ')}.")),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // Get color based on stock level
  Color _getStockLevelColor(int quantity) {
    if (quantity <= 0) return Colors.red.shade400;
    if (quantity < 5) return Colors.orange.shade400;
    if (quantity < 10) return Colors.amber.shade400;
    return kLogoGreen;
  }

  // Stock Item UI
  Widget _buildStockItem(Food food) {
    final currentQuantity = updatedStock[food] ?? food.availableQuantity;
    final hasChanged = updatedStock.containsKey(food);
    final stockColor = _getStockLevelColor(currentQuantity);
    
    return AnimationConfiguration.staggeredList(
      position: _foodMenu.indexOf(food),
      duration: const Duration(milliseconds: 450),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.grey.withOpacity(0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: hasChanged 
                    ? [Colors.white, Colors.green.shade50] 
                    : [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: hasChanged 
                  ? Border.all(color: kLogoGreen.withOpacity(0.5), width: 1.5)
                  : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: [
                    // Food image with stock level indicator
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            getFullImageUrl(food.image),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            },
                          ),
                        ),
                        
                        // Stock level indicator pill
                        Container(
                          margin: EdgeInsets.only(right: 4, bottom: 4),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stockColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            currentQuantity.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Veg/Non-veg indicator
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              food.isVeg ? Icons.eco : Icons.restaurant,
                              color: food.isVeg ? Colors.green : Colors.redAccent,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Food details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FoodName(foodName: food.name),
                          
                          const SizedBox(height: 4),
                          
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FoodPrice(foodPrice: "₹${food.price.toStringAsFixed(2)}"),
                              ),
                              
                              const SizedBox(width: 6),
                              
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FoodDescription(
                                  description: _getCategoryName(food.category),
                                  color: Colors.purple.shade800,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Status change indicator
                          if (hasChanged)
                            Row(
                              children: [
                                Icon(
                                  food.availableQuantity < currentQuantity 
                                      ? Icons.arrow_upward 
                                      : Icons.arrow_downward,
                                  color: food.availableQuantity < currentQuantity 
                                      ? Colors.green 
                                      : Colors.red,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                FoodDescription(
                                  description: "Changed from ${food.availableQuantity}",
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    // Stock stepper
                    _buildStockStepper(food),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryName(FoodCategory category) {
    switch (category) {
      case FoodCategory.breakfast:
        return "Breakfast";
      case FoodCategory.lunch:
        return "Lunch";
      case FoodCategory.snacks:
        return "Snacks";
      case FoodCategory.beverages:
        return "Beverages";
      default:
        return "Other";
    }
  }

  // Stock Counter Stepper
  Widget _buildStockStepper(Food food) {
    final currentQuantity = updatedStock[food] ?? food.availableQuantity;
    
    return Column(
      children: [
        // Increment button
        GestureDetector(
          onTap: () {
            setState(() {
              updatedStock[food] = currentQuantity + 1;
              // Pulse animation for the save button
              _saveButtonController.forward().then((_) => _saveButtonController.reverse());
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: kLogoGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(6),
            child: Icon(Icons.add, color: kLogoGreen, size: 24),
          ),
        ),
        
        // Quantity display
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              currentQuantity.toString(),
              key: ValueKey<int>(currentQuantity),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getStockLevelColor(currentQuantity),
              ),
            ),
          ),
        ),
        
        // Decrement button
        GestureDetector(
          onTap: () {
            if (currentQuantity > 0) {
              setState(() {
                updatedStock[food] = currentQuantity - 1;
                // Pulse animation for the save button
                _saveButtonController.forward().then((_) => _saveButtonController.reverse());
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(6),
            child: Icon(Icons.remove, color: Colors.red, size: 24),
          ),
        ),
      ],
    );
  }

  // Build category tabs
  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: _categorizedFoodMenu.keys.map((category) {
          final isActive = _activeCategory == category.name;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategory = category.name;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? kLogoGreen : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: isActive 
                        ? kLogoGreen.withOpacity(0.3) 
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: isActive ? kLogoGreen : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: isActive ? Colors.white : Colors.grey.shade700,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getCategoryName(category),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  IconData _getCategoryIcon(FoodCategory category) {
    switch (category) {
      case FoodCategory.breakfast:
        return Icons.breakfast_dining;
      case FoodCategory.lunch:
        return Icons.lunch_dining;
      case FoodCategory.snacks:
        return Icons.bakery_dining;
      case FoodCategory.beverages:
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }

  // Summary card showing changes
  Widget _buildSummaryCard() {
    if (updatedStock.isEmpty) return SizedBox.shrink();
    
    int itemsChanged = updatedStock.length;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kLogoGreen.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: kLogoGreen.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kLogoGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_note, color: kLogoGreen, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubTitles(
                  title: "$itemsChanged ${itemsChanged == 1 ? 'item' : 'items'} modified",
                  fontSize: 16,
                  color: Colors.black87,
                ),
                Description(
                  description: "Tap the floating button below to save changes",
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SubTitles(
          title: "Stock Management",
          fontSize: 20,
          color: Colors.white,
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kLogoGreen,
                Color(0xFF4AE578), // Lighter green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (updatedStock.isNotEmpty)
            Badge(
              label: Text(
                updatedStock.length.toString(),
                style: TextStyle(color: Colors.white),
              ),
              child: Icon(Icons.edit, color: Colors.white),
            ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kLogoGreen),
                  SizedBox(height: 16),
                  Description(
                    description: "Loading inventory...",
                    color: Colors.grey[600],
                  ),
                ],
              ),
            )
          : Column(
              children: [
                SizedBox(height: 16),
                // Category tabs
                _buildCategoryTabs(),
                
                // Summary of changes
                _buildSummaryCard(),
                
                // Food items list grouped by active category
                Expanded(
                  child: _categorizedFoodMenu.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, 
                                size: 64, 
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              SubTitles(
                                title: "No items in inventory",
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _categorizedFoodMenu.entries
                                .firstWhere(
                                  (entry) => entry.key.name == _activeCategory,
                                  orElse: () => MapEntry(FoodCategory.breakfast, []),
                                )
                                .value
                                .length,
                            itemBuilder: (context, index) {
                              final food = _categorizedFoodMenu.entries
                                  .firstWhere(
                                    (entry) => entry.key.name == _activeCategory,
                                    orElse: () => MapEntry(FoodCategory.breakfast, []),
                                  )
                                  .value[index];
                              return _buildStockItem(food);
                            },
                          ),
                        ),
                ),
              ],
            ),
      // Floating action button to save changes
      floatingActionButton: updatedStock.isNotEmpty
          ? AnimatedBuilder(
              animation: _saveButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _saveButtonAnimation.value,
                  child: FloatingActionButton.extended(
                    onPressed: _isSaving ? null : _saveStockChanges,
                    backgroundColor: kLogoGreen,
                    icon: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.save),
                    label: Text(
                      _isSaving 
                          ? "Saving..." 
                          : "Save Changes (${updatedStock.length})",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    elevation: 4,
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
