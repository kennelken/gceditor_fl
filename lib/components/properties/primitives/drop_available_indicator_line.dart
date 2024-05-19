import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';

class DropAvailableIndicatorLine extends StatelessWidget {
  final bool visible;

  const DropAvailableIndicatorLine({
    super.key,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1 * kScale,
      color: visible ? kTextColorLight : kColorTransparent,
    );
  }
}
