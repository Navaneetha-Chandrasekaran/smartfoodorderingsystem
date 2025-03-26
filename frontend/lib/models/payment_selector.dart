import 'package:flutter/material.dart';

import 'titles.dart';

class PaymentSelector extends StatelessWidget {
  final String selectedPayment;
  final Function(String) onPaymentChanged;

  const PaymentSelector({
    super.key,
    required this.selectedPayment,
    required this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: SubTitles(title: "Select Payment Method")),
        SizedBox(height: screenWidth * 0.05),
        Center(
          child: Container(
            width: screenWidth * 0.9,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 250, 250, 250),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 175, 175, 175),
                  spreadRadius: 1,
                  blurRadius: 2
                )
              ]
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPayment,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onPaymentChanged(newValue);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: "Cash",
                    child: Row(
                      children: [
                        Icon(Icons.money, color: Colors.green),
                        SizedBox(width: 10),
                        Text("Cash"),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: "GPay",
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.blue),
                        SizedBox(width: 10),
                        Text("GPay"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
