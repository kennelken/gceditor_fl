import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';

class TextButtonTransparent extends StatelessWidget {
  final Widget child;
  final VoidCallback onClick;

  const TextButtonTransparent({
    required this.child,
    required this.onClick,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 35,
      minWidth: 0,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const Border(),
      color: kColorTransparent,
      onPressed: onClick,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: child,
    );
  }
}
