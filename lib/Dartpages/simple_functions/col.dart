import 'package:flutter/material.dart';

class PrivacySection extends StatelessWidget {
  final String title;
  final String content;

  const PrivacySection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: Color(0xff002114),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 25),
        Text(
          content,
          style: TextStyle(
            color: Color(0xff002114),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
