import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/style_state.dart';

class TooltipWrapper extends StatelessWidget {
  final Widget child;
  final String? message;
  final String? Function()? messageBuilder;
  final String? imagePath;

  const TooltipWrapper({
    super.key,
    required this.child,
    this.message,
    this.messageBuilder,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null && messageBuilder == null) {
      return child;
    }
    if (message != null && message!.isEmpty) {
      return child;
    }

    final showImage = imagePath != null &&
        (imagePath!.endsWith('.png') ||
         imagePath!.endsWith('.jpg') ||
         imagePath!.endsWith('.jpeg') ||
         imagePath!.endsWith('.gif') ||
         imagePath!.endsWith('.webp') ||
         imagePath!.endsWith('.bmp')) &&
        File(imagePath!).existsSync();

    return Tooltip(
      decoration: BoxDecoration(color: kColorPrimaryDarkest.withAlpha(240), borderRadius: kCardBorder),
      padding: EdgeInsets.all(7 * kStyle.globalScale),
      richMessage: TextSpan(
        children: [
          if (showImage)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 200 * kStyle.globalScale,
                    maxHeight: 200 * kStyle.globalScale,
                  ),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          WidgetSpan(
            child: _LazyTooltipText(
              message: message,
              messageBuilder: messageBuilder,
              style: kStyle.kTextExtraSmall,
            ),
          ),
        ],
      ),
      waitDuration: kTooltipDelay,
      child: child,
    );
  }
}

class _LazyTooltipText extends StatelessWidget {
  final String? message;
  final String? Function()? messageBuilder;
  final TextStyle? style;

  const _LazyTooltipText({
    this.message,
    this.messageBuilder,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final text = message ?? messageBuilder?.call() ?? '';
    return Text(
      text,
      style: style,
    );
  }
}
