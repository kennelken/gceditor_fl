import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/managers/startup/startup_flow.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/menubar_state.dart';

final startupProvider = ChangeNotifierProvider((_) => StartupManager.instance);

class StartupManager extends ChangeNotifier {
  static StartupManager? _instance;
  // ignore: prefer_constructors_over_static_methods
  static StartupManager get instance {
    _instance ??= StartupManager();
    return _instance!;
  }

  StartupFlow? startupFlow;

  void clear() {
    startupFlow?.clear();
    startupFlow = null;

    notifyListeners();
  }

  void createNewLoginFlowIfRequired(VoidCallback runApp) {
    if (startupFlow != null) //
      return;

    startupFlow = StartupFlow(runApp);
    startupFlow!.machine!.onAfterTransition.listen((event) {
      Future.delayed(const Duration(microseconds: 10)).then((value) => providerContainer.read(menubarStateProvider).refresh());
      providerContainer.read(logStateProvider).addMessage(
            LogEntry(LogLevel.log, 'StartupFlow: state changed "${event.source}" -> "${event.target}"'),
            silent: true,
          );
      notifyListeners();
    });
    startupFlow!.start();
  }
}
