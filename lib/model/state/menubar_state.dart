import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:menubar/menubar.dart' as menu_bar;

final menubarStateProvider = ChangeNotifierProvider((ref) {
  final notifier = MenubarStateNotifier(MenubarState());

  ref.read(clientOwnCommandsStateProvider).addListener(() {
    notifier.refresh();
  });

  return notifier;
});

class MenubarState {
  List<menu_bar.Submenu>? _items;
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
      menu_bar.Submenu(
        label: Loc.get.menubarFile,
        children: [
          menu_bar.MenuItem(
            label: Loc.get.menubarProjectSettings,
            shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            onClicked: GlobalShortcuts.openProjectSettings,
          ),
          menu_bar.MenuItem(
            label: Loc.get.menubarRunGenerators,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            onClicked: GlobalShortcuts.runGenerators,
          ),
        ],
      ),
      menu_bar.Submenu(
        label: Loc.get.menubarEdit,
        children: [
          menu_bar.MenuItem(
            label: Loc.get.menubarUndo + (nextUndoCommand != null ? ': ${describeEnum(nextUndoCommand.$type!)}' : ''),
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            enabled: nextUndoCommand != null,
            onClicked: GlobalShortcuts.undo,
          ),
          menu_bar.MenuItem(
            label: Loc.get.menubarRedo + (nextRedoCommand != null ? ': ${describeEnum(nextRedoCommand.$type!)}' : ''),
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY),
            enabled: nextRedoCommand != null,
            onClicked: GlobalShortcuts.redo,
          ),
          menu_bar.MenuItem(
            label: Loc.get.menubarFind,
            onClicked: GlobalShortcuts.openFind,
          ),
          menu_bar.MenuItem(
            label: Loc.get.requestModelFromServer,
            onClicked: _requestModelFromServer,
          ),
        ],
      ),
      menu_bar.Submenu(
        label: Loc.get.menubarView,
        children: [
          menu_bar.MenuItem(
            label: Loc.get.expandedViewMenu,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.toggleActions, // is registered in GlobalShortcuts
          ),
          menu_bar.MenuItem(
            label: Loc.get.menubarConsole,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.toggleConsole, // is registered in GlobalShortcuts
          ),
          menu_bar.MenuItem(
            label: Loc.get.menubarZoomIn,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.zoomIn, // is registered in GlobalShortcuts
          ),
          menu_bar.MenuItem(
            label: Loc.get.menubarZoomOut,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.zoomOut, // is registered in GlobalShortcuts
          ),
          menu_bar.MenuItem(
            label: Loc.get.menubarShowShortcuts,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onClicked: GlobalShortcuts.openShortcutsList, // is registered in GlobalShortcuts
          ),
        ],
      ),
    ];

    if (!kIsWeb) //
      menu_bar.setApplicationMenu(state._items!);
  }

  void _removeMenubar() {
    if (state._items == null) //
      return;

    state._items = null;

    if (!kIsWeb) //
      menu_bar.setApplicationMenu([]);
  }

  void _requestModelFromServer() {
    providerContainer.read(appStateProvider).state.clientApp!.reInitModel();
  }
}
