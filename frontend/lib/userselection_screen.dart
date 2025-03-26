import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sheets/navigator.dart';
import 'ui/canteen/screens/login_screen.dart';
import 'ui/user/screens/login_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 🌟 Background with Deep Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF40CF58), Color(0xFF4AFD69)], // Dark Green → Teal
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🌟 Centered Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 Logo with White Background for Contrast
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Image.asset("assets/logo.png", width: screenWidth * 0.4),
                ),

                SizedBox(height: screenHeight * 0.04),

                // 🌟 Header Text
                Text(
                  "Who Are You?",
                  style: GoogleFonts.roboto(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // 🌟 Glassmorphism Role Selection Box
                Container(
                  width: screenWidth * 0.85,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3), // Frosted Glass Effect
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.7)),
                  ),
                  child: Column(
                    children: [
                      _buildRoleCard(
                        title: "Student",
                        icon: Icons.school,
                        onTap: () => Navigation.navigateTo(context, UserLoginScreen()),
                      ),
                      SizedBox(height: 20),
                      _buildRoleCard(
                        title: "Canteen Staff",
                        icon: Icons.storefront,
                        onTap: () => Navigation.navigateTo(context, CanteenLoginScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Reusable Role Selection Card
  Widget _buildRoleCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green[800], size: 28),
            SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
