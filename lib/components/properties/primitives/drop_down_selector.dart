import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/clickable_reference_text.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/client_view_mode_state.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';

import '../../../consts/consts.dart';

class DropDownSelector<T extends IIdentifiable?> extends ConsumerWidget {
  final String label;
  late final List<T?> items;
  final T? selectedItem;
  final bool Function(T) isEnabled;
  final bool addNull;
  final ValueChanged<T?> onValueChanged;
  final InputDecoration? inputDecoration;
  final String? nullValueLabel;
  final bool showTooltip;
  final ClassMeta? classEntity;
  final void Function(T? item)? onJumpToDefinition;

  DropDownSelector({
    super.key,
    required List<T> items,
    required this.label,
    required this.selectedItem,
    required this.isEnabled,
    required this.onValueChanged,
    this.addNull = true,
    this.inputDecoration,
    this.nullValueLabel,
    this.showTooltip = true,
    this.classEntity,
    this.onJumpToDefinition,
  }) {
    this.items = addNull ? [null, ...items] : items;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = clientModel;
    final navService = ref.read(clientNavigationServiceProvider);

    bool canJump(T? item) {
      if (item == null) return false;
      return navService.canJumpToDefinition(model, item, classEntity: classEntity);
    }

    void doJump(T? item) {
      if (item == null) return;
      if (onJumpToDefinition != null) {
        onJumpToDefinition!(item);
      } else {
        navService.jumpToDefinition(model, item, classEntity: classEntity);
      }
    }

    return SizedBox(
      height: kStyle.kTableTopRowHeight,
      child: DropdownSearch<T?>(
        items: (filter, loadProps) => items,
        onBeforePopupOpening: (selectedItem) async {
          final isControlPressed = ref.read(clientViewModeStateProvider).state.controlKey || HardwareKeyboard.instance.isControlPressed;
          if (isControlPressed && selectedItem != null && canJump(selectedItem)) {
            doJump(selectedItem);
            return false;
          }
          return true;
        },
        dropdownBuilder: (context, selectedItem) {
          if (selectedItem == null) return const SizedBox();
          final itemName = _getItemName(selectedItem);
          final jumpable = canJump(selectedItem);

          return TooltipWrapper(
            message: showTooltip && (selectedItem is IDescribable) ? (selectedItem as IDescribable).description : null,
            child: ClickableReferenceText(
              text: itemName,
              style: kStyle.kTextExtraSmall,
              canJump: jumpable,
              onJumpToDefinition: jumpable ? () => doJump(selectedItem) : null,
            ),
          );
        },
        popupProps: PopupProps.menu(
          fit: FlexFit.loose,
          containerBuilder: (context, popupWidget) => Padding(
            padding: EdgeInsets.only(bottom: 5 * kScale),
            child: popupWidget,
          ),
          constraints: BoxConstraints.loose(const Size.fromHeight(1000)),
          disabledItemFn: (i) => !_isEnabled(i),
          menuProps: const MenuProps(
            elevation: 30,
            barrierColor: kColorPrimaryLightTransparent3,
            backgroundColor: kColorAccentBlue2,
            shadowColor: Colors.black,
          ),
          itemBuilder: (context, item, isDisabled, isSelected) {
            final enabled = _isEnabled(item);
            final itemName = item?.id ?? Loc.get.nullValue;
            final jumpable = canJump(item);
            final textStyle = isSelected ? kStyle.kTextExtraSmallSelected : (enabled ? kStyle.kTextExtraSmall : kStyle.kTextExtraSmallInactive);

            return TooltipWrapper(
              message: (item is IDescribable) ? (item as IDescribable).description : null,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  if (event.buttons == kPrimaryButton) {
                    final isControlPressed = ref.read(clientViewModeStateProvider).state.controlKey || HardwareKeyboard.instance.isControlPressed;
                    if (isControlPressed && item != null && jumpable) {
                      Navigator.of(context, rootNavigator: true).pop();
                      doJump(item);
                    }
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5 * kScale, vertical: 2 * kScale),
                  child: ClickableReferenceText(
                    text: itemName,
                    style: textStyle,
                    canJump: jumpable,
                    onJumpToDefinition: jumpable
                        ? () {
                            Navigator.of(context, rootNavigator: true).pop();
                            doJump(item);
                          }
                        : null,
                  ),
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
          emptyBuilder: (context, searchEntry) => SizedBox(
            width: 9999,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10 * kScale),
              child: Text(
                Loc.get.emptyDropDownList,
                style: kStyle.kTextExtraSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        suffixProps: DropdownSuffixProps(
          dropdownButtonProps: DropdownButtonProps(
            color: kColorPrimaryLight,
            padding: EdgeInsets.zero,
            iconSize: 15 * kScale,
            constraints: BoxConstraints.tightFor(width: 35 * kScale, height: 25),
            splashRadius: 20 * kScale,
            iconClosed: const FaIcon(FontAwesomeIcons.caretDown),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: (inputDecoration ?? kStyle.kInputTextStyleProperties).copyWith(
            labelText: selectedItem == null ? null : label,
            hintText: selectedItem == null ? (nullValueLabel ?? label) : '',
          ),
        ),
        compareFn: (a, b) => a == b,
        onSelected: onValueChanged,
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
