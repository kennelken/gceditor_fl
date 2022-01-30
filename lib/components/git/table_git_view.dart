import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/git/table_git_item_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/client_git_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableGitView extends ConsumerWidget {
  const TableGitView({Key? key}) : super(key: key);

  @override
  Widget build(context, watch) {
    final items = watch(clientGitStateProvider).state.items;
    watch(styleStateProvider);

    return ScrollConfiguration(
      behavior: kScrollDraggable,
      child: ListView.builder(
        controller: ScrollController(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return TableGitItemView(
            data: items[index],
          );
        },
      ),
    );
  }
}
