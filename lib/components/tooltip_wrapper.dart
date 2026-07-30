import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TooltipWrapper extends StatefulWidget {
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
  State<TooltipWrapper> createState() => _TooltipWrapperState();
}

class _TooltipWrapperState extends State<TooltipWrapper> {
  OverlayEntry? _entry;
  Timer? _timer;

  void _hideTooltip() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  void _scheduleShow() {
    _hideTooltip();
    var delay = kTooltipDelay;
    try {
      delay = Duration(milliseconds: (clientModel.settings.tooltipDelay * 1000).round());
    } catch (_) {}

    _timer = Timer(delay, () {
      if (mounted) {
        _showTooltip();
      }
    });
  }

  void _showTooltip() {
    _hideTooltip();
    if (!mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    try {
      renderBox.localToGlobal(Offset.zero);
    } catch (_) {
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (context) {
        if (!mounted) return const SizedBox();
        final currentBox = this.context.findRenderObject() as RenderBox?;
        if (currentBox == null || !currentBox.attached) {
          return const SizedBox();
        }

        Offset currentTarget;
        try {
          currentTarget = currentBox.localToGlobal(Offset.zero);
        } catch (_) {
          return const SizedBox();
        }

        final size = currentBox.size;
        final screenSize = MediaQuery.of(context).size;

        final showImage = widget.imagePath != null &&
            (widget.imagePath!.endsWith('.png') ||
                widget.imagePath!.endsWith('.jpg') ||
                widget.imagePath!.endsWith('.jpeg') ||
                widget.imagePath!.endsWith('.gif') ||
                widget.imagePath!.endsWith('.webp') ||
                widget.imagePath!.endsWith('.bmp')) &&
            File(widget.imagePath!).existsSync();

        final tooltipContent = Container(
          decoration: BoxDecoration(
            color: kColorPrimaryDarkest.withAlpha(240),
            borderRadius: kCardBorder,
          ),
          padding: EdgeInsets.all(7 * kStyle.globalScale),
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
                      File(widget.imagePath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              if (widget.headerMessage != null || widget.headerMessageBuilder != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _LazyTooltipText(
                    message: widget.headerMessage,
                    messageBuilder: widget.headerMessageBuilder,
                    style: kStyle.kTextExtraSmallInactive,
                  ),
                ),
              _LazyTooltipText(
                message: widget.message,
                messageBuilder: widget.messageBuilder,
                style: kStyle.kTextExtraSmall,
              ),
            ],
          ),
        );

        double top = currentTarget.dy + size.height + 4;
        if (top > screenSize.height - 80) {
          top = (currentTarget.dy - 40).clamp(8.0, screenSize.height - 40);
        }
        double left = currentTarget.dx.clamp(8.0, (screenSize.width - 220).clamp(8.0, screenSize.width));

        return Positioned(
          left: left,
          top: top,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: tooltipContent,
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
  }

  @override
  void deactivate() {
    _hideTooltip();
    super.deactivate();
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message == null && widget.messageBuilder == null) {
      return widget.child;
    }
    if (widget.message != null && widget.message!.isEmpty) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _hideTooltip(),
      child: MouseRegion(
        onEnter: (_) => _scheduleShow(),
        onExit: (_) => _hideTooltip(),
        child: widget.child,
      ),
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
