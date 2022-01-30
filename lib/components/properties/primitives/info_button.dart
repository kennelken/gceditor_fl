import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';

class InfoButton extends StatelessWidget {
  final String text;
  //final _defaultValueInfoController = CustomPopupMenuController();

  const InfoButton({
    required this.text,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20 * kScale,
      height: 20 * kScale,
      child: TooltipWrapper(
        message: text,
        child: Material(
          elevation: 0,
          shape: const CircleBorder(),
          color: kColorTransparent,
          child: Icon(
            FontAwesomeIcons.infoCircle,
            color: kTextColorLight,
            size: 20 * kScale,
          ),
        ),
      ),
    );
  }
}
