import 'package:bitetimenew/models/food_tile.dart';
import 'package:bitetimenew/ui/screens/food_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitetimenew/models/drawer.dart';
import 'package:bitetimenew/models/sliver_appbar.dart';
import 'package:bitetimenew/models/tab_bar.dart';
import 'package:bitetimenew/models/titles.dart';
import 'package:bitetimenew/ui/sheets/food.dart';
import 'package:bitetimenew/ui/sheets/food_menu.dart';

import '../../sheets/navigator.dart';

class IstharaScreen extends StatefulWidget {
  const IstharaScreen({super.key});

  @override
  State<IstharaScreen> createState() => _IstharaScreenState();
}

class _IstharaScreenState extends State<IstharaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showVegOnly = false; // ✅ Tracks filter state

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

  // ✅ Filters menu by category
  List<Food> _filterMenuByCategory(FoodCategory category, List<Food> fullMenu) {
    return fullMenu
        .where((food) => food.category == category)
        .where((food) => !_showVegOnly || food.isVeg) // ✅ Apply Veg filter
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
                  );
                },
              ),
            );
    }).toList();
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
                key: ValueKey<bool>(_showVegOnly), // ✅ Ensures animation when toggling
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  MySliverAppBar(
                    child: const Text(''),
                    title: const SubTitles(title: 'Isthara'),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(40),
                      child: MyTabBar(tabController: _tabController),
                    ),
                    showVegOnly: _showVegOnly, // ✅ Pass filter state
                    onToggle: () {
                      setState(() {
                        _showVegOnly = !_showVegOnly;
                      });
                    },
                  ),
                ],
                body: Consumer<FoodMenu>(
                  builder: (context, foodMenu, child) => TabBarView(
                    controller: _tabController,
                    children: getFoodInCategory(foodMenu.menu),
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
