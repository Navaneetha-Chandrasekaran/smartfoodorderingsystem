import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Titles extends StatelessWidget {
  const Titles({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Text(title,
        style: GoogleFonts.roboto(
            fontSize: screenWidth * 0.07, fontWeight: FontWeight.bold));
  }
}

class Description extends StatelessWidget {
  const Description({
    super.key,
    required this.description,
  });

  final String description;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Text(description,
        style: GoogleFonts.roboto(
            fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600));
  }
}

class rowText extends StatelessWidget {
  const rowText({
    super.key,
    required this.text,
    required this.buttonText,
    required this.destination,
  });

  final String text;
  final String buttonText;
  final Widget destination;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => destination,
              ),
            );
          },
          child: Text(
            buttonText,
            style: GoogleFonts.roboto(
              color: const Color.fromARGB(255, 78, 173, 252),
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
