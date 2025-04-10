import 'package:bitetimenew/models/titles.dart';
import 'package:flutter/material.dart';

class ErrorDialog {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Error",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: screenWidth * 0.04),
              SubTitles(title: title),
            ],
          ),
          content: Text(message),
          actions: [
            if (onRetry != null)
              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.green),
                label: const Description(description: "Try Again"),
                onPressed: () {
                  Navigator.pop(context);
                  onRetry();
                },
              ),
            TextButton(
              child: const Description(description: "Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim.value),
          child: Opacity(
            opacity: anim.value,
            child: child,
          ),
        );
      },
    );
  }
}