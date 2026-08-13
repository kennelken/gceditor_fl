import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db/table_meta_entity.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_opened_tabs_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/model/state/table_selection_state.dart';

class OpenedTableTabsView extends ConsumerWidget {
  const OpenedTableTabsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openedTabsState = ref.watch(clientOpenedTabsStateProvider).state;
    final selectedTable = ref.watch(tableSelectionStateProvider).state.selectedTable;
    ref.watch(styleStateProvider);

    if (openedTabsState.openedTableIds.isEmpty) {
      return const SizedBox();
    }

    final activeTableId = selectedTable?.id ?? openedTabsState.activeTableId;

    return Container(
      height: kStyle.kTableTopRowHeight,
      color: kColorPrimaryDarkest,
      child: ScrollConfiguration(
        behavior: kScrollDraggableNoScrollBar,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: openedTabsState.openedTableIds.length,
          itemBuilder: (context, index) {
            final tableId = openedTabsState.openedTableIds[index];
            final isActive = tableId == activeTableId;
            final model = ref.watch(clientStateProvider).state.model;
            final table = model.cache.getTable<TableMetaEntity>(tableId);
            final title = table?.id ?? tableId;
            final description = table?.description;

            return Listener(
              onPointerDown: (event) {
                if (event.buttons == kMiddleMouseButton) {
                  ref.read(clientOpenedTabsStateProvider.notifier).closeTable(tableId);
                }
              },
              child: TooltipWrapper(
                message: description != null && description.isNotEmpty ? '$title\n$description' : title,
                child: Material(
                  color: isActive ? kColorPrimaryDarker : kColorPrimaryDarker2,
                  child: InkWell(
                    splashColor: kColorPrimaryLighter,
                    hoverColor: isActive ? kColorPrimaryDarker : kColorPrimaryLighter,
                    onTap: () {
                      if (table != null) {
                        providerContainer.read(tableSelectionStateProvider).setSelectedTable(table: table);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10 * kScale),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isActive ? kColorAccentBlue : kColorTransparent,
                            width: 2 * kScale,
                          ),
                          right: BorderSide(
                            color: kColorPrimary,
                            width: 1 * kScale,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: isActive ? kStyle.kTextExtraSmallSelected : kStyle.kTextExtraSmall,
                            maxLines: 1,
                          ),
                          SizedBox(width: 6 * kScale),
                          InkWell(
                            borderRadius: BorderRadius.circular(10 * kScale),
                            onTap: () {
                              ref.read(clientOpenedTabsStateProvider.notifier).closeTable(tableId);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(2 * kScale),
                              child: FaIcon(
                                FontAwesomeIcons.xmark,
                                size: 10 * kScale,
                                color: isActive ? kColorPrimaryLight : kColorPrimaryLightTransparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
