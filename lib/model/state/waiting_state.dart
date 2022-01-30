import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/utils/lock.dart';

final waitingStateProvider = ChangeNotifierProvider((_) => WaitingStateNotifier(WaitingState()));

class WaitingState {
  final Lock _lock = Lock();

  bool get isWaiting => _lock.locked;
}

class WaitingStateNotifier extends ChangeNotifier {
  final WaitingState state;
  WaitingStateNotifier(this.state);

  void toggleWaiting(Object requestor, bool value) {
    final updatedValue = state._lock.toggle(requestor, value);
    if (updatedValue != null) //
      notifyListeners();
  }
}
