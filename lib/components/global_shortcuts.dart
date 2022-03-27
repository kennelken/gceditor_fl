import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gceditor/components/history/history_dialog.dart';
import 'package:gceditor/components/settings/settings_view.dart';
import 'package:gceditor/components/settings/shortcuts_view.dart';
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
  static Map<ShortcutActivator, Intent> getIntents() {
    return {
      const SingleActivator(LogicalKeyboardKey.backquote): const ToggleConsoleIntent(),
      const SingleActivator(LogicalKeyboardKey.escape): const DeselectIntent(),
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true): const UndoIntent(),
      const SingleActivator(LogicalKeyboardKey.keyY, control: true): const RedoIntent(),
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): const FindIntent(),
      const SingleActivator(LogicalKeyboardKey.keyR, control: true): const RunGeneratorsIntent(),
      //const SingleActivator(LogicalKeyboardKey.add, control: true): const ZoomInIntent(),
      //const SingleActivator(LogicalKeyboardKey.greater, control: true): const ZoomInIntent(),
      //const SingleActivator(LogicalKeyboardKey.minus, control: true): const ZoomOutIntent(),
      const SingleActivator(LogicalKeyboardKey.zoomIn): const ZoomInIntent(),
      const SingleActivator(LogicalKeyboardKey.zoomOut): const ZoomOutIntent(),
      const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): const ZoomInIntent(),
      const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): const ZoomOutIntent(),
      const SingleActivator(LogicalKeyboardKey.f8): const NextProblemIntent(),
    };
  }

  static Map<Type, Action<Intent>> getActions() {
    return {
      ToggleConsoleIntent: CallbackAction<ToggleConsoleIntent>(
        onInvoke: (ToggleConsoleIntent intent) {
          toggleConsole();
          return null;
        },
      ),
      DeselectIntent: CallbackAction<DeselectIntent>(
        onInvoke: (DeselectIntent intent) {
          deselect();
          return null;
        },
      ),
      UndoIntent: CallbackAction<UndoIntent>(
        onInvoke: (UndoIntent intent) {
          undo();
          return null;
        },
      ),
      RedoIntent: CallbackAction<RedoIntent>(
        onInvoke: (RedoIntent intent) {
          redo();
          return null;
        },
      ),
      FindIntent: CallbackAction<FindIntent>(
        onInvoke: (FindIntent intent) {
          openFind();
          return null;
        },
      ),
      RunGeneratorsIntent: CallbackAction<RunGeneratorsIntent>(
        onInvoke: (RunGeneratorsIntent intent) {
          runGenerators();
          return null;
        },
      ),
      ZoomInIntent: CallbackAction<ZoomInIntent>(
        onInvoke: (ZoomInIntent intent) {
          zoomIn();
          return null;
        },
      ),
      ZoomOutIntent: CallbackAction<ZoomOutIntent>(
        onInvoke: (ZoomOutIntent intent) {
          zoomOut();
          return null;
        },
      ),
      NextProblemIntent: CallbackAction<NextProblemIntent>(
        onInvoke: (NextProblemIntent intent) {
          providerContainer.read(clientProblemsStateProvider).focusOnNextProblem(null);
          return null;
        },
      ),
    };
  }

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

  static void openShortcutsList() {
    showDialog(
      context: popupContext!,
      barrierColor: kColorTransparent,
      builder: (context) {
        return const Dialog(
          child: ShortcutsView(),
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
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<RawKeyboardEvents> createState() => _RawKeyboardEventsState();
}

class _RawKeyboardEventsState extends State<RawKeyboardEvents> {
  late final FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: _handleKeyEvent,
      child: widget.child,
      autofocus: true,
    );
  }

  void _handleKeyEvent(RawKeyEvent data) {
    providerContainer.read(clientViewModeStateProvider).setControlKey(data.isControlPressed);
    providerContainer.read(clientViewModeStateProvider).setAltKey(data.isAltPressed);
    providerContainer.read(clientViewModeStateProvider).setShiftKey(data.isShiftPressed);
  }
}


/* class _RawKeyboardEventsState extends State<RawKeyboardEvents> {
  late final FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: true,
      focusNode: focusNode,
      onKey: _handleKey,
      child: widget.child,
    );
  }

  KeyEventResult _handleKey(FocusNode node, RawKeyEvent event) {
    providerContainer.read(clientViewModeStateProvider).setControlKey(event.isControlPressed);
    return KeyEventResult.ignored;
  }
}
 */