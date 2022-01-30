import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/app_local_storage.dart';

final clientViewModeStateProvider = ChangeNotifierProvider((ref) => ClientViewModeStateNotifier(ClientViewModeState()));

class ClientViewModeState {
  bool _controlKey = false;
  bool _altKey = false;
  bool _shiftKey = false;
  bool _expandedMode = false;

  bool get expandedMode => _expandedMode;
  bool get actionsMode => _controlKey || _altKey || _expandedMode;

  bool get controlKey => _controlKey;
  bool get shiftKey => _shiftKey;

  ClientViewModeState() {
    _expandedMode = AppLocalStorage.instance.expandedMode ?? false;
  }
}

class ClientViewModeStateNotifier extends ChangeNotifier {
  final ClientViewModeState state;

  ClientViewModeStateNotifier(this.state);

  void toggleExpandedMode([bool? value]) {
    final newValue = value ?? !state._expandedMode;
    if (state._expandedMode == newValue) //
      return;

    state._expandedMode = newValue;
    AppLocalStorage.instance.expandedMode = state._expandedMode;
    notifyListeners();
  }

  void setControlKey(bool value) {
    if (state._controlKey == value) //
      return;

    state._controlKey = value;
    notifyListeners();
  }

  void setAltKey(bool value) {
    if (state._altKey == value) //
      return;

    state._altKey = value;
    notifyListeners();
  }

  void setShiftKey(bool value) {
    if (state._shiftKey == value) //
      return;

    state._shiftKey = value;
    notifyListeners();
  }
}
