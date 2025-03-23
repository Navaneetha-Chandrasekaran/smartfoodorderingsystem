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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(sh * 0.35), // ✅ Increased height to prevent overflow
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: Titles(title: 'Welcome'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                onPressed: (){
                  Navigation.navigateTo(context, NotficationScreen());
                }, 
                icon: Icon(
                  Icons.notifications, color: Colors.black,
                  size: sw * 0.08,
                )
              ),
            ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: sh * 0.07, horizontal: 20), // ✅ Reduced vertical padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SubTitles(title: 'Tap, Collect and Delight!'),
                            SizedBox(height: sh * 0.005),
                            Description(description: "Let's find your favourite food"),
                          ],
                        ),
                      ),
                      SizedBox(width: sw * 0.05),
                      Image.asset('assets/fav.png', width: sw * 0.2), // ✅ Added back but with proper size
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Column(
            children: [
              SizedBox(height: sh * 0.03),
              SubTitles(title: 'Dish Up Your Cravings!'),
              SizedBox(height: sh * 0.04),
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
                Status: Image.asset('assets/close.png')
              )
            ],
          ),
        ),
      ),
    );
  }
}
