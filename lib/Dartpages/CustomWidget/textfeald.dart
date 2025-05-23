import 'package:flutter/material.dart';

class Input extends StatefulWidget {
  final hintText;
  const Input({super.key,required this.hintText});

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10,right: 60,top: 12),
      child: SizedBox(
        height: 41, // Reduced height
        width: 280, // Fixed width
        child: TextField(
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: Colors.grey[100],
            isDense: true, // Reduces internal padding
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none, // Removes default border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}