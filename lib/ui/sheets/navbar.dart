import 'package:flutter/material.dart';
import '../../models/constants.dart';
import '../screens/home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/order_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/timeline_screen.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _selectedIndex = 0;

  // List of screens corresponding to navbar items
  final List<Widget> _screens = [
    HomeScreen(),
    CartScreen(),
    TimelineScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: Container(
        height: 102, // Slightly taller navbar
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Optional rounded corners
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.black,
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped, // Handles navigation
          items: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.shopping_cart, 1),
            _buildNavItem(Icons.assignment, 2),
            _buildNavItem(Icons.person, 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 8), // Moves icons lower
        child: _selectedIndex == index
            ? ShaderMask(
                shaderCallback: (Rect bounds) {
                  return primaryColor.createShader(bounds);
                },
                child: Icon(icon, size: 35, color: Colors.white), // Active icon
              )
            : Icon(icon, size: 35, color: Colors.black), // Inactive icon
      ),
      label: '',
    );
  }
}
