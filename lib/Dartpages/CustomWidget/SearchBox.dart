import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomSearchBox extends StatelessWidget {
  final double width;
  final double height;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  String? hintText;
  CustomSearchBox({
    super.key,
    this.controller,
    this.onChanged,
    this.width = 300,
    this.height = 40,
    String hintText = "none",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color.fromARGB(255, 214, 204, 204),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xff012C19),
          ),
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
    );
  }
}
