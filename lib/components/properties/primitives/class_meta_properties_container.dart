import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';

class ClassMetaPropertiesContainer extends StatelessWidget {
  final List<Widget> children;

  const ClassMetaPropertiesContainer({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return ScrollConfiguration(
      behavior: kScrollDraggable,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.symmetric(horizontal: 6 * kScale, vertical: 10 * kScale),
        child: ScrollConfiguration(
          behavior: kScrollNoScroll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
