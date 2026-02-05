import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          "SMILE",
          style: TextStyle(
              fontSize: 39,
              fontWeight: FontWeight.bold,
              color: Colors.blue),
        ),
        Text(
          "DENTAL",
          style: TextStyle(
              fontSize: 39,
              fontWeight: FontWeight.bold,
              color: Colors.lightBlue),
        ),
        Text(
          "CLINIC",
          style: TextStyle(
              fontSize: 39,
              fontWeight: FontWeight.bold,
              color: Colors.blue),
        ),
      ],
    );
  }
}
