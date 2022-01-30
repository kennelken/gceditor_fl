import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/utils/components/popup_messages.dart';

var errorNotifierProvider = StateProvider<ErrorNotifier>((_) => ErrorNotifier());

class ErrorNotifier {
  StreamSubscription? subscription;

  void start() {
    dispose();
    subscription = providerContainer.read(logStateProvider).state.onLog.stream.listen(_handleLogEntry);
  }

  void _handleLogEntry(LogEntry entry) {
    if (entry.level.index >= LogLevel.warning.index) {
      PopupMessages.show(_getMessageData(entry));
    }
  }

  PopupMessageData _getMessageData(LogEntry entry) {
    return PopupMessageData(
      message: entry.message,
      color: getColorByLogLevel(entry.level),
      duration: entry.level.index >= LogLevel.error.index ? const Duration(milliseconds: 3000) : null,
    );
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
  }
}
