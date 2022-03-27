import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:menubar/menubar.dart';

final menubarStateProvider = ChangeNotifierProvider((ref) {
  final notifier = MenubarStateNotifier(MenubarState());

  ref.read(clientOwnCommandsStateProvider).addListener(() {
    notifier.refresh();
  });

  return notifier;
});

class MenubarState {
  List<Submenu>? _items;
}

class MenubarStateNotifier extends ChangeNotifier {
  final MenubarState state;

  MenubarStateNotifier(this.state);

  void refresh() {
    _updateMenubar();
    notifyListeners();
  }

  void _updateMenubar() {
    if (providerContainer.read(appStateProvider).state.clientApp == null) {
      _removeMenubar();
      return;
    }

    final nextUndoCommand = providerContainer.read(clientOwnCommandsStateProvider).state.nextUndoCommand;
    final nextRedoCommand = providerContainer.read(clientOwnCommandsStateProvider).state.nextRedoCommand;

    state._items = [
      Submenu(
        label: Loc.get.menubarFile,
        children: [
          MenuItem(
            label: Loc.get.menubarProjectSettings,
            shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            onClicked: GlobalShortcuts.openProjectSettings,
          ),
          MenuItem(
            label: Loc.get.menubarRunGenerators,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            onClicked: GlobalShortcuts.runGenerators,
          ),
        ],
      ),
      Submenu(
        label: Loc.get.menubarEdit,
        children: [
          MenuItem(
            label: Loc.get.menubarUndo + (nextUndoCommand != null ? ': ${describeEnum(nextUndoCommand.$type!)}' : ''),
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            enabled: nextUndoCommand != null,
            onClicked: GlobalShortcuts.undo,
          ),
          MenuItem(
            label: Loc.get.menubarRedo + (nextRedoCommand != null ? ': ${describeEnum(nextRedoCommand.$type!)}' : ''),
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY),
            enabled: nextRedoCommand != null,
            onClicked: GlobalShortcuts.redo,
          ),
          MenuItem(
            label: Loc.get.menubarFind,
            onClicked: GlobalShortcuts.openFind,
          ),
          MenuItem(
            label: Loc.get.requestModelFromServer,
            onClicked: _requestModelFromServer,
          ),
        ],
      ),
      Submenu(
        label: Loc.get.menubarView,
        children: [
          MenuItem(
            label: Loc.get.expandedViewMenu,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.toggleActions, // is registered in GlobalShortcuts
          ),
          MenuItem(
            label: Loc.get.menubarConsole,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.toggleConsole, // is registered in GlobalShortcuts
          ),
          MenuItem(
            label: Loc.get.menubarZoomIn,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.zoomIn, // is registered in GlobalShortcuts
          ),
          MenuItem(
            label: Loc.get.menubarZoomOut,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.zoomOut, // is registered in GlobalShortcuts
          ),
          MenuItem(
            label: Loc.get.menubarShowShortcuts,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.openShortcutsList, // is registered in GlobalShortcuts
          ),
        ],
      ),
    ];

    if (!kIsWeb) //
      setApplicationMenu(state._items!);
  }

  void _removeMenubar() {
    if (state._items == null) //
      return;

    state._items = null;

    if (!kIsWeb) //
      setApplicationMenu([]);
  }

  void _requestModelFromServer() {
    providerContainer.read(appStateProvider).state.clientApp!.reInitModel();
  }
}
