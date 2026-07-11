import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db_network/get_item_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_git_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableGitItemView extends ConsumerWidget {
  final GitItemData data;

  const TableGitItemView({
    super.key,
    required this.data,
  });

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
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: data.name),
                        if (data.isModified)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Transform.translate(
                              offset: Offset(1 * kScale, -4 * kScale),
                              child: FaIcon(
                                FontAwesomeIcons.asterisk,
                                size: 8 * kScale,
                                color: kColorAccentBlue,
                              ),
                            ),
                          ),
                        if (data.isUnpushed)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 2 * kScale),
                              child: FaIcon(
                                FontAwesomeIcons.arrowUp,
                                size: 9 * kScale,
                                color: kColorAccentBlue,
                              ),
                            ),
                          ),
                        if (data.isUnpulled)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 2 * kScale),
                              child: FaIcon(
                                FontAwesomeIcons.arrowDown,
                                size: 9 * kScale,
                                color: kColorAccentBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
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
