import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';

// ignore: must_be_immutable
class IconButtonTransparent extends StatelessWidget {
  final Widget icon;
  final VoidCallback onClick;
  late double size;
  final bool enabled;

  IconButtonTransparent({
    required this.icon,
    required this.onClick,
    required this.size,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: MaterialButton(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        color: kColorTransparent,
        onPressed: enabled ? onClick : null,
        child: icon,
      ),
    );
  }
}
