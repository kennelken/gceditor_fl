import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class FindPanelItem extends StatelessWidget {
  final FindResultItem item;
  final int index;

  const FindPanelItem({
    required this.item,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0 * kScale),
      child: Material(
        color: kColorPrimary,
        child: InkWell(
          onTap: _handleClick,
          child: SizedBox(
            height: kStyle.kTableTopRowHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 7 * kScale),
              child: Row(
                children: [
                  Text('$index.', style: kStyle.kTextExtraSmallInactive),
                  SizedBox(width: 3 * kScale),
                  _getCoordinatesText(),
                  SizedBox(width: 5 * kScale),
                  Text(
                    item.getDescription(),
                    style: kStyle.kTextExtraSmall.copyWith(color: item.color()),
                  ),
                  Text(
                    ': "${item.value}"',
                    style: kStyle.kTextExtraSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCoordinatesText() {
    switch (item.type) {
      case FindResultType.declaration:
        return Text(
          '${item.tableItem!.tableId}[${item.tableItem!.rowIndex}]',
          style: kStyle.kTextExtraSmall,
        );

      case FindResultType.value:
      case FindResultType.reference:
        return Text(
          '${item.tableItem!.tableId}[${item.tableItem!.rowIndex}:${item.tableItem!.fieldIndex}]',
          style: kStyle.kTextExtraSmall,
        );

      case FindResultType.tableDeclaration:
        return Text(
          '${item.metaItem!.tableId}',
          style: kStyle.kTextExtraSmall,
        );

      case FindResultType.classDeclaration:
      case FindResultType.enumDeclaration:
      case FindResultType.fieldDeclaration:
      case FindResultType.columnUsedAsReferenceType:
        return Text(
          '${item.metaItem!.classId}${item.metaItem!.fieldId == null ? '' : '/${item.metaItem!.fieldId}'}',
          style: kStyle.kTextExtraSmall,
        );

      case FindResultType.classParentClass:
        return Text(
          '${item.metaItem!.classId}',
          style: kStyle.kTextExtraSmall,
        );

      case FindResultType.classParentInterface:
        return Text(
          '${item.metaItem!.classId}',
          style: kStyle.kTextExtraSmall,
        );

      case FindResultType.tableParentClass:
        return Text(
          '${item.metaItem!.tableId}',
          style: kStyle.kTextExtraSmall,
        );
    }
  }

  void _handleClick() {
    providerContainer.read(clientFindStateProvider).focusOn(item);
  }
}
