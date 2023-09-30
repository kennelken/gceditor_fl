import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/utils/scheduler.dart';

final logStateProvider = ChangeNotifierProvider((_) => LogStateNotifier(LogState())..setLoggingLevel(Config.loggingLevel));

class LogState {
  final onLog = StreamController<LogEntry>();

  final messages = <LogEntry>[];
  LogLevel logLevel = LogLevel.debug;
  bool visible = false;
}

class LogStateNotifier extends ChangeNotifier {
  final LogState state;

  LogStateNotifier(this.state);

  void setLoggingLevel(LogLevel logLevel) {
    state.logLevel = logLevel;
    notifyListeners();
  }

  void addMessage(LogEntry entry, {bool silent = false}) {
    if (entry.level.index < state.logLevel.index) //
      return;

    state.messages.add(entry);
    print('${entry.level}: ${entry.message}');

    state.onLog.add(entry);

    if (!silent) {
      Scheduler.addPostFrameCallback(this, (d) => notifyListeners);
    }
  }

  void toggleVisible(bool? visible) {
    state.visible = visible ?? !state.visible;
    notifyListeners();
  }
}

class LogEntry {
  late DateTime time;
  LogLevel level;
  String message;

  LogEntry(this.level, this.message) {
    time = DateTime.now();
  }
}

enum LogLevel {
  debug,
  log,
  warning,
  error,
  assertion,
  critical,
}

Color getColorByLogLevel(LogLevel logLevel) {
  switch (logLevel) {
    case LogLevel.debug:
      return kTextColorLightHalfTransparent;

    case LogLevel.log:
      return kTextColorLightest;

    case LogLevel.warning:
      return Colors.yellow;

    case LogLevel.error:
      return Colors.redAccent.shade700;

    case LogLevel.assertion:
      return Colors.red.shade900;

    case LogLevel.critical:
      return Colors.purple;
  }
}

class LogStateReportHandler {
  Future<bool> handleError(FlutterErrorDetails error) {
    return handle(error.exceptionAsString());
  }

  Future<bool> handle(String error) {
    providerContainer.read(logStateProvider).addMessage(
          LogEntry(
            LogLevel.error,
            'error: ${error.trimRight()}',
          ),
        );
    return Future.value(true);
  }
}
