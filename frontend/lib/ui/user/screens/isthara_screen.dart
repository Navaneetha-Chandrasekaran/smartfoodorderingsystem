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
import 'food_screen.dart';

enum FoodTypeFilter { all, veg, nonVeg }

class IstharaScreen extends StatefulWidget {
  const IstharaScreen({super.key});

  @override
  State<IstharaScreen> createState() => _IstharaScreenState();
}

class _IstharaScreenState extends State<IstharaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FoodTypeFilter _filter = FoodTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: FoodCategory.values.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _retryFetch(); // Initial load
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _retryFetch(
      category: FoodCategory.values[_tabController.index],
      type: _currentFilterType,
    );
  }

  String? get _currentFilterType {
    switch (_filter) {
      case FoodTypeFilter.veg:
        return 'veg';
      case FoodTypeFilter.nonVeg:
        return 'non_veg';
      default:
        return null;
    }
  }

  Future<void> _retryFetch({FoodCategory? category, String? type}) async {
    try {
      await Provider.of<FoodMenu>(context, listen: false)
          .fetchMenuFromBackend(category: category, type: type, shopId: 2);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorDialog.show(
          context,
          title: "Menu Load Failed",
          message: e.toString(),
          onRetry: () => _retryFetch(category: category, type: type),
        );
      });
    }
  }

  void _toggleVeg() {
    setState(() {
      _filter = _filter == FoodTypeFilter.veg ? FoodTypeFilter.all : FoodTypeFilter.veg;
    });
    _retryFetch(
      category: FoodCategory.values[_tabController.index],
      type: _currentFilterType,
    );
  }

  void _toggleNonVeg() {
    setState(() {
      _filter = _filter == FoodTypeFilter.nonVeg ? FoodTypeFilter.all : FoodTypeFilter.nonVeg;
    });
    _retryFetch(
      category: FoodCategory.values[_tabController.index],
      type: _currentFilterType,
    );
  }

  List<Widget> getFoodInCategory(List<Food> menu) {
    return FoodCategory.values.map((category) {
      final categoryItems = menu.where((food) => food.category == category).toList();

      return categoryItems.isEmpty
          ? const Center(child: Text("No items in this category"))
          : Padding(
              padding: const EdgeInsets.all(8),
              child: RefreshIndicator(
                onRefresh: () => _retryFetch(
                  category: category,
                  type: _currentFilterType,
                ),
                child: ListView.builder(
                  key: ValueKey('${category.name}_${_filter.name}'),
                  itemCount: categoryItems.length,
                  itemBuilder: (_, i) => FoodTile(
                    food: categoryItems[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FoodScreen(food: categoryItems[i])),
                    )
                  ),
                ),
              ),
            );
    }).toList();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideDrawer(),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: NestedScrollView(
                key: ValueKey<FoodTypeFilter>(_filter),
                headerSliverBuilder: (_, __) => [
                  MySliverAppBar(
                    title: const SubTitles(title: 'Isthara'),
                    child: const Text(''),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(40),
                      child: MyTabBar(tabController: _tabController),
                    ),
                    showVegOnly: _filter == FoodTypeFilter.veg,
                    showNonVegOnly: _filter == FoodTypeFilter.nonVeg,
                    onToggle: _toggleVeg,
                    onNonVegToggle: _toggleNonVeg,
                  ),
                ],
                body: Consumer<FoodMenu>(
                  builder: (context, foodMenu, _) {
                    final menu = foodMenu.menu;
                    return menu.isEmpty
                        ? const Center(child: Text("Menu is empty"))
                        : TabBarView(
                            controller: _tabController,
                            children: getFoodInCategory(menu),
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