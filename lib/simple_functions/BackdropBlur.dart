import 'dart:ui';
import 'package:flutter/material.dart';

class BackdropBlur extends StatelessWidget {
  final bool isKeyboardVisible;

  const BackdropBlur({super.key, required this.isKeyboardVisible});

  @override
  Widget build(BuildContext context) {
    return isKeyboardVisible
        ? BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              color: const Color.fromARGB(255, 235, 237, 236).withOpacity(0.1),
            ),
          )
        : const SizedBox.shrink();
  }
}
