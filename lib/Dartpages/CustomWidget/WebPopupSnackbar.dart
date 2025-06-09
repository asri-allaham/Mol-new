import 'package:flutter/material.dart';

class WebPopupSnackbar {
  static void showOnWebLaunch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    Duration delay = const Duration(seconds: 1),
    required String imagePath,
  }) {
    if (!isWeb()) return;

    Future.delayed(delay, () {
      _showPopup(
        context,
        imagePath: imagePath,
        title: title,
        subtitle: subtitle,
        buttonText: buttonText,
        onPressed: onPressed,
      );
    });
  }

  static bool isWeb() {
    return identical(0, 0.0);
  }

  static void _showPopup(
    BuildContext context, {
    required String imagePath,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 70,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.down,
            onDismissed: (_) => overlayEntry.remove(),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xffDADADA),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Color(0xff024023),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      overlayEntry.remove();
                      onPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff012113),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }
}
