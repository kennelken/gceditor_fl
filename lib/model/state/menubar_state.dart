import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';
import 'package:menu_bar/menu_bar.dart';

import '../../components/global_shortcuts.dart';
import '../../consts/consts.dart';
import '../../consts/loc.dart';
import '../../utils/utils.dart';
import 'client_problems_state.dart';
import 'client_view_mode_state.dart';

final menubarStateProvider = ChangeNotifierProvider((ref) {
  final notifier = MenubarStateNotifier(MenubarState());

  ref.read(clientOwnCommandsStateProvider).addListener(() {
    notifier.refresh();
  });

  ref.read(tableSelectionStateProvider).addListener(() {
    notifier.refresh();
  });

  return notifier;
});

class MenubarState {
  Func1<Widget, Widget>? menubar;
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

    nextUndoCommand() => providerContainer.read(clientOwnCommandsStateProvider).state.nextUndoCommand;
    nextRedoCommand() => providerContainer.read(clientOwnCommandsStateProvider).state.nextRedoCommand;
    hasNextProblem() => providerContainer.read(clientProblemsStateProvider).state.problems.length > 1;
    hasSelectedItem() => providerContainer.read(tableSelectionStateProvider).state.canBeDeselected();

    state.menubar = (app) => Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return SizedBox(
                  height: 18,
                  child: MenuBarWidget(
                    barStyle: const MenuStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      backgroundColor: WidgetStatePropertyAll(kColorPrimaryDarker2),
                      maximumSize: WidgetStatePropertyAll(Size(double.infinity, 28.0)),
                    ),
                    barButtonStyle: ButtonStyle(
                      textStyle: WidgetStatePropertyAll(kStyle.kTextExtraSmallLightest.copyWith(fontSize: 12, color: Colors.white)),
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
                      minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
                    ),
                    menuButtonStyle: ButtonStyle(
                      backgroundColor: const WidgetStatePropertyAll(kColorPrimaryDarker2),
                      textStyle: WidgetStatePropertyAll(kStyle.kTextExtraSmallDark.copyWith(fontSize: 12)),
                      minimumSize: const WidgetStatePropertyAll(Size(100, 32)),
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    ),
                    barButtons: [
                      BarButton(
                        text: Text(Loc.get.menubarFile, style: _styleBar()),
                        submenu: SubMenu(
                          menuItems: [
                            MenuButton(
                              text: Text(Loc.get.menubarProjectSettings, style: _styleMenuActive()),
                              onTap: GlobalShortcuts.openProjectSettings,
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(Loc.get.menubarRunGenerators, style: _styleMenuActive()),
                              onTap: GlobalShortcuts.runGenerators,
                              shortcutText: 'Ctrl+R',
                              shortcutStyle: _styleShortcut(),
                            ),
                          ],
                        ),
                      ),
                      BarButton(
                        text: Text(Loc.get.menubarEdit, style: _styleBar()),
                        submenu: SubMenu(
                          menuItems: [
                            MenuButton(
                              text: Text(
                                Loc.get.menubarUndo + (nextUndoCommand() != null ? ': ${nextUndoCommand()!.$type!.name}' : ''),
                                style: nextUndoCommand() != null ? _styleMenuActive() : _styleMenuInactive(),
                              ),
                              onTap: nextUndoCommand() != null ? GlobalShortcuts.undo : null,
                              shortcutText: 'Ctrl+Z',
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(
                                Loc.get.menubarRedo + (nextRedoCommand() != null ? ': ${nextRedoCommand()!.$type!.name}' : ''),
                                style: nextRedoCommand() != null ? _styleMenuActive() : _styleMenuInactive(),
                              ),
                              onTap: nextRedoCommand() != null ? GlobalShortcuts.redo : null,
                              shortcutText: 'Ctrl+Y',
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(Loc.get.menubarFind, style: _styleMenuActive()),
                              onTap: GlobalShortcuts.openFind,
                              shortcutText: 'Ctrl+F',
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(
                                Loc.get.menubarNextProblem,
                                style: hasNextProblem() ? _styleMenuActive() : _styleMenuInactive(),
                              ),
                              onTap: hasNextProblem() ? GlobalShortcuts.showNextProblem : null,
                              shortcutText: 'F8',
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(
                                Loc.get.closeSelectedItem,
                                style: hasSelectedItem() ? _styleMenuActive() : _styleMenuInactive(),
                              ),
                              onTap: hasSelectedItem() ? GlobalShortcuts.deselect : null,
                              shortcutText: 'Esc',
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(Loc.get.requestModelFromServer, style: _styleMenuActive()),
                              onTap: _requestModelFromServer,
                              shortcutStyle: _styleShortcut(),
                            ),
                          ],
                        ),
                      ),
                      BarButton(
                        text: Text(Loc.get.menubarView, style: _styleBar()),
                        submenu: SubMenu(
                          menuItems: [
                            MenuButton(
                              text: Text(Loc.get.expandedViewMenu, style: _styleMenuActive()),
                              onTap: GlobalShortcuts.toggleActions,
                              shortcutStyle: _styleShortcut(),
                              icon: Icon(
                                providerContainer.read(clientViewModeStateProvider).state.actionsMode
                                    ? FontAwesomeIcons.squareCheck
                                    : FontAwesomeIcons.square,
                                color: kTextColorLight.withAlpha(170),
                                size: 12,
                              ),
                            ),
                            MenuButton(
                              text: Text(Loc.get.menubarConsole, style: _styleMenuActive()),
                              onTap: GlobalShortcuts.toggleConsole,
                              shortcutText: '~',
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(Loc.get.menubarZoomIn, style: _styleMenuActive()),
                              onTap: GlobalShortcuts.zoomIn,
                              shortcutText: 'Ctrl+Numpad+',
                              shortcutStyle: _styleShortcut(),
                            ),
                            MenuButton(
                              text: Text(Loc.get.menubarZoomOut, style: _styleMenuActive()),
                              onTap: GlobalShortcuts.zoomOut,
                              shortcutText: 'Ctrl+Numpad-',
                              shortcutStyle: _styleShortcut(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: app,
                  ),
                );
              },
            )
          ],
        );

    notifyListeners();
  }

  TextStyle _styleBar() => kStyle.kTextExtraSmallLightest.copyWith(fontSize: 12, color: kTextColorLight);
  TextStyle _styleMenuActive() => kStyle.kTextExtraSmallLightest.copyWith(fontSize: 10.5, color: kTextColorLight, fontWeight: FontWeight.w400);
  TextStyle _styleMenuInactive() => kStyle.kTextExtraSmallLightest.copyWith(fontSize: 10.5, color: kTextColorLight.withAlpha(170));
  TextStyle _styleShortcut() => kStyle.kTextExtraSmallLightest.copyWith(fontSize: 10.5, color: kTextColorLight.withAlpha(170));

  void _removeMenubar() {
    if (state.menubar == null) //
      return;

    state.menubar = null;
    notifyListeners();
  }

  void _requestModelFromServer() {
    providerContainer.read(appStateProvider).state.clientApp!.reInitModel();
  }
}
