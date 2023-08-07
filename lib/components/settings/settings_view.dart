import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/settings/generators_view.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_project_settings.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    final model = ref.watch(clientStateProvider).state.model;

    final tz = model.settings.timeZone;
    final timezoneController = TextEditingController(text: Utils.floatWithSign(tz));
    final timezoneFocusNode = FocusNode();
    timezoneFocusNode.addListener(() => _handleTimezoneFocus(timezoneFocusNode, timezoneController));

    final saveDelayController = TextEditingController(text: model.settings.saveDelay.toString());
    final saveDelayFocusNode = FocusNode();
    saveDelayFocusNode.addListener(() => _handleSaveDelayFocus(saveDelayFocusNode, saveDelayController));

    ref.watch(styleStateProvider);

    return Container(
      width: 1100 * kScale,
      height: 352 * kScale,
      color: kTextColorLightest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            alignment: Alignment.center,
            height: 50 * kScale,
            color: kColorAccentBlue2,
            child: Text(
              Loc.get.projectSettingsTitle,
              style: kStyle.kTextBig,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20 * kScale),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          Loc.get.projectSettingsSaveDelay,
                          style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: saveDelayController,
                          decoration: kStyle.kInputTextStyleSettingsProperties,
                          inputFormatters: Config.filterCellTypeFloat,
                          focusNode: saveDelayFocusNode,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          Loc.get.projectSettingsTimezoneTitle,
                          style: kStyle.kTextRegular.copyWith(color: kTextColorDark),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: timezoneController,
                          decoration: kStyle.kInputTextStyleSettingsProperties,
                          inputFormatters: Config.filterTimeZone,
                          focusNode: timezoneFocusNode,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * kScale),
                  GeneratorsView(
                    key: ValueKey(ref.watch(clientStateProvider).state.version),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTimezoneFocus(FocusNode focus, TextEditingController textComponent) {
    if (focus.hasFocus) //
      return;

    final match = Config.validTimezoneFormat.firstMatch(textComponent.text);
    if (match == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Invalid timezone. Valid format example "+1.5"'));
      providerContainer.read(clientStateProvider).dispatchChange();
      return;
    }

    final value = textComponent.text.replaceAll('+', '');
    final newTimezone = double.parse(value);

    if (newTimezone == clientModel.settings.timeZone) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            timezone: newTimezone,
          ),
        );
  }

  void _handleSaveDelayFocus(FocusNode focus, TextEditingController textComponent) {
    if (focus.hasFocus) //
      return;

    final value = textComponent.text;
    final match = Config.validCharactersForCellTypeFloat.firstMatch(value);
    if (match == null || double.tryParse(value) == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Invalid float value. Valid format example "2.0"'));
      providerContainer.read(clientStateProvider).dispatchChange();
      return;
    }

    final newSaveDelay = double.parse(value);

    if (newSaveDelay == clientModel.settings.saveDelay) //
      return;

    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            saveDelay: newSaveDelay,
          ),
        );
  }
}
