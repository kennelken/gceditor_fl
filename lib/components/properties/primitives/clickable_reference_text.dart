import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';

class ClickableReferenceText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback? onJumpToDefinition;
  final bool canJump;
  final int maxLines;
  final TextOverflow overflow;

  const ClickableReferenceText({
    super.key,
    required this.text,
    required this.style,
    this.onJumpToDefinition,
    this.canJump = true,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  ConsumerState<ClickableReferenceText> createState() => _ClickableReferenceTextState();
}

class _ClickableReferenceTextState extends ConsumerState<ClickableReferenceText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isControlPressed = ref.watch(clientViewModeStateProvider).state.controlKey ||
        HardwareKeyboard.instance.isControlPressed;

    final isHighlighted = _isHovered && isControlPressed && widget.canJump && widget.onJumpToDefinition != null;

    final effectiveStyle = isHighlighted
        ? widget.style.copyWith(
            color: kTextColorLightBlue,
            decoration: TextDecoration.underline,
            decorationColor: kTextColorLightBlue,
          )
        : widget.style.copyWith(
            decoration: TextDecoration.none,
          );

    return MouseRegion(
      cursor: isHighlighted ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Text(
        widget.text,
        style: effectiveStyle,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}
