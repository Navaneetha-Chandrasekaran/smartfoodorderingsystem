import 'package:flutter/material.dart';

import '../ui/user/sheets/navbar.dart';

class ConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConfirmationDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Cancel Order"),
      content: const Text("Are you sure you want to cancel your order?"),
      actions: <Widget>[
        // Cancel button: Just close the dialog
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text("Cancel"),
        ),
        // Confirm button: Call onConfirm and navigate to the CustomNavBar screen
        TextButton(
          onPressed: () {
            onConfirm(); // Call the cancel order logic passed as callback
            Navigator.of(context).pop(); // Close the dialog
            
            // Navigate to CustomNavBar and clear the stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CustomNavBar()),
              (route) => false, // This removes all previous routes from the stack
            );
          },
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}
