import 'package:flutter/widgets.dart';

class KeyboardVisibilityObserver extends StatefulWidget {
  final Widget child;
  final Function(bool isKeyboardVisible) onKeyboardVisibilityChanged;

  const KeyboardVisibilityObserver({
    super.key,
    required this.child,
    required this.onKeyboardVisibilityChanged,
  });

  @override
  _KeyboardVisibilityObserverState createState() =>
      _KeyboardVisibilityObserverState();
}

class _KeyboardVisibilityObserverState extends State<KeyboardVisibilityObserver>
    with WidgetsBindingObserver {
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    bool isVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (_isKeyboardVisible != isVisible) {
      setState(() {
        _isKeyboardVisible = isVisible;
      });
      widget.onKeyboardVisibilityChanged(_isKeyboardVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
