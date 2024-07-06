import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

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
      WidgetsFlutterBinding.ensureInitialized();
      await windowManager.ensureInitialized();

      await windowManager.setMinimumSize(Config.minWidowSize);

      final savedWindowRect = AppLocalStorage.instance.windowRect;
      if (savedWindowRect == null) {
        _initialized = true;
        return;
      }

      _initialized = true;

      final displayList = await screenRetriever.getAllDisplays();
      final intersections = displayList.map((d) => ((d.visiblePosition ?? const Offset(0, 0)) & d.size).intersect(savedWindowRect));

      if (intersections.any((e) => e.width > 50 && e.height > 50)) {
        windowManager.setBounds(savedWindowRect);
        return;
      }
    } catch (e) {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.log, 'Exception in _restoreScreenSize. Probably the current platform is not supported.'));
    } finally {
      windowManager.show();
      windowManager.focus();
    }
  }

  void _startTrackingScreenSize() async {
    while (!_disposed) {
      await Future.delayed(Config.pollWindowPositionPeriod);
      if (!_initialized) //
        continue;

      try {
        final bounds = await windowManager.getBounds();
        if (bounds == _windowRect) //
          continue;

        _windowRect = bounds;
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
