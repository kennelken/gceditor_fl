import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/style_state.dart';

class DropDownSelector<T extends IIdentifiable?> extends StatelessWidget {
  final String label;
  late final List<T?> items;
  final T? selectedItem;
  final bool Function(T) isEnabled;
  final bool addNull;
  final ValueChanged<T?> onValueChanged;
  final InputDecoration? inputDecoration;
  final String? nullValueLabel;

  DropDownSelector({
    Key? key,
    required List<T> items,
    required this.label,
    required this.selectedItem,
    required this.isEnabled,
    required this.onValueChanged,
    this.addNull = true,
    this.inputDecoration,
    this.nullValueLabel,
  }) : super(key: key) {
    this.items = addNull ? [null, ...items] : items;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kStyle.kTableTopRowHeight,
      child: DropdownSearch<T?>(
        dropdownButtonBuilder: (context) => SizedBox(
          width: 20 * kStyle.globalScale,
          child: Icon(
            FontAwesomeIcons.caretDown,
            color: kTextColorLight,
            size: 15 * kStyle.globalScale,
          ),
        ),
        dropdownBuilder: (context, selectedItem) {
          return TooltipWrapper(
            message: (selectedItem is IDescribable) ? (selectedItem as IDescribable).description : null,
            child: Text(
              _getItemName(selectedItem),
              style: kStyle.kTextExtraSmall,
              maxLines: 1,
            ),
          );
        },
        scrollbarProps: ScrollbarProps(isAlwaysShown: false),
        maxHeight: kStyle.dropDownSelectorHeight,
        dropdownSearchDecoration: (inputDecoration ?? kStyle.kInputTextStyleProperties)
            .copyWith(labelText: (selectedItem == null ? nullValueLabel : null) ?? label, hintText: ''), // actual view style
        dropdownSearchBaseStyle: kStyle.kTextExtraSmallLightest,
        searchFieldProps: TextFieldProps(
          decoration: kStyle.kInputTextStylePropertiesDropDownSearch.copyWith(hintText: Loc.get.dropDownSearchHint),
          autofocus: true,
        ),
        searchDelay: Duration.zero,
        showSelectedItems: true,
        showAsSuffixIcons: true,
        popupElevation: 0,
        mode: Mode.MENU,
        showSearchBox: true,
        items: items,
        emptyBuilder: (context, searchEntry) => Center(
          child: Text(
            Loc.get.emptyDropDownList,
            style: kStyle.kTextExtraSmall,
          ),
        ),
        compareFn: (a, b) => a == b,
        popupBarrierColor: kColorPrimaryLightTransparent2,
        popupBackgroundColor: kColorAccentBlue2,
        popupItemDisabled: (e) => !_isEnabled(e),
        popupItemBuilder: (context, item, isSelected) {
          final enabled = _isEnabled(item);
          return TooltipWrapper(
            message: (item is IDescribable) ? (item as IDescribable).description : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5 * kScale, vertical: 2 * kScale),
              child: Text(
                item?.id ?? Loc.get.nullValue,
                maxLines: 1,
                style: isSelected ? kStyle.kTextExtraSmallSelected : (enabled ? kStyle.kTextExtraSmall : kStyle.kTextExtraSmallInactive),
              ),
            ),
          );
        },
        clearButton: Icon(
          FontAwesomeIcons.times,
          color: kColorPrimaryLight,
          size: 15 * kScale,
        ),
        dropDownButton: Icon(
          FontAwesomeIcons.caretDown,
          color: kColorPrimaryLight,
          size: 15 * kScale,
        ),
        onChanged: onValueChanged,
        selectedItem: selectedItem,
        itemAsString: _getItemName,
      ),
    );
  }

  bool _isEnabled(T? item) {
    return item == null || isEnabled(item);
  }

  String _getItemName(T? item) {
    return item?.id ?? Loc.get.nullValue;
  }
}
