import 'package:bitetimenew/ui/user/screens/isthara/isthara.dart';
import 'package:bitetimenew/ui/user/screens/notfication_screen.dart';
import 'package:flutter/material.dart';
import '../../../models/constants.dart';
import '../../../models/titles.dart';
import '../../../sheets/navigator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100], // ✅ Softer background
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(sh * 0.3),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: Titles(title: 'Welcome'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                onPressed: () {
                  Navigation.navigateTo(context, NotficationScreen());
                },
                icon: Icon(Icons.notifications, color: Colors.black, size: sw * 0.08),
              ),
            ),
          ],
          flexibleSpace: Stack(
            children: [
              // ✅ Gradient Background with Shadow
              Container(
                decoration: BoxDecoration(
                  gradient: primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // ✅ Content inside AppBar
              Positioned(
                bottom: 15,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SubTitles(title: 'Tap, Collect and Delight!', fontSize: sw * 0.045),
                          SizedBox(height: sh * 0.005),
                          Description(description: "Let's find your favorite food"),
                        ],
                      ),
                    ),
                    Image.asset('assets/fav.png', width: sw * 0.2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: sh * 0.02),
              SubTitles(title: 'Dish Up Your Cravings!'),
              SizedBox(height: sh * 0.04),
          
              // ✅ Using Shops Component from Constants
              Shops(
                Icon: Image.asset('assets/shop.png'),
                ShopName: SubTitles(title: 'Isthara', fontSize: sw * 0.04),
                Status: Image.asset('assets/open.png'),
                destination: IstharaScreen(),
              ),
              SizedBox(height: sh * 0.05),
              Shops(
                Icon: Image.asset('assets/shop.png'),
                ShopName: SubTitles(title: 'Brown\nFening', fontSize: sw * 0.04),
                Status: Image.asset('assets/close.png'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
