// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/shop_service.dart';
import '../sheets/navigator.dart';
import 'shop.dart';
import 'titles.dart';

// Logo Colors
const Color kLogoGreen = Color(0xFF00D943);   // Green from logo
const Color kLogoOrange = Color(0xFFFF7C2B);  // Orange from logo

//Primary color
const LinearGradient primaryColor = LinearGradient(
  colors: [Color.fromRGBO(74, 242, 102, 1), Color.fromRGBO(2, 224, 40, 1)],
  begin: Alignment.topLeft,
  end: Alignment(0.8, 1),
);

const secondaryColor = Color.fromRGBO(28, 231, 63, 1);

// class userButton extends StatelessWidget {
//   const userButton({
//     super.key,
//     required this.userType,
//   });
//   final String userType;

//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//             context, MaterialPageRoute(builder: (context) => const LoginScreen()));
//       },
//       child: Container(
//           width: screenWidth * 0.8,
//           height: screenHeight * 0.05,
//           decoration: BoxDecoration(
//             color: secondaryColor,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Center(
//             child: Text(userType,
//                 style: GoogleFonts.roboto(
//                   fontSize: screenWidth * 0.05,
//                   fontWeight: FontWeight.w700,
//                 )),
//           )),
//     );
//   }
// }



//Textfield controller
class SignUpController extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Dispose controllers when not needed
  void disposeControllers() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    notifyListeners();
  }
}


//Custom textfield

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isPasswordVisible;
  final Function? togglePasswordVisibility;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.togglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hintText,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword ? !isPasswordVisible : false,
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide(style: BorderStyle.solid, color: Colors.black),
              borderRadius: BorderRadius.circular(20),
            ),
            prefixIcon: Icon(prefixIcon),
            hintText: 'Enter your $hintText',
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      if (togglePasswordVisibility != null) {
                        togglePasswordVisibility!();
                      }
                    },
                  )
                : null,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}


//Shop container
class Shops extends StatefulWidget {
  const Shops({
    super.key,
    required this.icon,
    required this.shopName,
    required this.status,
    this.destination,
    required this.shop,  // Pass the entire Shop object for handling its ID
  });

  final Image icon;
  final SubTitles shopName;
  final Image status;
  final Widget? destination;
  final Shop shop;  // Add the shop object to access its ID

  @override
  State<Shops> createState() => _ShopsState();
}

class _ShopsState extends State<Shops> {
  bool _isTapped = false;

  // Method to store the selected shop ID
  Future<void> _storeShopId() async {
    await ShopService().storeSelectedShopId(widget.shop.id);  // Store the shop ID in SharedPreferences
    print("Stored shop ID: ${widget.shop.id}");
  }

  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: () {
        // Store the shop ID when tapped
        _storeShopId();

        // Navigate to the destination page if it is not null
        if (widget.destination != null) {
          Navigation.navigateTo(context, widget.destination!);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: sw * 0.85,
        height: sh * 0.08,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: _isTapped
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: _isTapped
              ? [BoxShadow(color: Colors.greenAccent, blurRadius: 10, spreadRadius: 2)]
              : [BoxShadow(color: Colors.black12.withOpacity(0.2), blurRadius: 8, spreadRadius: 2, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            widget.icon,
            Expanded(child: Padding(padding: const EdgeInsets.only(left: 20), child: widget.shopName)),
            Padding(padding: const EdgeInsets.only(right: 15), child: widget.status),
          ],
        ),
      ),
    );
  }
}
