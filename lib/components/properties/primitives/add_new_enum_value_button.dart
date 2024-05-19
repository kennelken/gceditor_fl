import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/state/style_state.dart';

class AddNewEnumValueButton extends StatelessWidget {
  final VoidCallback onClick;

  const AddNewEnumValueButton({
    super.key,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30 * kScale,
      child: TextButton.icon(
        style: kButtonTransparent.copyWith(alignment: Alignment.centerLeft),
        onPressed: onClick,
        icon: Icon(
          FontAwesomeIcons.plus,
          color: kColorAccentBlue,
          size: 20 * kScale,
        ),
        label: Text(
          Loc.get.addNewItem,
          style: kStyle.kTextSmall,
        ),
      ),
    );
  }
}
