import 'package:bitetimenew/models/food_tile.dart';
import 'package:bitetimenew/ui/user/screens/food_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitetimenew/models/drawer.dart';
import 'package:bitetimenew/models/sliver_appbar.dart';
import 'package:bitetimenew/models/tab_bar.dart';
import 'package:bitetimenew/models/titles.dart';
import 'package:bitetimenew/food.dart';
import 'package:bitetimenew/food_menu.dart';

import '../../../../sheets/navigator.dart';

class IstharaScreen extends StatefulWidget {
  const IstharaScreen({super.key});

  @override
  State<IstharaScreen> createState() => _IstharaScreenState();
}

class _IstharaScreenState extends State<IstharaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showVegOnly = false;  // Toggle for Veg items
  bool _showNonVegOnly = false;  // Toggle for Non-Veg items

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: FoodCategory.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Filters menu by category and veg/non-veg toggles
  List<Food> _filterMenuByCategory(FoodCategory category, List<Food> fullMenu) {
    return fullMenu
        .where((food) => food.category == category)
        .where((food) =>
            (!_showVegOnly && !_showNonVegOnly) || // Show all food if both filters are off
            (_showVegOnly && food.isVeg) ||  // Show only veg items if the veg toggle is on
            (_showNonVegOnly && !food.isVeg)) // Show only non-veg items if the non-veg toggle is on
        .toList();
  }

  // ✅ Returns list of food items per category
  List<Widget> getFoodInCategory(List<Food> fullMenu) {
    return FoodCategory.values.map((category) {
      List<Food> categoryMenu = _filterMenuByCategory(category, fullMenu);

      return categoryMenu.isEmpty
          ? const Center(child: Text("No items in this category"))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: categoryMenu.length,
                itemBuilder: (context, index) {
                  final food = categoryMenu[index];

                  return FoodTile(
                    food: food,
                    onTap: () => Navigation.navigateTo(context, FoodScreen(food: food)),
                    availableItems: food.availableQuantity,
                  );
                },
              ),
            );
    }).toList();
  }

  // Toggling Veg and Non-Veg states
  void _toggleVeg() {
    setState(() {
      _showVegOnly = !_showVegOnly;
      if (_showVegOnly) _showNonVegOnly = false; // Ensure Non-Veg toggle is off when Veg is on
    });
  }

  void _toggleNonVeg() {
    setState(() {
      _showNonVegOnly = !_showNonVegOnly;
      if (_showNonVegOnly) _showVegOnly = false; // Ensure Veg toggle is off when Non-Veg is on
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideDrawer(),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: NestedScrollView(
                key: ValueKey<bool>(_showVegOnly || _showNonVegOnly),  // Ensures animation when toggling
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  MySliverAppBar(
                    child: const Text(''),
                    title: const SubTitles(title: 'Isthara'),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(40),
                      child: MyTabBar(tabController: _tabController),
                    ),
                    // Passing the toggle state to the SliverAppBar
                    showVegOnly: _showVegOnly,
                    showNonVegOnly: _showNonVegOnly,
                    onToggle: _toggleVeg,
                    onNonVegToggle: _toggleNonVeg,
                  ),
                ],
                body: Consumer<FoodMenu>(
                  builder: (context, foodMenu, child) => TabBarView(
                    controller: _tabController,
                    children: getFoodInCategory(foodMenu.menu), // Pass the filtered menu
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
