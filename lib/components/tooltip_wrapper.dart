import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/style_state.dart';

class TooltipWrapper extends StatelessWidget {
  final Widget child;
  final String? message;
  final String? imagePath;

  const TooltipWrapper({
    super.key,
    required this.child,
    required this.message,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final showImage = imagePath != null &&
        (imagePath!.endsWith('.png') ||
         imagePath!.endsWith('.jpg') ||
         imagePath!.endsWith('.jpeg') ||
         imagePath!.endsWith('.gif') ||
         imagePath!.endsWith('.webp') ||
         imagePath!.endsWith('.bmp')) &&
        File(imagePath!).existsSync();

    return (message?.isNotEmpty ?? false)
        ? Tooltip(
            decoration: BoxDecoration(color: kColorPrimaryDarkest.withAlpha(240), borderRadius: kCardBorder),
            padding: EdgeInsets.all(7 * kStyle.globalScale),
            richMessage: showImage
                ? TextSpan(
                    children: [
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
                      TextSpan(
                        text: '\n$message',
                        style: kStyle.kTextExtraSmall,
                      ),
                    ],
                  )
                : TextSpan(
                    text: message!,
                    style: kStyle.kTextExtraSmall,
                  ),
            waitDuration: kTooltipDelay,
            child: child,
          )
        : child;
  }
}
