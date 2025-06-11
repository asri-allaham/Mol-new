import 'package:Mollni/Dartpages/UserData/rowprofile.dart';
import 'package:flutter/material.dart';

Widget buildSettingsGroup(List<Widget> children) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffE5E5E5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget buildRow({
  required IconData icon,
  required String label,
  String? trailing = "",
  VoidCallback? onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: InkWell(
      onTap: onTap,
      child: ReusableRow(
        icon: icon,
        firstText: label,
        secondText: trailing,
      ),
    ),
  );
}
