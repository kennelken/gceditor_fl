import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db_network/history_item_data_entry.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_history_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class HistoryDialogItem extends StatelessWidget {
  final HistoryItemDataEntry data;
  final bool selected;
  final bool? executionResult;
  final void Function() onClick;

  const HistoryDialogItem({
    super.key,
    required this.data,
    required this.selected,
    required this.executionResult,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? kTextColorLightBlue
          : (executionResult == true ? kColorAccentGreenTransparent : (executionResult == false ? kColorAccentRedTransparent : kColorTransparent)),
      child: InkWell(
        onTap: onClick,
        child: SizedBox(
          height: 30 * kScale,
          child: Row(
            children: [
              SizedBox(width: 8 * kScale),
              Text(
                kDateTimeFormat.format(data.time),
                style: kStyle.kTextExtraSmallDark.copyWith(color: kColorAccentOrange),
              ),
              SizedBox(width: 20 * kScale),
              Text(
                data.user,
                style: kStyle.kTextExtraSmallDark.copyWith(color: kColorAccentBlue1_5),
              ),
              SizedBox(width: 20 * kScale),
              Expanded(
                child: Text(
                  providerContainer.read(clientHistoryStateProvider).state.getEntryString(data),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  style: kStyle.kTextExtraSmallDark,
                ),
              ),
              SizedBox(width: 20 * kScale),
              IconButtonTransparent(
                size: 35 * kScale,
                onClick: _handleCopyClicked,
                icon: Icon(
                  FontAwesomeIcons.copy,
                  size: 19 * kScale,
                  color: kColorPrimaryLight,
                ),
              ),
              SizedBox(width: 15 * kScale),
              if (executionResult == true) //
                ...[
                Icon(FontAwesomeIcons.circleCheck, size: 20 * kScale, color: kColorAccentTeal),
                SizedBox(width: 15 * kScale),
              ],
              if (executionResult == false) //
                ...[
                Icon(FontAwesomeIcons.circleXmark, size: 20 * kScale, color: kColorAccentRed),
                SizedBox(width: 15 * kScale),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleCopyClicked() {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Copied to the clipboard command "${data.command.id}"'));
    Clipboard.setData(ClipboardData(text: jsonEncode(data.command.toJson())));
  }
}
