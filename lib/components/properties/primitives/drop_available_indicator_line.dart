import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';

class DropAvailableIndicatorLine extends StatelessWidget {
  final bool visible;

  const DropAvailableIndicatorLine({
    Key? key,
    this.visible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1 * kScale,
      color: visible ? kTextColorLight : kColorTransparent,
    );
  }
}
