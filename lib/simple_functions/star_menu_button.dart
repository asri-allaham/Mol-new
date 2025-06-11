import 'package:flutter/material.dart';
import 'package:star_menu/star_menu.dart';

class StarMenuButton extends StatelessWidget {
  final List<Widget> items;
  final void Function(int index)? onItemTapped;

  const StarMenuButton({
    Key? key,
    required this.items,
    this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StarMenu(
      params: StarMenuParameters(rotateItemsAnimationAngle: 20),
      onStateChanged: (state) {
        print("Menu state: $state");
      },
      onItemTapped: (index, controller) {
        if (onItemTapped != null) {
          onItemTapped!(index);
        }
        controller.closeMenu!();
      },
      items: items,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: IconButton(
          icon: Icon(Icons.more_vert),
          iconSize: 24,
          splashRadius: 20,
          onPressed: () {
            print("Main menu button tapped");
          },
          tooltip: 'Open menu',
        ),
      ),
    );
  }
}
