import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/style_state.dart';

class ContextMenuButton extends StatelessWidget {
  final List<ContextMenuChildButtonData> buttons;
  final CustomPopupMenuController controller;
  final Icon? icon;

  const ContextMenuButton({
    Key? key,
    required this.controller,
    required this.buttons,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26 * kScale,
      child: CustomPopupMenu(
        arrowColor: kTextColorLight,
        controller: controller,
        pressType: PressType.singleClick,
        menuBuilder: () {
          return Container(
            width: 100 * kScale,
            color: kColorPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buttons
                  .map(
                    (b) => ContextMenuItem(
                      text: b.title,
                      onClick: () {
                        controller.hideMenu();
                        b.onClick();
                      },
                    ),
                  )
                  .toList(),
            ),
          );
        },
        child: icon ?? const IconPlus(),
      ),
    );
  }
}

class IconPlus extends StatelessWidget {
  const IconPlus({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      FontAwesomeIcons.plus,
      color: kColorAccentBlue,
      size: 18 * kScale,
    );
  }
}

class ContextMenuItem extends StatelessWidget {
  final String text;
  final VoidCallback onClick;

  const ContextMenuItem({
    Key? key,
    required this.text,
    required this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: kButtonContextMenu,
      onPressed: onClick,
      child: Text(
        text,
        style: kStyle.kTextSmall,
      ),
    );
  }
}

class ContextMenuChildButtonData {
  String title;
  VoidCallback onClick;

  ContextMenuChildButtonData(this.title, this.onClick);
}
