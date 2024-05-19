import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/history/table_history_item_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/client_history_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableHistoryView extends ConsumerWidget {
  const TableHistoryView({super.key});

  @override
  Widget build(context, ref) {
    final items = ref.watch(clientHistoryStateProvider).state.items;
    ref.watch(styleStateProvider);

    return ScrollConfiguration(
      behavior: kScrollDraggable,
      child: ListView.builder(
        controller: ScrollController(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return TableHistoryItemView(
            data: items[index],
          );
        },
      ),
    );
  }
}
