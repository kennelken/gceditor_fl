import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/problems/table_problems_item_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableProblemsView extends ConsumerWidget {
  const TableProblemsView({super.key});

  @override
  Widget build(context, ref) {
    final problems = ref.watch(clientProblemsStateProvider).state.problems;
    ref.watch(styleStateProvider);

    return ScrollConfiguration(
      behavior: kScrollDraggable,
      child: ListView.builder(
        itemCount: problems.length,
        controller: ScrollController(),
        itemBuilder: (context, index) {
          return TableProblemsItemView(
            index: index,
            problem: problems[index],
          );
        },
      ),
    );
  }
}
