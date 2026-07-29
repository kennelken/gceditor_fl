import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TooltipWrapper extends StatelessWidget {
  final Widget child;
  final String? message;
  final String? Function()? messageBuilder;
  final String? headerMessage;
  final String? Function()? headerMessageBuilder;
  final String? imagePath;

  const TooltipWrapper({
    super.key,
    required this.child,
    this.message,
    this.messageBuilder,
    this.headerMessage,
    this.headerMessageBuilder,
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

    var delay = kTooltipDelay;
    try {
      delay = Duration(milliseconds: (clientModel.settings.tooltipDelay * 1000).round());
    } catch (_) {}

    return Tooltip(
      ignorePointer: true,
      decoration: BoxDecoration(color: kColorPrimaryDarkest.withAlpha(240), borderRadius: kCardBorder),
      padding: EdgeInsets.all(7 * kStyle.globalScale),
      richMessage: WidgetSpan(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showImage)
              Padding(
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
            if (headerMessage != null || headerMessageBuilder != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _LazyTooltipText(
                  message: headerMessage,
                  messageBuilder: headerMessageBuilder,
                  style: kStyle.kTextExtraSmallInactive,
                ),
              ),
            _LazyTooltipText(
              message: message,
              messageBuilder: messageBuilder,
              style: kStyle.kTextExtraSmall,
            ),
          ],
        ),
      ),
      waitDuration: delay,
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
    if (text.isEmpty) {
      return const SizedBox();
    }

    final defaultStyle = style ?? kStyle.kTextExtraSmall;
    final inactiveStyle = kStyle.kTextExtraSmallInactive;

    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) {
        spans.add(const TextSpan(text: '\n'));
      }

      final colonIndex = line.indexOf(':');
      if (colonIndex != -1) {
        final label = line.substring(0, colonIndex + 1);
        final rest = line.substring(colonIndex + 1);
        spans.add(TextSpan(text: label, style: inactiveStyle));
        if (rest.isNotEmpty) {
          spans.add(TextSpan(text: rest, style: defaultStyle));
        }
      } else {
        spans.add(TextSpan(text: line, style: defaultStyle));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }
}
