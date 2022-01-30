import 'package:flutter/material.dart';

class ConditionalWrapper extends StatelessWidget {
  final bool enabled;
  final SingleChildRenderObjectWidget Function(Widget child)? wrapperBuilder;
  final Widget child;

  const ConditionalWrapper({
    Key? key,
    required this.wrapperBuilder,
    required this.enabled,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return enabled && wrapperBuilder != null ? wrapperBuilder!(child) : child;
  }
}
