import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../food.dart';
import '../../../food_menu.dart';
import '../../../models/drawer.dart';
import '../../../models/error_dialog.dart';
import '../../../models/food_tile.dart';
import '../../../models/sliver_appbar.dart';
import '../../../models/tab_bar.dart';
import '../../../models/titles.dart';
import '../../../sheets/navigator.dart';
import 'food_screen.dart';

class IstharaScreen extends StatefulWidget {
  const IstharaScreen({super.key});

  @override
  State<IstharaScreen> createState() => _IstharaScreenState();
}

class _IstharaScreenState extends State<IstharaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showVegOnly = false;
  bool _showNonVegOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: FoodCategory.values.length, vsync: this);
    _retryFetch();
  }

  Future<void> _retryFetch() async {
    try {
      await Provider.of<FoodMenu>(context, listen: false).fetchMenuFromBackend(
        showVegOnly: _showVegOnly,
        showNonVegOnly: _showNonVegOnly,
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorDialog.show(
          context,
          title: "Menu Load Failed",
          message: e.toString(),
          onRetry: _retryFetch,
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Removed local veg/non-veg filtering
  List<Food> _filterMenuByCategory(FoodCategory category, List<Food> fullMenu) {
    return fullMenu.where((food) => food.category == category).toList();
  }

  List<Widget> getFoodInCategory(List<Food> fullMenu) {
    return FoodCategory.values.map((category) {
      final categoryMenu = _filterMenuByCategory(category, fullMenu);

      return categoryMenu.isEmpty
          ? const Center(child: Text("No items in this category"))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: RefreshIndicator(
                onRefresh: () => Provider.of<FoodMenu>(context, listen: false)
                    .fetchMenuFromBackend(
                      category: category,
                      showVegOnly: _showVegOnly,
                      showNonVegOnly: _showNonVegOnly,
                    ),
                child: ListView.builder(
                  key: ValueKey('${category.name}_${_showVegOnly}_$_showNonVegOnly}'),
                  itemCount: categoryMenu.length,
                  itemBuilder: (context, index) {
                    final food = categoryMenu[index];
                    return FoodTile(
                      food: food,
                      onTap: () => Navigation.navigateTo(
                        context,
                        FoodScreen(food: food),
                      ),
                    );
                  },
                ),
              ),
            );
    }).toList();
  }

  void _toggleVeg() async {
    setState(() {
      _showVegOnly = !_showVegOnly;
      if (_showVegOnly) _showNonVegOnly = false;
    });
    await _retryFetch();
  }

  void _toggleNonVeg() async {
    setState(() {
      _showNonVegOnly = !_showNonVegOnly;
      if (_showNonVegOnly) _showVegOnly = false;
    });
    await _retryFetch();
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
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: NestedScrollView(
                key: ValueKey<bool>(_showVegOnly || _showNonVegOnly),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  MySliverAppBar(
                    child: const Text(''),
                    title: const SubTitles(title: 'Isthara'),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(40),
                      child: MyTabBar(tabController: _tabController),
                    ),
                    showVegOnly: _showVegOnly,
                    showNonVegOnly: _showNonVegOnly,
                    onToggle: _toggleVeg,
                    onNonVegToggle: _toggleNonVeg,
                  ),
                ],
                body: Consumer<FoodMenu>(
                  builder: (context, foodMenu, _) {
                    final allMenu = foodMenu.menu;

                    if (allMenu.isEmpty) {
                      return const Center(child: Text("Menu is empty"));
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: getFoodInCategory(allMenu),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
