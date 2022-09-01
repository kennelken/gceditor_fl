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
  List<menu_bar.NativeSubmenu>? _items;
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
      menu_bar.NativeSubmenu(
        label: Loc.get.menubarFile,
        children: [
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarProjectSettings,
            shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            onSelected: GlobalShortcuts.openProjectSettings,
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarRunGenerators,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            onSelected: GlobalShortcuts.runGenerators,
          ),
        ],
      ),
      menu_bar.NativeSubmenu(
        label: Loc.get.menubarEdit,
        children: [
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarUndo + (nextUndoCommand != null ? ': ${describeEnum(nextUndoCommand.$type!)}' : ''),
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ),
            onSelected: nextUndoCommand != null ? GlobalShortcuts.undo : null,
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarRedo + (nextRedoCommand != null ? ': ${describeEnum(nextRedoCommand.$type!)}' : ''),
            //shortcut: LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY),
            onSelected: nextRedoCommand != null ? GlobalShortcuts.redo : null,
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarFind,
            onSelected: GlobalShortcuts.openFind,
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.requestModelFromServer,
            onSelected: _requestModelFromServer,
          ),
        ],
      ),
      menu_bar.NativeSubmenu(
        label: Loc.get.menubarView,
        children: [
          menu_bar.NativeMenuItem(
            label: Loc.get.expandedViewMenu,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onSelected: GlobalShortcuts.toggleActions, // is registered in GlobalShortcuts
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarConsole,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onSelected: GlobalShortcuts.toggleConsole, // is registered in GlobalShortcuts
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarZoomIn,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onSelected: GlobalShortcuts.zoomIn, // is registered in GlobalShortcuts
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarZoomOut,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onSelected: GlobalShortcuts.zoomOut, // is registered in GlobalShortcuts
          ),
          menu_bar.NativeMenuItem(
            label: Loc.get.menubarShowShortcuts,
            //shortcut: LogicalKeySet(LogicalKeyboardKey.backquote),
            onSelected: GlobalShortcuts.openShortcutsList, // is registered in GlobalShortcuts
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
