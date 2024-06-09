import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db_network/history_item_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_history_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableHistoryItemView extends ConsumerWidget {
  final HistoryItemData data;

  const TableHistoryItemView({
    super.key,
    required this.data,
  });

  @override
  Widget build(context, ref) {
    final historyState = providerContainer.read(clientHistoryStateProvider).state;

    return SizedBox(
      height: 26 * kScale,
      child: FittedBox(
        fit: BoxFit.none,
        alignment: Alignment.centerLeft,
        child: Material(
          color: kColorPrimaryLighter,
          child: InkWell(
            onTap: () => _handleClick(),
            child: Padding(
              padding: EdgeInsets.only(left: 10 * kScale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '#${data.id}',
                    style: kStyle.kTextExtraSmall,
                  ),
                  if (historyState.currentTag == data.id) ...[
                    SizedBox(width: 12 * kScale),
                    Text(
                      Loc.get.historyItemCurrent,
                      style: kStyle.kTextExtraSmallInactive.copyWith(color: kColorPrimaryLightTransparent1_5),
                    ),
                  ],
                  const SizedBox(width: 9999),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _handleClick() {
    providerContainer.read(clientHistoryStateProvider).toggleSelection(data);
  }
}
