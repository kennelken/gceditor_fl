import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/utils/components/popup_messages.dart';

class DeleteButton extends StatelessWidget {
  final VoidCallback onAction;
  final double? size;
  final double? width;
  final Color? color;
  final String tooltipText;

  const DeleteButton({
    Key? key,
    required this.onAction,
    this.size,
    this.width,
    this.color,
    required this.tooltipText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (width ?? (size ?? 20) + 15) * kScale,
      child: TooltipWrapper(
        message: tooltipText,
        child: MaterialButton(
          padding: EdgeInsets.zero,
          onPressed: () => PopupMessages.show(PopupMessageData(message: Loc.get.longTapToDelete)),
          onLongPress: onAction,
          child: FittedBox(
            child: Icon(
              FontAwesomeIcons.trashAlt,
              color: color ?? kColorPrimaryLightTransparent,
              size: (size ?? 20) * kScale,
            ),
          ),
        ),
      ),
    );
  }
}
