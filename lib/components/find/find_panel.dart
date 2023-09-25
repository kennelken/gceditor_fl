import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/find/find_panel_item.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class FindPanel extends StatefulWidget {
  const FindPanel({
    Key? key,
  }) : super(key: key);

  @override
  State<FindPanel> createState() => _FindPanelState();
}

class _FindPanelState extends State<FindPanel> {
  late TextEditingController _findTextController;
  late FocusNode _findFocusNode;

  @override
  void initState() {
    super.initState();
    _findFocusNode = FocusNode();

    _findTextController = TextEditingController(text: providerContainer.read(clientFindStateProvider).state.settings.text);
    _preselectFindText();

    providerContainer.read(selectFindFieldProvider).addListener(_preselectFindText);
  }

  @override
  void dispose() {
    super.dispose();
    _findTextController.dispose();
    providerContainer.read(selectFindFieldProvider).removeListener(_preselectFindText);
  }

  void _preselectFindText() {
    _findTextController.selection = TextSelection(baseOffset: 0, extentOffset: _findTextController.text.length);
    _findFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final settings = ref.watch(clientFindStateProvider).state.settings;
      final results = ref.watch(clientFindStateProvider).state.getResults();
      ref.watch(styleStateProvider);
      _findTextController.text = settings.text ?? '';
      _preselectFindText();

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 7 * kScale, top: 7 * kScale, right: 3 * kScale),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        onChanged: (_) => _handleTextChanged(),
                        onSubmitted: (_) => _handleFindClick(),
                        controller: _findTextController,
                        focusNode: _findFocusNode,
                        decoration: kStyle.kInputTextStyleFind.copyWith(
                          labelText: Loc.get.labelFind,
                          hintText: Loc.get.hintFind,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 10 * kScale),
                        child: Text(
                          results == null ? '' : Loc.get.findResultsCount(results.length),
                          textAlign: TextAlign.end,
                          style: kStyle.kTextExtraSmallInactive,
                        ),
                      ),
                    ],
                  ),
                ),
                TooltipWrapper(
                  message: Loc.get.findTooltip,
                  child: IconButtonTransparent(
                    size: 35 * kScale,
                    icon: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: kColorAccentBlue,
                      size: 20 * kScale,
                    ),
                    onClick: _handleFindClick,
                  ),
                ),
                SizedBox(width: 3 * kScale),
                TooltipWrapper(
                  message: Loc.get.findIdTooltip,
                  child: IconButtonTransparent(
                    size: 37 * kScale,
                    onClick: _handleOnlyIdClick,
                    icon: FittedBox(
                      child: Text(
                        'id',
                        style: kStyle.kTextExtraSmall.copyWith(color: settings.onlyId == true ? kTextColorLightBlue : kTextColorLightHalfTransparent),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
                TooltipWrapper(
                  message: Loc.get.findCaseSensitiveTooltip,
                  child: IconButtonTransparent(
                    size: 37 * kScale,
                    onClick: _handleCaseSensitiveClick,
                    icon: FittedBox(
                      child: Text(
                        'Aa',
                        style: kStyle.kTextExtraSmall
                            .copyWith(color: settings.caseSensitive == true ? kTextColorLightBlue : kTextColorLightHalfTransparent),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
                TooltipWrapper(
                  message: Loc.get.findFullWordsTooltip,
                  child: IconButtonTransparent(
                    size: 37 * kScale,
                    onClick: _handleWordClick,
                    icon: FittedBox(
                      child: Text(
                        'W',
                        style: kStyle.kTextExtraSmall.copyWith(color: settings.word == true ? kTextColorLightBlue : kTextColorLightHalfTransparent),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
                TooltipWrapper(
                  message: Loc.get.findRegexTooltip,
                  child: IconButtonTransparent(
                    size: 37 * kScale,
                    onClick: _handleRegexClick,
                    icon: FittedBox(
                      child: Text(
                        '.*',
                        style: kStyle.kTextExtraSmall.copyWith(color: settings.regEx == true ? kTextColorLightBlue : kTextColorLightHalfTransparent),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20 * kScale),
                TooltipWrapper(
                  message: Loc.get.findCloseTooltip,
                  child: IconButtonTransparent(
                    size: 35 * kScale,
                    icon: Icon(
                      FontAwesomeIcons.xmark,
                      color: kColorPrimaryLight,
                      size: 20 * kScale,
                    ),
                    onClick: () => providerContainer.read(clientFindStateProvider).toggleVisibility(false),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0 * kScale),
              child: ScrollConfiguration(
                behavior: kScrollDraggable,
                child: ListView.builder(
                  controller: ScrollController(),
                  itemCount: results?.length ?? 0,
                  itemBuilder: (context, index) {
                    return FindPanelItem(
                      index: index,
                      item: results![index],
                      key: ValueKey(results[index].hashCode),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _handleTextChanged() {
    providerContainer.read(clientFindStateProvider).setSettings(
          FindSettings(text: _findTextController.text),
          silent: true,
        );
  }

  void _handleFindClick() {
    providerContainer.read(clientFindStateProvider).find(clientModel);
    _findFocusNode.requestFocus();
  }

  void _handleOnlyIdClick() {
    providerContainer.read(clientFindStateProvider).setSettings(
          FindSettings(onlyId: !(providerContainer.read(clientFindStateProvider).state.settings.onlyId == true)),
        );
  }

  void _handleCaseSensitiveClick() {
    providerContainer.read(clientFindStateProvider).setSettings(
          FindSettings(caseSensitive: !(providerContainer.read(clientFindStateProvider).state.settings.caseSensitive == true)),
        );
  }

  void _handleRegexClick() {
    providerContainer.read(clientFindStateProvider).setSettings(
          FindSettings(regEx: !(providerContainer.read(clientFindStateProvider).state.settings.regEx == true)),
        );
  }

  void _handleWordClick() {
    providerContainer.read(clientFindStateProvider).setSettings(
          FindSettings(word: !(providerContainer.read(clientFindStateProvider).state.settings.word == true)),
        );
  }
}
