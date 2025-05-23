import 'package:flutter/material.dart';

class CustomMenuIcon extends StatelessWidget {
  const CustomMenuIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
            padding: EdgeInsets.only(right: 20, top: 40),
            child: Column(
              children: [
                Container(width: 24, height: 3, color: Colors.white),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(width: 24, height: 3, color: Colors.transparent),
                    Container(width: 18, height: 3, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 4),
                Container(width: 24, height: 3, color: Colors.white),
              ],
            )),
      ],
    );
  }
}
