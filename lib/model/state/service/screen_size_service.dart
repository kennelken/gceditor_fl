import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:window_size/window_size.dart';

final screenServiceProvider = ChangeNotifierProvider((_) => ScreenServiceNotifier(ScreenService()));

class ScreenServiceNotifier extends ChangeNotifier {
  final ScreenService state;
  ScreenServiceNotifier(this.state);

  @override
  void dispose() {
    super.dispose();

    state.dispose();
    notifyListeners();
  }
}

class ScreenService {
  bool _disposed = false;
  bool _initialized = false;

  Rect? _windowRect;

  Future init() async {
    await _restoreScreenSize();
    _startTrackingScreenSize();
  }

  Future _restoreScreenSize() async {
    try {
      final windowInfo = await getWindowInfo();

      setWindowMinSize(Config.minWidowSize);

      final savedWindowRect = AppLocalStorage.instance.windowRect;
      if (savedWindowRect == null || windowInfo.screen == null) {
        _initialized = true;
        return;
      }

      final allScreens = await getScreenList();

      _initialized = true;

      for (var screen in allScreens) {
        final intersection = screen.visibleFrame.intersect(savedWindowRect);
        if (intersection.width > 50 && intersection.height > 50) {
          setWindowFrame(savedWindowRect);
          return;
        }
      }
    } catch (e) {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.log, 'Exception in _restoreScreenSize. Probably the current platform is not supported.'));
    }
  }

  void _startTrackingScreenSize() async {
    while (!_disposed) {
      await Future.delayed(Config.pollWindowPositionPeriod);
      if (!_initialized) //
        continue;

      try {
        final windowInfo = await getWindowInfo();
        if (windowInfo.frame == _windowRect) //
          continue;

        _windowRect = windowInfo.frame;
        AppLocalStorage.instance.windowRect = _windowRect;
      } catch (e) {
        //
      }
    }
  }

  void dispose() {
    _disposed = true;
  }
}
