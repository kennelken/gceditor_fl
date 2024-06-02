import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gceditor/components/history/history_dialog.dart';
import 'package:gceditor/components/settings/settings_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/db_network/history_item_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/service/client_data_selection_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:gceditor/utils/components/popup_messages.dart';

class GlobalShortcuts {
  static void toggleConsole() {
    providerContainer.read(logStateProvider).toggleVisible(null);
  }

  static void toggleActions() {
    providerContainer.read(clientViewModeStateProvider).toggleExpandedMode();
  }

  static void deselect() {
    final stateSelection = providerContainer.read(tableSelectionStateProvider);
    if (stateSelection.state.selectedField != null) {
      stateSelection.setSelectedField();
    } else if (stateSelection.state.selectedEntity != null) {
      stateSelection.setSelectedEntity();
    }

    providerContainer.read(clientFindStateProvider).toggleVisibility(false);
    providerContainer.read(clientDataSelectionStateProvider).clear(false);
  }

  static void undo() {
    providerContainer.read(clientOwnCommandsStateProvider).undo();
  }

  static void redo() {
    providerContainer.read(clientOwnCommandsStateProvider).redo();
  }

  static void openFind() {
    providerContainer.read(clientFindStateProvider).toggleVisibility(true);
    providerContainer.read(selectFindFieldProvider).dispatchEvent();
  }

  static void zoomIn() {
    _zoom(true);
  }

  static void zoomOut() {
    _zoom(false);
  }

  static void showNextProblem() {
    providerContainer.read(clientProblemsStateProvider).focusOnNextProblem(null);
  }

  static void _zoom(bool zoomIn) {
    final notifier = providerContainer.read(styleStateProvider);
    final newScale = notifier.state.globalScale * (zoomIn ? Config.globalScaleStep : (1 / Config.globalScaleStep));
    if (notifier.state.globalScale == newScale) //
      return;

    notifier.setGlobalScale(newScale);
    _showCurrentScaleMessage();
  }

  static void _showCurrentScaleMessage() {
    final notifier = providerContainer.read(styleStateProvider);

    final message = '🔎${(notifier.state.globalScale * 100).round()}%';
    PopupMessages.show(PopupMessageData(message: message, duration: const Duration(milliseconds: 800)));
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, message));
  }

  static void openProjectSettings() {
    showDialog(
      context: popupContext!,
      barrierColor: kColorTransparent,
      builder: (context) {
        return const Dialog(
          child: SettingsView(),
        );
      },
    );
  }

  static void openHistory(HistoryItemData history) {
    showDialog(
      context: popupContext!,
      barrierColor: kColorTransparent,
      builder: (context) {
        return Dialog(
          child: HistoryDialog(data: history),
        );
      },
    );
  }

  static void runGenerators() {
    providerContainer.read(appStateProvider).requestRunGenerators();
  }
}

class ToggleConsoleIntent extends Intent {
  const ToggleConsoleIntent();
}

class DeselectIntent extends Intent {
  const DeselectIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class FindIntent extends Intent {
  const FindIntent();
}

class RunGeneratorsIntent extends Intent {
  const RunGeneratorsIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class NextProblemIntent extends Intent {
  const NextProblemIntent();
}

class RawKeyboardEvents extends StatefulWidget {
  final Widget child;

  const RawKeyboardEvents({
    super.key,
    required this.child,
  });

  @override
  State<RawKeyboardEvents> createState() => _RawKeyboardEventsState();
}

class _RawKeyboardEventsState extends State<RawKeyboardEvents> {
  late final FocusNode focusNode;

  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_handleKey);
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  bool _handleKey(KeyEvent data) {
    final isKeyDown = data is KeyDownEvent;

    switch (data.logicalKey) {
      case LogicalKeyboardKey.control:
      case LogicalKeyboardKey.controlLeft:
      case LogicalKeyboardKey.controlRight:
        providerContainer.read(clientViewModeStateProvider).setControlKey(isKeyDown);
        return true;

      case LogicalKeyboardKey.alt:
      case LogicalKeyboardKey.altLeft:
      case LogicalKeyboardKey.altRight:
        providerContainer.read(clientViewModeStateProvider).setAltKey(isKeyDown);
        return true;

      case LogicalKeyboardKey.shift:
      case LogicalKeyboardKey.shiftLeft:
      case LogicalKeyboardKey.shiftRight:
        providerContainer.read(clientViewModeStateProvider).setAltKey(isKeyDown);
        return true;

      case LogicalKeyboardKey.backquote:
        if (isKeyDown) {
          GlobalShortcuts.toggleConsole();
          return true;
        }
        break;

      case LogicalKeyboardKey.escape:
        if (isKeyDown) {
          GlobalShortcuts.deselect();
          return true;
        }
        break;

      case LogicalKeyboardKey.keyZ:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.undo();
          return true;
        }
        break;

      case LogicalKeyboardKey.keyY:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.redo();
          return true;
        }
        break;

      case LogicalKeyboardKey.keyF:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.openFind();
          return true;
        }
        break;

      case LogicalKeyboardKey.keyR:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.runGenerators();
          return true;
        }
        break;

      case LogicalKeyboardKey.zoomIn:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.zoomIn();
          return true;
        }
        break;

      case LogicalKeyboardKey.zoomOut:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.zoomOut();
          return true;
        }
        break;

      case LogicalKeyboardKey.numpadAdd:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.zoomIn();
          return true;
        }
        break;

      case LogicalKeyboardKey.numpadSubtract:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.zoomOut();
          return true;
        }
        break;

      case LogicalKeyboardKey.f8:
        if (isKeyDown && providerContainer.read(clientViewModeStateProvider).state.controlKey) {
          GlobalShortcuts.showNextProblem();
          return true;
        }
        break;
    }
    return false;
  }
}
