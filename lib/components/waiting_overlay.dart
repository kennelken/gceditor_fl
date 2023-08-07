import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/managers/startup/startup_manager.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/waiting_state.dart';
import 'package:loading_overlay/loading_overlay.dart';

class WaitingOverlay extends ConsumerWidget {
  final Widget child;

  const WaitingOverlay({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    final isLoading = (ref.watch(startupProvider).startupFlow?.isLoading() ?? true) ||
        (ref.watch(appStateProvider).state.needRestart) ||
        ref.watch(waitingStateProvider).state.isWaiting;
    return LoadingOverlay(
      isLoading: isLoading,
      color: Colors.black.withAlpha(100),
      child: child,
    );
  }
}
