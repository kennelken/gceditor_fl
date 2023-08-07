import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/style_state.dart';

class TooltipWrapper extends StatelessWidget {
  final Widget child;
  final String? message;

  const TooltipWrapper({
    Key? key,
    required this.child,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (message?.isNotEmpty ?? false)
        ? Tooltip(
            decoration: BoxDecoration(color: kColorPrimaryDarkest.withAlpha(240), borderRadius: kCardBorder),
            padding: EdgeInsets.all(7 * kStyle.globalScale),
            message: message!,
            textStyle: kStyle.kTextExtraSmall,
            waitDuration: kTooltipDelay,
            child: child,
          )
        : child;
  }
}
