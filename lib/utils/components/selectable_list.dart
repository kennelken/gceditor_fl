import 'package:flutter/material.dart';

import '../selection_list_controller.dart';

// ignore: must_be_immutable
class SelectableList extends StatefulWidget {
  late SelectionListController _controller;

  final Widget Function(
    BuildContext context,
    IsItemSelected isSelected,
    ItemSelectedCallback onClick,
  ) builder;

  SelectableList({
    Key? key,
    required this.builder,
    SelectionListController? controller,
  }) : super(key: key) {
    _controller = controller ?? SelectionListController();
  }

  @override
  SelectableListState createState() => SelectableListState();
}

class SelectableListState extends State<SelectableList> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      (i) => widget._controller.selectedItems.contains(i),
      _handleItemClick,
    );
  }

  void _handleItemClick(int index, bool ctrlKey, bool shiftKey) {
    setState(() => widget._controller.selectItem(index, ctrlKey, shiftKey));
  }
}
