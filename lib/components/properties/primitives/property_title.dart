import 'package:flutter/material.dart';
import 'package:gceditor/model/state/style_state.dart';

class PropertyTitle extends StatelessWidget {
  final String title;

  const PropertyTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: kStyle.kTextExtraSmallPropertyHeader,
    );
  }
}
