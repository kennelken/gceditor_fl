import 'dart:math';

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/data_selection/data_selection_panel.dart';
import 'package:gceditor/components/find/find_panel.dart';
import 'package:gceditor/components/git/table_git_view.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/components/history/table_history_view.dart';
import 'package:gceditor/components/pinned/pinned_panel.dart';
import 'package:gceditor/components/problems/table_problems_view.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/table/context_menu_button.dart';
import 'package:gceditor/components/table/data_table/data_table_view.dart';
import 'package:gceditor/components/table/data_table_header.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/components/tree/table_classes_view.dart';
import 'package:gceditor/components/tree/table_tables_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_new_class.dart';
import 'package:gceditor/model/db_cmd/db_cmd_add_new_table.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_git_state.dart';
import 'package:gceditor/model/state/client_history_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/service/client_data_selection_state.dart';
import 'package:gceditor/model/state/settings_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

final _addClassController = CustomPopupMenuController();
final _addTableController = CustomPopupMenuController();

class TableView extends ConsumerWidget {
  const TableView({super.key});

  @override
  Widget build(context, ref) {
    final gitState = ref.watch(clientGitStateProvider).state;
    final historyState = ref.watch(clientHistoryStateProvider).state;
    final settingsState = ref.watch(settingsStateProvider).state;
    final problemsState = ref.watch(clientProblemsStateProvider).state;
    final findState = ref.watch(clientFindStateProvider).state;
    final pinnedState = ref.watch(pinnedItemsStateProvider).state;
    final dataSelectionState = ref.watch(clientDataSelectionStateProvider).state;
    ref.watch(styleStateProvider);

    return Row(
      children: [
        Container(
          width: settingsState.classesWidth,
          color: kColorPrimaryLighter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _getPanelHeader(
                width: settingsState.classesWidth,
                onTap: _handleSettingsClick,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Loc.get.settingsTitle,
                        style: kStyle.kTextSmall,
                      ),
                    ),
                  ],
                ),
              ),
              _getPanelHeader(
                width: settingsState.classesWidth,
                onTap: _handleToggleTablesPanel,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Loc.get.tablesTitle,
                        style: kStyle.kTextSmall,
                      ),
                    ),
                    TooltipWrapper(
                      message: Loc.get.crateNewTableItem,
                      child: ContextMenuButton(
                        controller: _addTableController,
                        buttons: [
                          ContextMenuChildButtonData(Loc.get.contextMenuFolder, () => _addNewTable(TableMetaType.$group)),
                          ContextMenuChildButtonData(Loc.get.contextMenuTable, () => _addNewTable(TableMetaType.$table)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (settingsState.tablesExpanded)
                Expanded(
                  flex: (settingsState.tablesHeight * Config.flexRatioMultiplier).toInt(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(height: kDividerLineWidth, color: kColorPrimary),
                      const Expanded(child: TableTablesView()),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeRow,
                        child: GestureDetector(
                          onVerticalDragUpdate: (d) => _handleTablesHeightDrag(d, context),
                          child: Container(height: kDividerLineWidth, color: kColorPrimaryLighter),
                        ),
                      ),
                    ],
                  ),
                ),
              _getPanelHeader(
                width: settingsState.classesWidth,
                onTap: _handleToggleClassesPanel,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Loc.get.classesTitle,
                        style: kStyle.kTextSmall,
                      ),
                    ),
                    TooltipWrapper(
                      message: Loc.get.createNewClassTooltip,
                      child: ContextMenuButton(
                        controller: _addClassController,
                        buttons: [
                          ContextMenuChildButtonData(Loc.get.contextMenuFolder, () => _addNewClass(ClassMetaType.$group)),
                          ContextMenuChildButtonData(Loc.get.contextMenuEnum, () => _addNewClass(ClassMetaType.$enum)),
                          ContextMenuChildButtonData(Loc.get.contextMenuClass, () => _addNewClass(ClassMetaType.$class)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (settingsState.classesExpanded)
                Expanded(
                  flex: (settingsState.classesHeight * Config.flexRatioMultiplier).toInt(),
                  child: Column(
                    children: [
                      Container(height: kDividerLineWidth, color: kColorPrimaryLighter),
                      const Expanded(child: TableClassesView()),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeRow,
                        child: GestureDetector(
                          onVerticalDragUpdate: (d) => _handleClassesHeightDrag(d, context),
                          child: Container(height: kDividerLineWidth, color: kColorPrimaryLighter),
                        ),
                      ),
                    ],
                  ),
                ),
              _getPanelHeader(
                width: settingsState.classesWidth,
                onTap: _handleToggleProblemsPanel,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      Loc.get.problemsTitle,
                      style: kStyle.kTextSmall,
                    ),
                    const Expanded(child: SizedBox()),
                    Material(
                      color: kColorTransparent,
                      child: TooltipWrapper(
                        message: Loc.get.nextProblemTooltip,
                        child: InkWell(
                          enableFeedback: true,
                          splashColor: kColorPrimaryDarker,
                          highlightColor: kColorPrimaryDarker2,
                          hoverColor: kColorPrimary,
                          onTap: _handleProblemsClick,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FontAwesomeIcons.triangleExclamation,
                                size: 13 * kScale,
                                color: kColorAccentRed2,
                              ),
                              SizedBox(width: 5 * kScale),
                              Text(
                                problemsState.getProblems(ProblemSeverity.error).length.toString(),
                                style: kStyle.kTextSmall,
                              ),
                              SizedBox(width: 15 * kScale),
                              Icon(
                                FontAwesomeIcons.triangleExclamation,
                                size: 13 * kScale,
                                color: kColorAccentYellow,
                              ),
                              SizedBox(width: 5 * kScale),
                              Text(
                                problemsState.getProblems(ProblemSeverity.warning).length.toString(),
                                style: kStyle.kTextSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (settingsState.problemsExpanded)
                Expanded(
                  flex: (settingsState.problemsHeight * Config.flexRatioMultiplier).toInt(),
                  child: Column(
                    children: [
                      Container(height: kDividerLineWidth, color: kColorPrimaryLighter),
                      const Expanded(child: TableProblemsView()),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeRow,
                        child: GestureDetector(
                          onVerticalDragUpdate: (d) => _handleProblemsHeightDrag(d, context),
                          child: Container(height: kDividerLineWidth, color: kColorPrimaryLighter),
                        ),
                      ),
                    ],
                  ),
                ),
              if (gitState.hasAnyBranch()) ...[
                _getPanelHeader(
                  width: settingsState.classesWidth,
                  onTap: _handleToggleGitPanel,
                  child: Row(
                    children: [
                      Text(
                        Loc.get.gitTitle,
                        style: kStyle.kTextSmall,
                      ),
                      SizedBox(width: 10 * kScale),
                      Expanded(
                        child: Text(
                          Loc.get.gitSelected(gitState.selectedItems.length, gitState.items.length),
                          style: kStyle.kTextExtraSmallInactive,
                          maxLines: 1,
                        ),
                      ),
                      TooltipWrapper(
                        message: Loc.get.gitRefreshTooltip,
                        child: IconButtonTransparent(
                          size: 32 * kScale,
                          icon: Icon(
                            FontAwesomeIcons.rotate,
                            color: gitState.isProcessing ? kColorAccentBlueInactive : kColorAccentBlue,
                            size: 15 * kScale,
                          ),
                          onClick: () => providerContainer.read(clientGitStateProvider).refresh(),
                          enabled: !gitState.isProcessing,
                        ),
                      ),
                      TooltipWrapper(
                        message: Loc.get.gitCommitTooltip,
                        child: IconButtonTransparent(
                          size: 32 * kScale,
                          icon: Icon(
                            FontAwesomeIcons.floppyDisk,
                            color: gitState.isProcessing || gitState.selectedItems.isEmpty ? kColorAccentBlueInactive : kColorAccentBlue,
                            size: 15 * kScale,
                          ),
                          onClick: () => providerContainer.read(clientGitStateProvider).doCommit(),
                          enabled: !gitState.isProcessing && gitState.selectedItems.isNotEmpty,
                        ),
                      ),
                      TooltipWrapper(
                        message: Loc.get.gitPushTooltip,
                        child: IconButtonTransparent(
                          size: 32 * kScale,
                          icon: Icon(
                            FontAwesomeIcons.circleArrowUp,
                            color: gitState.isProcessing || gitState.selectedItems.isEmpty ? kColorAccentBlueInactive : kColorAccentBlue,
                            size: 15 * kScale,
                          ),
                          onClick: () => providerContainer.read(clientGitStateProvider).doPush(),
                          enabled: !gitState.isProcessing && gitState.selectedItems.isNotEmpty,
                        ),
                      ),
                      TooltipWrapper(
                        message: Loc.get.gitPullTooltip,
                        child: IconButtonTransparent(
                          size: 32 * kScale,
                          icon: Icon(
                            FontAwesomeIcons.circleArrowDown,
                            color: gitState.isProcessing || gitState.selectedItems.isEmpty ? kColorAccentBlueInactive : kColorAccentBlue,
                            size: 15 * kScale,
                          ),
                          onClick: () => providerContainer.read(clientGitStateProvider).doPull(),
                          enabled: !gitState.isProcessing && gitState.selectedItems.isNotEmpty,
                        ),
                      ),
                    ],
                  ),
                ),
                if (settingsState.gitExpanded)
                  Expanded(
                    flex: (settingsState.gitHeight * Config.flexRatioMultiplier).toInt(),
                    child: Column(
                      children: [
                        Container(height: kDividerLineWidth, color: kColorPrimaryLighter),
                        const Expanded(child: TableGitView()),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeRow,
                          child: GestureDetector(
                            onVerticalDragUpdate: (d) => _handleGitHeightDrag(d, context),
                            child: Container(height: kDividerLineWidth, color: kColorPrimaryLighter),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (historyState.hasAnyHistory()) ...[
                _getPanelHeader(
                  width: settingsState.classesWidth,
                  onTap: _handleToggleHistoryPanel,
                  child: Row(
                    children: [
                      Text(
                        Loc.get.historyTitle,
                        style: kStyle.kTextSmall,
                      ),
                      SizedBox(width: 10 * kScale),
                      if (historyState.currentTag != null) ...[
                        Expanded(
                          child: Text(
                            '#${historyState.currentTag}',
                            style: kStyle.kTextExtraSmallInactive,
                          ),
                        ),
                      ],
                      if (historyState.currentTag == null) ...[
                        const Expanded(child: SizedBox()),
                      ],
                      /* Expanded(
                        child: Text(
                          Loc.get.historyItemsCount(historyState.items.length),
                          style: kStyle.kTextExtraSmallInactive,
                          maxLines: 1,
                        ),
                      ), */
                      TooltipWrapper(
                        message: Loc.get.historyRefreshTooltip,
                        child: IconButtonTransparent(
                          size: 32 * kScale,
                          icon: Icon(
                            FontAwesomeIcons.rotate,
                            color: historyState.isProcessing ? kColorAccentBlueInactive : kColorAccentBlue,
                            size: 15 * kScale,
                          ),
                          onClick: () => providerContainer.read(clientHistoryStateProvider).refresh(),
                          enabled: !historyState.isProcessing,
                        ),
                      ),
                    ],
                  ),
                ),
                if (settingsState.historyExpanded)
                  Expanded(
                    flex: (settingsState.historyHeight * Config.flexRatioMultiplier).toInt(),
                    child: const TableHistoryView(),
                  ),
              ]
            ],
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: _handleClassesWidthDrag,
            child: Container(width: kDividerLineWidth, color: kColorPrimary),
          ),
        ),
        Expanded(
          child: Container(
            color: kColorPrimary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(kStyle.kLabelPadding),
                  alignment: Alignment.centerLeft,
                  color: kColorPrimaryDarker,
                  height: kStyle.kTableTopRowHeight,
                  child: const DataTableHeader(),
                ),
                Container(height: kDividerLineWidth, color: kColorPrimary),
                const DataTableView(),
                if (dataSelectionState.visible) ...[
                  Container(
                    height: kDividerLineWidth,
                    color: kColorPrimary,
                  ),
                  const DataSelectionPanel(),
                ],
                if (findState.visible) ...[
                  GestureDetector(
                    onVerticalDragUpdate: _handleFindHeightDrag,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeRow,
                      child: Container(
                        height: kDividerLineWidth,
                        color: kColorPrimary,
                      ),
                    ),
                  ),
                  Container(
                    height: settingsState.findHeight,
                    color: kColorPrimaryDarker,
                    child: const FindPanel(),
                  ),
                ],
                if (pinnedState.items.isNotEmpty) ...[
                  GestureDetector(
                    onVerticalDragUpdate: _handlePinnedPanelHeightDrag,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeRow,
                      child: Container(
                        height: kDividerLineWidth,
                        color: kColorPrimary,
                      ),
                    ),
                  ),
                  Container(
                    height: settingsState.pinnedPanelHeight,
                    color: kColorPrimaryDarker2,
                    child: const PinnedPanel(),
                  ),
                ],
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _getPanelHeader({
    required Widget child,
    required VoidCallback onTap,
    required width,
  }) {
    return Material(
      color: kColorPrimaryDarker,
      child: SizedBox(
        height: kStyle.kTableTopRowHeight,
        child: InkWell(
          enableFeedback: true,
          splashColor: kColorPrimaryDarker,
          highlightColor: kColorPrimaryDarker2,
          hoverColor: kColorPrimary,
          onTap: onTap,
          child: FittedBox(
            fit: BoxFit.none,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: kStyle.kLabelPadding),
              width: width,
              height: kStyle.kTableTopRowHeight,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  void _handleClassesWidthDrag(DragUpdateDetails details) {
    final width = providerContainer.read(settingsStateProvider).state.classesWidth;
    final newWidth = max(Config.minPanelsWidth, width + details.delta.dx);
    providerContainer.read(settingsStateProvider).setClassesWidth(newWidth);
  }

  void _handleTablesHeightDrag(DragUpdateDetails details, BuildContext context) {
    _handleHeightChange(0, details.delta.dy, context);
  }

  void _handleClassesHeightDrag(DragUpdateDetails details, BuildContext context) {
    _handleHeightChange(1, details.delta.dy, context);
  }

  void _handleProblemsHeightDrag(DragUpdateDetails details, BuildContext context) {
    _handleHeightChange(2, details.delta.dy, context);
  }

  void _handleGitHeightDrag(DragUpdateDetails details, BuildContext context) {
    _handleHeightChange(3, details.delta.dy, context);
  }

  void _handleHeightChange(int index, double delta, BuildContext context) {
    if (delta == 0.0) //
      return;

    const panelsCount = 4;
    final totalHeight = context.size!.height - panelsCount * kStyle.kTableTopRowHeight;

    final settingsProvider = providerContainer.read(settingsStateProvider);
    final settings = settingsProvider.state;

    const sum = Config.defaultClassesHeightRatio + Config.defaultTablesHeightRatio + Config.defaultProblemsHeightRatio;
    final minHeight = Config.minMainColumnHeightRatio * totalHeight;

    final isExpanded = <bool>[];
    final height = <double>[];

    isExpanded.add(settings.tablesExpanded);
    height.add(isExpanded[0] ? settings.tablesHeight * totalHeight : 0.0);

    isExpanded.add(settings.classesExpanded);
    height.add(isExpanded[1] ? settings.classesHeight * totalHeight : 0.0);

    isExpanded.add(settings.problemsExpanded);
    height.add(isExpanded[2] ? settings.problemsHeight * totalHeight : 0.0);

    isExpanded.add(settings.gitExpanded);
    height.add(isExpanded[3] ? settings.gitHeight * totalHeight : 0.0);

    isExpanded.add(settings.historyExpanded);
    height.add(isExpanded[4] ? settings.historyHeight * totalHeight : 0.0);

    final participantsIndexes = <int>[];
    for (var i = index; i < panelsCount; i++) {
      if (isExpanded[i]) //
        participantsIndexes.add(i);
    }

    if (participantsIndexes.length < 2) //
      return;

    height[participantsIndexes[0]] += delta;
    height[participantsIndexes[1]] -= delta;

    for (var i = 0; i < 2; i++) {
      final underMinHeight = minHeight - height[participantsIndexes[i]];
      if (underMinHeight > 0) {
        height[participantsIndexes[1 - i]] -= underMinHeight;
        height[participantsIndexes[i]] += underMinHeight;
      }
    }

    var resultingTotalHeight = 0.0;
    for (var i = 0; i < panelsCount; i++) {
      height[i] /= totalHeight;
      resultingTotalHeight += height[i];
    }

    final coeff = resultingTotalHeight / sum;
    for (var i = 0; i < panelsCount; i++) {
      height[i] /= coeff;
    }

    settingsProvider.setPanelHeightByIndex(participantsIndexes[0], height[participantsIndexes[0]]);
    settingsProvider.setPanelHeightByIndex(participantsIndexes[1], height[participantsIndexes[1]]);
  }

  void _handleFindHeightDrag(DragUpdateDetails details) {
    final delta = -details.delta.dy;
    if (delta == 0.0) //
      return;

    final settingsProvider = providerContainer.read(settingsStateProvider);
    final newHeight = (settingsProvider.state.findHeight + delta).clamp(Config.minFindHeight, Config.maxFindHeight);

    if (newHeight == settingsProvider.state.findHeight) //
      return;

    settingsProvider.setFindHeight(newHeight);
  }

  void _handlePinnedPanelHeightDrag(DragUpdateDetails details) {
    final delta = -details.delta.dy;
    if (delta == 0.0) //
      return;

    final settingsProvider = providerContainer.read(settingsStateProvider);
    final newHeight = (settingsProvider.state.pinnedPanelHeight + delta).clamp(Config.minPinnedPanelHeight, Config.maxPinnedPanelHeight);

    if (newHeight == settingsProvider.state.pinnedPanelHeight) //
      return;

    settingsProvider.setPinnedPanelHeight(newHeight);
  }

  void _addNewClass(ClassMetaType type) {
    final id = DbModelUtils.getRandomId();
    final added = providerContainer
        .read(clientOwnCommandsStateProvider) //
        .addCommand(
          DbCmdAddNewClass.fromType(
            entityId: id,
            type: type,
            index: 0,
            parentId: null,
          ),
        );

    if (added) //
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity(id: id);
  }

  void _addNewTable(TableMetaType type) {
    final id = DbModelUtils.getRandomId();
    final added = providerContainer
        .read(clientOwnCommandsStateProvider) //
        .addCommand(
          DbCmdAddNewTable.fromType(
            entityId: id,
            type: type,
            index: 0,
            parentId: null,
          ),
        );

    if (added) //
      providerContainer.read(tableSelectionStateProvider).setSelectedEntity(id: id);
  }

  void _handleProblemsClick() {
    providerContainer.read(clientProblemsStateProvider).focusOnNextProblem(null);
  }

  void _handleToggleTablesPanel() {
    providerContainer.read(settingsStateProvider).toggleTablesExpanded();
  }

  void _handleToggleClassesPanel() {
    providerContainer.read(settingsStateProvider).toggleClassesExpanded();
  }

  void _handleToggleProblemsPanel() {
    providerContainer.read(settingsStateProvider).toggleProblemsExpanded();
  }

  void _handleToggleGitPanel() {
    providerContainer.read(settingsStateProvider).toggleGitExpanded();
  }

  void _handleToggleHistoryPanel() {
    providerContainer.read(settingsStateProvider).toggleHistoryExpanded();
  }

  void _handleSettingsClick() {
    GlobalShortcuts.openProjectSettings();
  }
}
