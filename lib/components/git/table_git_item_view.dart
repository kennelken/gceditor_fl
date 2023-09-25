import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db_network/get_item_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_git_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableGitItemView extends ConsumerWidget {
  final GitItemData data;

  const TableGitItemView({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(context, ref) {
    final gitState = providerContainer.read(clientGitStateProvider).state;

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
              padding: EdgeInsets.only(left: 5 * kScale),
              child: Row(
                children: [
                  kStyle.wrapCheckbox(
                    Checkbox(
                      value: gitState.selectedItems.contains(data.id),
                      onChanged: (_) => _handleClick(),
                    ),
                  ),
                  SizedBox(width: 5 * kScale),
                  Text(
                    data.name,
                    style: kStyle.kTextExtraSmall.copyWith(color: data.color),
                  ),
                  SizedBox(width: 12 * kScale),
                  Text(
                    data.branchName,
                    style: kStyle.kTextExtraSmallInactive.copyWith(color: kColorPrimaryLightTransparent1_5),
                  ),
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
    providerContainer.read(clientGitStateProvider).toggleSelection(data);
  }
}
