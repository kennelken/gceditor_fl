import 'package:flutter/material.dart';

class PlatformOnly extends StatelessWidget {
  final Widget child;
  final Set<TargetPlatform>? only;
  final Set<TargetPlatform>? except;

  const PlatformOnly({
    super.key,
    required this.child,
    this.only,
    this.except,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (only != null && !(only?.contains(platform) ?? true)) return const SizedBox();
    if (except != null && (except?.contains(platform) ?? false)) return const SizedBox();
    return child;
  }
}
