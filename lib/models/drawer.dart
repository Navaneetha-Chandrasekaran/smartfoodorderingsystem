import 'package:bitetimenew/models/constants.dart';
import 'package:bitetimenew/ui/user/screens/settings_screen.dart';
import 'package:bitetimenew/ui/user/sheets/navbar.dart';
import '../sheets/navigator.dart';
import 'package:bitetimenew/models/drawer_tile.dart';
import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Drawer(
        backgroundColor: Colors.white, // ✅ Clean background
        child: Column(
          children: [
            /// ✅ **Stylish Drawer Header**
            Container(
              width: double.infinity,
              height: sh * 0.25,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF40CF58), Color(0xFF4AFD69)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  SubTitles(title: 'Hello, User!', fontSize: sw * 0.05, color: Colors.white),
                  const SizedBox(height: 5),
                  Description(description: "Welcome back!", color: Colors.white),
                ],
              ),
            ),

            /// ✅ **Divider with Shadow**
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              child: Divider(
                color: Colors.grey[400],
                thickness: 1,
              ),
            ),

            /// ✅ **Drawer Menu Items**
            _buildDrawerItems(context),
          ],
        ),
      ),
    );
  }

  /// ✅ **Build Drawer Items List**
  Widget _buildDrawerItems(BuildContext context) {
    return Column(
      children: [
        DrawerTile(
          text: SubTitles(title: 'Home', fontSize: 16),
          icon: Icons.home,
          onTap: () {
            Navigation.navigateTo(context, CustomNavBar());
          },
        ),
        DrawerTile(
          text: SubTitles(title: 'Settings', fontSize: 16),
          icon: Icons.settings,
          onTap: () {
            Navigation.navigateTo(context, SettingsScreen());
          },
        ),

        /// ✅ **Logout with Confirmation Dialog**
        DrawerTile(
          text: SubTitles(title: 'Logout', fontSize: 16, color: Colors.red),
          icon: Icons.logout,
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  /// ✅ **Logout Confirmation Dialog**
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigation.navigateTo(context, SettingsScreen());
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
