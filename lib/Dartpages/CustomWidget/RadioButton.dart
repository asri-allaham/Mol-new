import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double width;
  final double height;
  final List<Color>? colors;
  final double fontSize;
  final double bottomEdge = 0;
  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width = 300,
    this.height = 50,
    this.colors,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      Colors.green.shade900,
      Colors.green.shade600,
      Colors.green.shade900,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors ?? defaultColors,
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Container(
                height: height,
                width: width,
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
