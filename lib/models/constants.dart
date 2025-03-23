import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/user/screens/login_screen.dart';
import 'titles.dart';
import 'package:bitetimenew/sheets/navigator.dart';


//Primary color
const LinearGradient primaryColor = LinearGradient(
  colors: [Color.fromRGBO(74, 242, 102, 1), Color.fromRGBO(2, 224, 40, 1)],
  begin: Alignment.topLeft,
  end: Alignment(0.8, 1),
);

const secondaryColor = Color.fromRGBO(28, 231, 63, 1);

class userButton extends StatelessWidget {
  const userButton({
    super.key,
    required this.userType,
  });
  final String userType;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      },
      child: Container(
          width: screenWidth * 0.8,
          height: screenHeight * 0.05,
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(userType,
                style: GoogleFonts.roboto(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w700,
                )),
          )),
    );
  }
}



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
class Shops extends StatelessWidget {
  const Shops({
    super.key,
    required this.Icon,
    required this.ShopName,
    required this.Status,
    this.destination,
    
  });
  final Image Icon;
  final SubTitles ShopName;
  final Image Status;
  final Widget? destination;
  

  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;
    return InkWell(
    onTap: destination != null
          ? () => Navigation.navigateTo(context, destination!) // ✅ Proper function call
          : null, // ✅ No action if destination is null
      child: Container(
        width: sw * 0.8,
        height: sh * 0.07,
        decoration: BoxDecoration(
          color: Color.fromARGB(169, 255, 255, 255),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(164, 158, 158, 158),
              offset: Offset(0, 4),
              spreadRadius: 3,
              blurRadius: 5,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon,
            ShopName,
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20),
              child: Status
            ),
          ],
        ),
      ),
    );
  }
}
