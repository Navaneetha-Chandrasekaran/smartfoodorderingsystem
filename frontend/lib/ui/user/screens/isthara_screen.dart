import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
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
  final String shopId;

  const IstharaScreen({super.key, required this.shopId});

  @override
  State<IstharaScreen> createState() => _IstharaScreenState();
}

class _IstharaScreenState extends State<IstharaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FoodTypeFilter _filter = FoodTypeFilter.all;
  bool _isLoading = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _isAnimating = true;
    _tabController = TabController(length: FoodCategory.values.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isAnimating = true;
          _isLoading = true;
        });
      }
      if (!_tabController.indexIsChanging) {
        setState(() {
          _isAnimating = false;
        });
        _retryFetch(
          category: FoodCategory.values[_tabController.index],
          type: _currentFilterType, 
          shopId: widget.shopId,
        ).then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    });
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retryFetch(
        category: FoodCategory.values[_tabController.index],
        type: _currentFilterType,
        shopId: widget.shopId,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAnimating = false;
          });
        }
      });
    });
  }

  void _handleTabChange() {
    // Removed since we're handling it in the listener
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

  Future<void> _retryFetch({FoodCategory? category, String? type, required String shopId}) async {
    try {
      int? parsedId = int.tryParse(shopId);
      if (parsedId == null) {
        throw Exception("Invalid shop ID format");
      }
      
      await Provider.of<FoodMenu>(context, listen: false)
          .fetchMenuFromBackend(category: category, type: type, shopId: parsedId);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorDialog.show(
          context,
          title: "Menu Load Failed",
          message: e.toString(),
          onRetry: () => _retryFetch(category: category, type: type, shopId: shopId),
        );
      });
    }
  }

  void _toggleVeg() {
    setState(() {
      _filter = _filter == FoodTypeFilter.veg ? FoodTypeFilter.all : FoodTypeFilter.veg;
      _isLoading = true;
    });
    _retryFetch(
      category: FoodCategory.values[_tabController.index],
      type: _currentFilterType,
      shopId: widget.shopId,
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _toggleNonVeg() {
    setState(() {
      _filter = _filter == FoodTypeFilter.nonVeg ? FoodTypeFilter.all : FoodTypeFilter.nonVeg;
      _isLoading = true;
    });
    _retryFetch(
      category: FoodCategory.values[_tabController.index],
      type: _currentFilterType,
      shopId: widget.shopId,
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
                body: Consumer<FoodMenu>(builder: (context, foodMenu, _) {
                  final menu = foodMenu.menu;

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      );
                    },
                    child: _isLoading
                        ? Center(
                            key: const ValueKey('loading'),
                            child: Lottie.asset(
                              'assets/lottie/loader.json',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          )
                        : TabBarView(
                            key: ValueKey<int>(_tabController.index),
                            controller: _tabController,
                            children: FoodCategory.values.map((category) {
                              final categoryItems = menu.where((food) => food.category == category).toList();
                              return categoryItems.isEmpty
                                  ? Center(
                                      key: ValueKey('empty_${category.name}'),
                                      child: const Text("No items in this category"),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: RefreshIndicator(
                                        onRefresh: () => _retryFetch(
                                          category: category,
                                          type: _currentFilterType,
                                          shopId: widget.shopId,
                                        ),
                                        child: ListView.builder(
                                          key: ValueKey('${category.name}_${_filter.name}'),
                                          itemCount: categoryItems.length,
                                          itemBuilder: (_, i) => FoodTile(
                                            food: categoryItems[i],
                                            onTap: () => Navigator.of(context).push(
                                              MaterialPageRoute(builder: (_) => FoodScreen(food: categoryItems[i])),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                            }).toList(),
                          ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
