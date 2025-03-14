import 'package:bitetimenew/models/constants.dart';
import 'package:bitetimenew/ui/screens/home_screen.dart';
import 'package:bitetimenew/ui/screens/settings_screen.dart';
import 'package:bitetimenew/ui/sheets/navbar.dart';
import '../ui/sheets/navigator.dart';
import 'package:bitetimenew/models/drawer_tile.dart';
import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';


class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    double sw = MediaQuery.of(context).size.width;
    double sh = MediaQuery.of(context).size.height;
    return Drawer(
      backgroundColor: secondaryColor,
      child: Column(
        children: [
          SizedBox(height: sh * 0.1),
          Icon(
            Icons.lock_open_rounded,
            size: sw * 0.1,
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Divider(color: Colors.black),
          ),

          //Home list:

          DrawerTile(
            text: SubTitles(title: 'H O M E'), 
            icon: Icons.home, 
            onTap: (){Navigation.navigateTo(context, CustomNavBar());}
          ),

          //Settings list:
          DrawerTile(
            text: SubTitles(title: 'S E T T I N G S'), 
            icon: Icons.settings, 
            onTap: (){Navigation.navigateTo(context, SettingsScreen());}
          ),
          
          //Logout list:
          DrawerTile(
            text: SubTitles(title: 'L O G O U T'), 
            icon: Icons.logout, 
            onTap: (){Navigation.navigateTo(context, SettingsScreen());}
          ),
        ],
      ),
    );
  }
}