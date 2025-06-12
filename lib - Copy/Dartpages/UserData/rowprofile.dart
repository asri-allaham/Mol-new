import 'package:flutter/material.dart';

class ReusableRow extends StatelessWidget {
  final IconData icon;
  final String firstText;
  final String? secondText;
  final double iconSize;
  final Color firstTextColor;
  final Color secondTextColor;

  const ReusableRow({
    super.key,
    required this.icon,
    required this.firstText,
    this.secondText = "",
    this.iconSize = 27,
    this.firstTextColor = const Color(0xff012113),
    this.secondTextColor = const Color(0xff00914B),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 372,
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(
            icon,
            size: iconSize,
          ),
          const SizedBox(width: 17),
          Text(
            firstText,
            style: TextStyle(
              color: firstTextColor,
              fontSize: 18,
            ),
          ), //
          Spacer(),
          Text(
            secondText!,
            style: TextStyle(
              color: secondTextColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
