import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Titles extends StatelessWidget {
  const Titles({
    super.key,
    required this.title,
    this.color
  });

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: screenWidth * 0.06, 
        fontWeight: FontWeight.w600,
        color: color
      )
    );
  }
}

class SubTitles extends StatelessWidget {
  final String title;
  final Color? color;
  final double? fontSize; // ✅ Allow custom font size

  const SubTitles({
    super.key,
    this.color,
    required this.title,
    this.fontSize, // ✅ Optional font size
  });

  @override
  Widget build(BuildContext context) {
    double defaultSize = MediaQuery.of(context).size.width * 0.05; // ✅ Responsive default size

    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: fontSize ?? defaultSize, // ✅ Use custom or default size
        fontWeight: FontWeight.w500,
        color: color
      ),
    );
  }
}

class Description extends StatelessWidget {
  const Description({
    super.key,
    required this.description,
    this.color
  });

  final String description;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Text(description,
        style: GoogleFonts.roboto(
            fontSize: screenWidth * 0.04, 
            fontWeight: FontWeight.w600,
            color: color
        ));
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
        Description(description: text),
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



class FoodName extends StatelessWidget {
  const FoodName({
    super.key,
    required this.foodName
  });
  final String foodName;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Text(
      foodName,
      style: GoogleFonts.roboto(
        fontSize: screenWidth * 0.04,
        fontWeight: FontWeight.w500
      ),
    );
  }
}

class FoodPrice extends StatelessWidget {
  const FoodPrice({
    super.key,
    required this.foodPrice
  });
  final String foodPrice;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Text(
      foodPrice,
      style: GoogleFonts.roboto(
        fontSize: screenWidth * 0.035,
        fontWeight: FontWeight.w600
      ),
    );
  }
}

class FoodDescription extends StatelessWidget {
  const FoodDescription({
    super.key,
    required this.description,
    this.color
  });
  final String description;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Text(
      description,
      style: GoogleFonts.roboto(
        fontSize: screenWidth * 0.03,
        fontWeight: FontWeight.w500,
        color: color
      ),
    );
  }
}