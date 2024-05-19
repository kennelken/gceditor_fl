import 'package:flutter/material.dart';

class ConditionalWrapper extends StatelessWidget {
  final bool enabled;
  final SingleChildRenderObjectWidget Function(Widget child)? wrapperBuilder;
  final Widget child;

  const ConditionalWrapper({
    super.key,
    required this.wrapperBuilder,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return enabled && wrapperBuilder != null ? wrapperBuilder!(child) : child;
  }
}
