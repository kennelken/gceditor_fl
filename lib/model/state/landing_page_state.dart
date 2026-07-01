import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../consts/config.dart';
import '../app_local_storage.dart';
import '../model_root.dart';
import 'app_state.dart';

final landingPageStateProvider = ChangeNotifierProvider((_) => LandingPageStateNotifier(LandingPageState()));

class LandingPageState {
  String? projectPath;
}

class LandingPageStateNotifier extends ChangeNotifier {
  final LandingPageState state;
  LandingPageStateNotifier(this.state);

  void setProjectPath(String? value) {
    state.projectPath = value;
    notifyListeners();
  }

  void initialize() {
    state.projectPath = AppLocalStorage.instance.projectPath;
    notifyListeners();
  }

  String getVisibleProjectPath() {
    return state.projectPath ?? path.join(providerContainer.read(appStateProvider).state.defaultProjectFolder!.path, Config.newProjectDefaultName);
  }
}
