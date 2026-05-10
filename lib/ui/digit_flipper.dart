import 'package:flutter/material.dart';

class DigitFlipper extends StatelessWidget {
  final String char;
  final TextStyle style;

  const DigitFlipper({
    super.key,
    required this.char,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final inAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.5),
          end: Offset.zero,
        ).animate(animation);
        final outAnimation = Tween<Offset>(
          begin: const Offset(0.0, -0.5),
          end: Offset.zero,
        ).animate(animation);

        if (child.key == ValueKey(char)) {
          return SlideTransition(position: inAnimation, child: FadeTransition(opacity: animation, child: child));
        } else {
          return SlideTransition(position: outAnimation, child: FadeTransition(opacity: animation, child: child));
        }
      },
      child: Text(
        char,
        key: ValueKey(char),
        style: style,
      ),
    );
  }
}
