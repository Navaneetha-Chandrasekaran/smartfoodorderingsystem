import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';

class DrawerTile extends StatelessWidget {
  final SubTitles text;
  final IconData? icon;
  final void Function()? onTap;
  
  const DrawerTile({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: ListTile(
        title: text,
        leading: Icon(
          icon,
          color: Colors.black,
        ),
        onTap: onTap,
      ),
    );
  }
}