import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:intl/intl.dart';

// Modify double tap settings in flutter directly because there is still no better way of doing that
// import 'package:flutter/gestures.dart' show kDoubleTapTimeout
// preferred values:
// const Duration kLongPressTimeout = Duration(milliseconds: 350);
// const Duration kDoubleTapTimeout = Duration(milliseconds: 150);
// const Duration kDoubleTapMinTime = Duration(milliseconds: 20);

double get kScale => kStyle.globalScale;
// find numbers without scale \b[0-9]+[\.0-9]*\b(?! \* kScale)

final MaterialColor kColorPrimary = Utils.createMaterialColor(const Color(0xff282c34));
const Color kColorPrimaryDarkest = Color(0xFF121418);
const Color kColorPrimaryDarker2 = Color(0xFF1D2025);
const Color kColorPrimaryDarker = Color(0xff21252b);
const Color kColorPrimaryLighter = Color(0xFF2E323B);
const Color kColorPrimaryLighter2 = Color(0xFF3E4452);
const Color kColorPrimaryLight = Color(0xFF979DAD);
const Color kColorPrimaryLightTransparent = Color(0x66979DAD);
const Color kColorPrimaryLightTransparent1_5 = Color(0x46979DAD);
const Color kColorPrimaryLightTransparent2 = Color(0x28979DAD);
const Color kColorSecondary = Color(0xffe2c08d);
const Color kColorBackground = Color(0xff282c34);
const Color kColorButtonActive = Color(0xFFBFC7D6);
const Color kColorTransparent = Color(0x00000000);
const Color kColorDarken = Color(0x44000000);
const Color kColorDataTableLine = Color(0xFF3E4452);
const Color kColorDataTableBackground = Color(0x005E7F97);

const Color kColorTextButton = kTextColorDark;

const Color kColorBlueMetaPropertiesGroup = Color(0xFF294863);
const Color kColorBlue = Color(0xFF537086);
const Color kColorBlueDarker = Color(0xFF455D70);
const Color kColorBlue2 = Color(0xFF475F72);
const Color kColorBlueDarker2 = Color(0xFF344858);

const Color kTextColorLightHalfTransparent = Color(0x77C9C9C9);
const Color kTextColorLightHalfTransparent2 = Color(0x22C9C9C9);
const Color kTextColorLight3 = Color(0xFF868686);
const Color kTextColorLight2 = Color(0xFFAFAFAF);
const Color kTextColorLight = Color(0xFFD6D6D6);
const Color kTextColorLightBlue = Color(0xFF96BBF1);
const Color kTextColorLightest = Color(0xFFECECEC);
const Color kTextColorDark = Color(0xFF16181B);

const Color kColorAccentBlue = Color(0xFF5F9FD4);
const Color kColorAccentBlueInactive = Color(0x665F9FD4);
const Color kColorAccentBlue1_5 = Color(0xFF4E85B3);
const Color kColorAccentBlue2 = Color(0xFF345F83);
const Color kColorAccentBlue2_5 = Color(0xFF23445F);
const Color kColorAccentBlue3 = Color(0xFF20384D);
const Color kColorAccentGreen = Color(0xFF52DB80);
const Color kColorAccentGreenTransparent = Color(0x5252DB80);
const Color kColorAccentTeal = Color(0xFF00796b);
const Color kColorAccentTealDark = Color(0xFF044941);
const Color kColorAccentRed = Color(0xFFC24848);
const Color kColorAccentRedTransparent = Color(0x4DC24848);
const Color kColorAccentRed2 = Color(0xFFAD4141);
const Color kColorAccentOrange = Color(0xffcc6633);
const Color kColorAccentOrangeHover = Color(0xFFBE531D);
const Color kColorAccentOrangeSplash = Color(0xFFCA8A6A);
const Color kColorAccentYellow = Color(0xFFCCA833);
const Color kColorAccentPink = Color(0xFFC55FAC);

const Color kColorSelectedDataTable = Color(0x0CFFFFFF);
const Color kColorSelectedDataTableId = Color(0x38FFFFFF);

const int kFindResultBackgroundAlpha = 160;
const int kFindResultBackgroundAlphaSelected = 255;

const int kIconInactiveAlpha = 140;
const int kIconActiveAlpha = 255;

const double kDividerLineWidth = 4;

final ButtonStyle kButtonWhite = ButtonStyle(
  backgroundColor: MaterialStateProperty.all(kColorButtonActive),
  foregroundColor: MaterialStateProperty.all(kTextColorDark),
);
final ButtonStyle kButtonBlue = ButtonStyle(
  backgroundColor: MaterialStateProperty.all(kColorAccentBlue),
  foregroundColor: MaterialStateProperty.all(Colors.white),
);
final ButtonStyle kButtonContextMenu = ButtonStyle(
  backgroundColor: MaterialStateProperty.all(kColorPrimaryLighter2),
  foregroundColor: MaterialStateProperty.all(Colors.white),
);
final ButtonStyle kButtonTransparent = ButtonStyle(
  backgroundColor: MaterialStateProperty.all(kColorTransparent),
  foregroundColor: MaterialStateProperty.all(Colors.white),
);

const Radius kCardRadius = Radius.circular(2.0);
const BorderRadius kCardBorder = BorderRadius.all(kCardRadius);

final kTimeFormat = DateFormat('HH:mm:ss');
final kDateTimeFormat = DateFormat('yyyy.MM.dd HH:mm:ss');

var kTreeViewTheme = TreeViewTheme(
  lineColor: kTextColorLight,
  lineThickness: 1,
  indent: 25 * kScale,
);

ScrollBehavior? _kScrollDraggable;
ScrollBehavior get kScrollDraggable {
  // ignore: prefer_conditional_assignment
  if (_kScrollDraggable == null) {
    _kScrollDraggable = getScrollDraggable(popupContext!);
  }
  return _kScrollDraggable!;
}

ScrollBehavior getScrollDraggable(BuildContext context) {
  return ScrollConfiguration.of(context).copyWith(
    dragDevices: {
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
    },
  );
}

ScrollBehavior? _kScrollDraggableNoScrollBar;
ScrollBehavior get kScrollDraggableNoScrollBar {
  // ignore: prefer_conditional_assignment
  if (_kScrollDraggableNoScrollBar == null) {
    _kScrollDraggableNoScrollBar = ScrollConfiguration.of(popupContext!).copyWith(
      scrollbars: false,
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      },
    );
  }
  return _kScrollDraggableNoScrollBar!;
}

ScrollBehavior? _kScrollNoScroll;
ScrollBehavior get kScrollNoScroll {
  // ignore: prefer_conditional_assignment
  if (_kScrollNoScroll == null) {
    _kScrollNoScroll = ScrollConfiguration.of(popupContext!).copyWith(
      scrollbars: false,
      physics: const NeverScrollableScrollPhysics(),
      dragDevices: {},
    );
  }
  return _kScrollNoScroll!;
}

const kScrollListDuration = Duration(milliseconds: 500);

const kTooltipDelay = Duration(milliseconds: 300);
