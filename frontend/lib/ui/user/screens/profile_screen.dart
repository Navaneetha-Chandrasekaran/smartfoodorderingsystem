import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          _buildCurvedBackground(),
          Column(
            children: [
              const SizedBox(height: 120), // Space for floating profile
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildProfileOptions(context),
            ],
          ),
        ],
      ),
    );
  }

  /// **🎨 Beautiful Curved Background**
  Widget _buildCurvedBackground() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(80),
          bottomRight: Radius.circular(80),
        ),
      ),
    );
  }

  /// **👤 Floating Profile Header**
  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 60,
                // backgroundImage: AssetImage('assets/profile_placeholder.png'), 
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.green),
                onPressed: () {
                  // ✅ Navigate to Edit Profile Screen
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          "John Doe", // ✅ Replace with actual user name
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        const Text(
          "johndoe@example.com", // ✅ Replace with user email
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  /// **⚡ Stylish Profile Options**
  Widget _buildProfileOptions(BuildContext context) {
    return Column(
      children: [
        _buildProfileItem(Icons.history, "Order History", Icons.arrow_forward_ios, () {}),
        _buildProfileItem(Icons.person, "Edit Profile", Icons.arrow_forward_ios, () {}),
        _buildProfileItem(Icons.settings, "Settings", Icons.arrow_forward_ios, () {}),
        _buildProfileItem(Icons.logout, "Logout", Icons.exit_to_app, () {
          _showLogoutConfirmation(context);
        }),
      ],
    );
  }

  /// **📌 Profile Option Tile**
  Widget _buildProfileItem(IconData icon, String title, IconData trailingIcon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Icon(trailingIcon, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  /// **🚪 Logout Confirmation**
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // ✅ Implement Logout Function
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
