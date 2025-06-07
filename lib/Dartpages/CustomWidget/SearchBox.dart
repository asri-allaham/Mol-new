import 'package:flutter/material.dart';

class CustomSearchBox extends StatefulWidget {
  final double width;
  final double height;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const CustomSearchBox({
    super.key,
    this.controller,
    this.onChanged,
    this.width = 300,
    this.height = 40,
    this.hintText = "Search by name",
  });

  @override
  State<CustomSearchBox> createState() => _CustomSearchBoxState();
}

class _CustomSearchBoxState extends State<CustomSearchBox> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double animatedWidth = _isFocused ? widget.width * 1.4 : widget.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 7000),
      curve: Curves.easeInOut,
      width: animatedWidth,
      height: widget.height,
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color.fromARGB(255, 214, 204, 204),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xff012C19),
          ),
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
