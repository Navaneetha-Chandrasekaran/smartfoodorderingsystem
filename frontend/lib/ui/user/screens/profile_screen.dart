import 'package:flutter/material.dart';
import '../../../models/constants.dart';
import 'package:flutter/services.dart';
import '../../../services/auth/login_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "User";
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Load user data after widget is inserted in the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      print("🔄 Loading user data...");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Safely get name with fallback
      String? name = prefs.getString('name');
      
      // If we don't have a name, try to get it from AuthService as fallback
      String userName = name ?? "User";
      if (userName == "User") {
        final currentName = await AuthService.getCurrentName();
        if (currentName != null && currentName.isNotEmpty) {
          userName = currentName;
          print("✅ Retrieved name from AuthService: $userName");
        }
      }
      
      // Ensure we're still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _userName = userName;
        _isLoading = false;
      });
      
      print("✅ User data loaded successfully - Name: $_userName");
    } catch (e) {
      print("❌ Error loading user data: $e");
      
      // Ensure we're still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Error loading user data: $e";
      });
    }
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = "";
    });
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _retryLoading,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kLogoGreen),
                  SizedBox(height: 20),
                  Text("Loading profile data...",
                    style: TextStyle(color: kLogoGreen, fontWeight: FontWeight.w500),
                  )
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 70),
                      const SizedBox(height: 20),
                      const Text("Something went wrong", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(_errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: _retryLoading,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kLogoGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(screenWidth, screenHeight),
    );
  }

  Widget _buildProfileContent(double screenWidth, double screenHeight) {
    return Column(
        children: [
          _buildHeader(screenWidth, screenHeight),
        const SizedBox(height: 30),
          _buildProfileOptions(context, screenWidth),
        const Spacer(),
        _buildVersionInfo(),
          const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.35,
      width: screenWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kLogoGreen,
            kLogoGreen.withOpacity(0.8),
            kLogoGreen.withOpacity(0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: kLogoGreen.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Abstract design elements
          Positioned(
            top: -screenWidth * 0.1,
            right: -screenWidth * 0.1,
            child: Container(
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -screenWidth * 0.15,
            left: -screenWidth * 0.15,
            child: Container(
              width: screenWidth * 0.5,
              height: screenWidth * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // User profile
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
          Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
            ),
                  child: const Text(
                    "Student",
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions(BuildContext context, double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileItem(Icons.history, "Order History", Icons.arrow_forward_ios, () {
            Navigator.pushNamed(context, '/order_history');
          }),
          const Divider(height: 0.5, thickness: 0.5, indent: 20, endIndent: 20),
          _buildProfileItem(Icons.help_outline, "Help & Support", Icons.arrow_forward_ios, () {
            // Navigate to help
          }),
          const Divider(height: 0.5, thickness: 0.5, indent: 20, endIndent: 20),
          _buildProfileItem(Icons.logout, "Logout", Icons.exit_to_app, () {
            _showLogoutConfirmation(context);
          }, textColor: Colors.red),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, IconData trailingIcon, VoidCallback onTap, {Color? textColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: icon == Icons.logout 
                    ? Colors.red.withOpacity(0.1) 
                    : kLogoGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: icon == Icons.logout ? Colors.red : kLogoGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              trailingIcon,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            "BiteTime",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kLogoGreen,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Version 1.0.0",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text("Logout"),
            ],
          ),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement Logout Function
                AuthService().logoutUser().then((_) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/user-selection',
                    (route) => false,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
