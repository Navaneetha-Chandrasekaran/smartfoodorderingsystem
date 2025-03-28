// ignore_for_file: deprecated_member_use, avoid_print

import 'package:bitetimenew/ui/canteen/screens/stock_screen.dart';
import 'package:flutter/material.dart';
import '../screens/canteen_dashboard_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';

class CanteenNavBar extends StatefulWidget {
  const CanteenNavBar({super.key});

  @override
  State<CanteenNavBar> createState() => _CanteenNavBarState();
}

class _CanteenNavBarState extends State<CanteenNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    CanteenDashboard(),
    StockManagementScreen(), // ✅ Stock Screen Added
    OrdersScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    print("Tapped on index: $index"); // ✅ Debugging
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey[500],
          showUnselectedLabels: false,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 0, screenWidth),
            _buildNavItem(Icons.inventory_2_outlined, Icons.inventory_2, 1, screenWidth), // ✅ Stock Icon Added
            _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 2, screenWidth),
            _buildNavItem(Icons.person_outline, Icons.person, 3, screenWidth),
          ],
        ),
      ),
    );
  }

  /// **✅ Only Icons are Clickable with Ripple Effect**
  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, int index, double screenWidth) {
    return BottomNavigationBarItem(
      icon: InkResponse(
        onTap: () => _onItemTapped(index),
        splashColor: Colors.green.withOpacity(0.3),
        radius: 40, // ✅ Expanded touch area
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _selectedIndex == index ? Colors.green.withOpacity(0.2) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: screenWidth * 0.055),
        ),
      ),
      activeIcon: InkResponse(
        onTap: () => _onItemTapped(index),
        splashColor: Colors.green.withOpacity(0.3),
        radius: 40,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(activeIcon, size: screenWidth * 0.065),
        ),
      ),
      label: "",
    );
  }
}
