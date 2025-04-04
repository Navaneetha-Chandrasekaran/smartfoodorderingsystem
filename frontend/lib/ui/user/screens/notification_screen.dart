import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/constants.dart';
import '../../../models/titles.dart';
import '../../../sheets/navigator.dart';
import '../sheets/navbar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, String>> notifications = [
    {
      "title": "Order Ready for Pickup 🎉",
      "message": "Your order is ready! Pick it up now.",
      "time": "Just now",
      "icon": "🛍️"
    },
    {
      "title": "Your Order is on the Way 🚚",
      "message": "The delivery partner is arriving soon.",
      "time": "5 min ago",
      "icon": "📦"
    },
    {
      "title": "Payment Successful 💳",
      "message": "Transaction of ₹500 completed.",
      "time": "10 min ago",
      "icon": "💰"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Titles(title: 'Notifications 🛎️'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: secondaryColor,
        leading: InkWell(
          onTap: () => Navigation.navigateTo(context, CustomNavBar()),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: () {
                setState(() => notifications.clear());
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyNotificationUI()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Dismissible(
                  key: Key(notification["title"]!),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() => notifications.removeAt(index));
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: _buildNotificationCard(notification),
                );
              },
            ),
    );
  }

  /// **✨ Stylish Notification Card ✨**
  Widget _buildNotificationCard(Map<String, String> notification) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
          child: Text(notification["icon"]!, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          notification["title"]!,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          notification["message"]!,
          style: GoogleFonts.poppins(color: Colors.grey[700]),
        ),
        trailing: Text(
          notification["time"]!,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  /// **🎈 Empty State UI**
  Widget _buildEmptyNotificationUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/no-notifications.png', width: 180),
          const SizedBox(height: 20),
          Text(
            "No Notifications",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "You're all caught up! 🎉",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
