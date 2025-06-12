import 'package:flutter/material.dart';

class PrivacySection extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PrivacySection({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xff002114),
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xff00B063),
          ),
        ],
      ),
    );
  }
}
