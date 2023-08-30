import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/style_state.dart';

import '../../../consts/consts.dart';

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
        items: items,
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
        popupProps: PopupProps.menu(
          fit: FlexFit.loose,
          constraints: BoxConstraints.loose(const Size.fromHeight(1000)),
          disabledItemFn: (i) => !_isEnabled(i),
          menuProps: const MenuProps(
            elevation: 0,
            barrierColor: kColorPrimaryLightTransparent2,
            backgroundColor: kColorAccentBlue2,
          ),
          itemBuilder: (context, item, isSelected) {
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
          searchDelay: Duration.zero,
          showSelectedItems: true,
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            style: kStyle.kTextExtraSmallLightest,
            decoration: kStyle.kInputTextStylePropertiesDropDownSearch.copyWith(hintText: Loc.get.dropDownSearchHint),
            autofocus: true,
          ),
          emptyBuilder: (context, searchEntry) => Center(
            child: Text(
              Loc.get.emptyDropDownList,
              style: kStyle.kTextExtraSmall,
            ),
          ),
        ),
        dropdownButtonProps: DropdownButtonProps(
          color: kColorPrimaryLight,
          padding: EdgeInsets.zero,
          iconSize: 15 * kScale,
          constraints: BoxConstraints.tightFor(width: 35 * kScale, height: 25),
          splashRadius: 20 * kScale,
          icon: const Icon(FontAwesomeIcons.caretDown),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: (inputDecoration ?? kStyle.kInputTextStyleProperties)
              .copyWith(labelText: (selectedItem == null ? nullValueLabel : null) ?? label, hintText: ''),
        ),
/*      maxHeight: kStyle.dropDownSelectorHeight, */
/*      showAsSuffixIcons: true,*/
        compareFn: (a, b) => a == b,
/*      clearButton: Icon(
          FontAwesomeIcons.times,
          color: kColorPrimaryLight,
          size: 15 * kScale,
        ),
        */
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
