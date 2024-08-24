import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/app_local_storage.dart';

final styleStateProvider = ChangeNotifierProvider(
  (_) {
    kStyle = StyleState();
    return StyleStateNotifier(kStyle);
  },
);

var kStyle = StyleState();

class StyleState {
  double globalScale = AppLocalStorage.instance.globalScale ?? Config.defaultGlobalScale;
  var kAppTheme = ThemeData();
  var kDefaultText = const TextStyle();
  var kTextHuge = const TextStyle();
  var kTextBigger2 = const TextStyle();
  var kTextBigger = const TextStyle();
  var kTextBig = const TextStyle();
  var kTextRegular = const TextStyle();
  var kTextSmall = const TextStyle();
  var kTextUltraSmall = const TextStyle();
  var kTextExtraSmall = const TextStyle();
  var kTextExtraSmallInactive = const TextStyle();
  var kTextExtraSmallLightest = const TextStyle();
  var kTextExtraSmallDark = const TextStyle();
  var kTextExtraSmallSelected = const TextStyle();
  var kTextExtraSmallPropertyHeader = const TextStyle();
  var kInputTextStyleProperties = const InputDecoration();
  var kInputTextStyleSettingsProperties = const InputDecoration();
  var kInputTextStylePropertiesDark = const InputDecoration();
  var kInputTextStylePropertiesTransparent = const InputDecoration();
  var kInputTextStylePropertiesDropDownSearch = const InputDecoration();
  var kInputTextStyleTransparent = const InputDecoration();
  var kInputTextStyleErrorTransparent = const InputDecoration();
  var kInputTextStyleError = const InputDecoration();
  var kInputTextStyleWarningTransparent = const InputDecoration();
  var kInputTextStyleWarning = const InputDecoration();
  var kInputTextStyleFind = const InputDecoration();
  var kLandingInputTextStyle = const InputDecoration();
  var kPropertiesVerticalDivider = const SizedBox();
  double kTableTopRowHeight = 0;
  var kInputTextStylePropertiesTableRowId = const InputDecoration();
  var kReorderableListTheme = ThemeData();
  var kReorderableListThemeInvisibleScrollbars = ThemeData();

  double kDataTableRowHeight = 0;
  double kDataTableInlineRowHeight = 0;
  double kDataTableRowListHeight = 0;
  double kDataTableLineThickness = 0;
  double kDataTableInlineListLineThickness = 0;
  var kDataTableCellBoxDecoration = const BoxDecoration();
  var kDataTableHeadBoxDecoration = const BoxDecoration();
  var kDataTableHeadBoxDecorationNoRight = const BoxDecoration();
  var kDataTableIdBoxDecoration = const BoxDecoration();
  var kDataTableEmptyIdBoxDecoration = const BoxDecoration();
  var kDataTableCellListBoxDecoration = const BoxDecoration();
  double dropDownSelectorHeight = 0;
  double kLabelPadding = 0;

  ThemeData kInputThemeLight = ThemeData();

  // ignore: prefer_function_declarations_over_variables
  Widget Function(Checkbox checkbox) wrapCheckbox = (v) => v; //for assigning it later

  StyleState();

  InputDecoration getInputDecoration(Color color) {
    return kInputTextStylePropertiesDark.copyWith(
      fillColor: color,
      focusColor: color,
      hoverColor: color,
    );
  }
}

class StyleStateNotifier extends ChangeNotifier {
  late StyleState state;
  StyleStateNotifier(this.state);

  void init() {
    setGlobalScale(AppLocalStorage.instance.globalScale ?? Config.defaultGlobalScale);
  }

  void setGlobalScale(double value) {
    value = value.clamp(Config.minGlobalScale, Config.maxGlobalScale);
    AppLocalStorage.instance.globalScale = value;
    state.globalScale = value;

    state.kTextRegular = TextStyle(
      fontSize: 20 * state.globalScale,
      color: kTextColorLight,
      fontFamily: 'JetbrainsMono',
      overflow: TextOverflow.ellipsis,
      fontWeight: FontWeight.w300,
    );
    state.kDefaultText = state.kTextRegular;
    state.kTextHuge = state.kTextRegular.copyWith(fontSize: 50 * state.globalScale);
    state.kTextBigger2 = state.kTextRegular.copyWith(fontSize: 40 * state.globalScale);
    state.kTextBigger = state.kTextRegular.copyWith(fontSize: 28 * state.globalScale);
    state.kTextBig = state.kTextRegular.copyWith(fontSize: 24 * state.globalScale);
    state.kTextSmall = state.kTextRegular.copyWith(fontSize: 16 * state.globalScale);
    state.kTextUltraSmall = state.kTextRegular.copyWith(fontSize: 11 * state.globalScale);
    state.kTextExtraSmall = state.kTextRegular.copyWith(fontSize: 14 * state.globalScale);
    state.kTextExtraSmallInactive = state.kTextRegular.copyWith(fontSize: 14 * state.globalScale, color: kTextColorLightHalfTransparent);
    state.kTextExtraSmallLightest = state.kTextRegular.copyWith(fontSize: 14 * state.globalScale, color: kTextColorLightest);
    state.kTextExtraSmallDark = state.kTextRegular.copyWith(fontSize: 14 * state.globalScale, color: kTextColorDark);
    state.kTextExtraSmallSelected = state.kTextExtraSmallLightest.copyWith(fontWeight: FontWeight.bold);
    state.kTextExtraSmallPropertyHeader = state.kTextRegular.copyWith(fontSize: 12.5 * state.globalScale);

    state.kInputTextStyleProperties = InputDecoration(
      isDense: true,
      hintStyle: state.kTextSmall.copyWith(color: kTextColorLight2),
      labelStyle: state.kTextSmall,
      contentPadding: EdgeInsets.symmetric(horizontal: 7 * state.globalScale, vertical: 10 * state.globalScale),
      border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: kCardBorder),
      disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kColorTransparent), borderRadius: kCardBorder),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kColorTransparent), borderRadius: kCardBorder),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kColorTransparent), borderRadius: kCardBorder),
      fillColor: kColorAccentBlue1_5,
      focusColor: kColorAccentBlue1_5,
      hoverColor: kColorAccentBlue1_5,
      filled: true,
    );

    state.kInputTextStyleSettingsProperties = state.kInputTextStyleProperties.copyWith(
      fillColor: kColorAccentBlue2,
      focusColor: kColorAccentBlue2,
      hoverColor: kColorAccentBlue2,
    );

    state.kInputTextStylePropertiesDark = state.kInputTextStyleProperties.copyWith(
      fillColor: kColorPrimary,
      focusColor: kColorPrimary,
      hoverColor: kColorPrimary,
    );

    state.kInputTextStylePropertiesTransparent = state.kInputTextStyleProperties.copyWith(
      fillColor: kColorTransparent,
      focusColor: kColorTransparent,
      hoverColor: kColorTransparent,
    );

    state.kInputTextStylePropertiesDropDownSearch = state.getInputDecoration(kColorAccentBlue2_5);
    state.kInputTextStyleTransparent = state.getInputDecoration(kColorTransparent);
    state.kInputTextStyleError = state.getInputDecoration(kColorAccentRed2);
    state.kInputTextStyleErrorTransparent = state.getInputDecoration(kColorAccentRed2.withAlpha(kFindResultBackgroundAlpha));
    state.kInputTextStyleWarning = state.getInputDecoration(kColorAccentYellow);
    state.kInputTextStyleWarningTransparent = state.getInputDecoration(kColorAccentYellow.withAlpha(kFindResultBackgroundAlpha));
    state.kInputTextStyleFind = state.getInputDecoration(kColorPrimary);

    state.kLandingInputTextStyle = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 11 * kScale, vertical: 15 * kScale),
    );

    state.kPropertiesVerticalDivider = SizedBox(height: 12 * state.globalScale);
    state.kTableTopRowHeight = 32.0 * state.globalScale; // means a row of home layout

    state.kAppTheme = ThemeData(
      dialogBackgroundColor: kColorBackground,
      scaffoldBackgroundColor: kColorBackground,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: state.kTextSmall.copyWith(color: kColorPrimaryLight),
        labelStyle: state.kTextSmall,
        contentPadding: EdgeInsets.symmetric(horizontal: 10 * state.globalScale),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: kCardBorder),
        disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kColorPrimaryDarker), borderRadius: kCardBorder),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kColorPrimaryDarker), borderRadius: kCardBorder),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: kColorPrimaryDarker), borderRadius: kCardBorder),
        fillColor: kColorPrimaryLighter,
        focusColor: kColorPrimaryLighter,
        hoverColor: kColorPrimaryLighter,
        filled: true,
      ),
      fontFamily: 'JetbrainsMono',
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: kColorPrimaryLight,
        selectionHandleColor: Colors.red,
      ),
      textTheme: TextTheme(
        titleMedium: state.kTextExtraSmallLightest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(4 * state.globalScale),
          backgroundColor: kColorAccentBlue,
          foregroundColor: kColorAccentBlue,
          textStyle: state.kTextBig,
          shape: const RoundedRectangleBorder(borderRadius: kCardBorder),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.all(4 * state.globalScale),
          foregroundColor: kColorTextButton,
          textStyle: state.kTextBig,
          shape: const RoundedRectangleBorder(borderRadius: kCardBorder),
          backgroundColor: kColorButtonActive,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(4 * state.globalScale),
          foregroundColor: kColorTextButton,
          textStyle: state.kTextBig,
          shape: const RoundedRectangleBorder(borderRadius: kCardBorder),
          backgroundColor: kColorButtonActive,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(8.0 * state.globalScale),
        thumbColor: WidgetStateProperty.resolveWith(scrollbarThumbColor),
        //trackColor: MaterialStateProperty.all(kTextColorLightHalfTransparent),
        thumbVisibility: WidgetStateProperty.all(true),
        interactive: true,
        trackVisibility: WidgetStateProperty.all(true),
      ),
      checkboxTheme: const CheckboxThemeData(
        side: BorderSide(color: kColorAccentBlue),
        fillColor: WidgetStatePropertyAll(kColorAccentBlue),
      ),
      colorScheme: ColorScheme.fromSwatch(primarySwatch: kColorPrimary).copyWith(secondary: kColorSecondary, surface: kColorBackground),
    );

    state.kInputThemeLight = state.kAppTheme.copyWith(
      textSelectionTheme: state.kAppTheme.textSelectionTheme.copyWith(
        cursorColor: kColorPrimaryDarker,
        selectionColor: kColorPrimaryLight,
        selectionHandleColor: kColorPrimaryLight,
      ),
      inputDecorationTheme: state.kAppTheme.inputDecorationTheme.copyWith(
        isDense: true,
        fillColor: kTextColorLightest,
        focusColor: kTextColorLightest,
        hoverColor: kTextColorLightest,
        border: const UnderlineInputBorder(borderSide: BorderSide.none, borderRadius: kCardBorder),
        disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: kColorPrimaryDarker), borderRadius: kCardBorder),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: kColorPrimaryDarker), borderRadius: kCardBorder),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: kColorPrimaryDarker), borderRadius: kCardBorder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
      ),
      textTheme: TextTheme(
        titleMedium: kStyle.kTextExtraSmall.copyWith(
          color: kColorPrimaryDarker,
        ),
        bodyLarge: kStyle.kTextExtraSmall.copyWith(
          color: kColorPrimaryDarker,
        ),
        bodyMedium: kStyle.kTextExtraSmall.copyWith(
          color: kColorPrimaryDarker,
        ),
      ),
    );

    state.kInputTextStylePropertiesTableRowId = state.kInputTextStyleProperties.copyWith(
      fillColor: kColorTransparent,
      focusColor: kColorTransparent,
      hoverColor: kColorTransparent,
    );

    state.kReorderableListTheme = state.kAppTheme.copyWith(
      canvasColor: kColorTransparent,
      shadowColor: kColorTransparent,
      iconTheme: IconThemeData(
        color: kColorPrimaryLight,
        size: 18 * state.globalScale,
      ),
    );

    state.kReorderableListThemeInvisibleScrollbars = state.kReorderableListTheme.copyWith(
      scrollbarTheme: state.kAppTheme.scrollbarTheme.copyWith(
        thumbVisibility: WidgetStateProperty.all(false),
      ),
    );

    state.kDataTableRowHeight = 33.0 * state.globalScale;
    state.kDataTableInlineRowHeight = 32.0 * state.globalScale;
    state.kDataTableRowListHeight = 120.0 * state.globalScale;
    state.kDataTableLineThickness = 3.0 * state.globalScale;
    state.kDataTableInlineListLineThickness = 1.0 * state.globalScale;
    state.kDataTableCellBoxDecoration = BoxDecoration(
      border: Border(
        right: BorderSide(color: kColorDataTableLine, width: state.kDataTableLineThickness),
        bottom: BorderSide(color: kColorDataTableLine, width: state.kDataTableLineThickness),
      ),
      color: kColorDataTableBackground,
    );
    state.kDataTableHeadBoxDecoration = BoxDecoration(
      border: Border(
        right: BorderSide(color: kColorDataTableLine, width: state.kDataTableLineThickness),
        bottom: BorderSide(color: kColorDataTableLine, width: state.kDataTableLineThickness),
      ),
      color: kColorAccentTeal,
    );
    state.kDataTableHeadBoxDecorationNoRight = BoxDecoration(
      border: Border(
        bottom: BorderSide(color: kColorDataTableLine, width: state.kDataTableLineThickness),
      ),
      color: kColorAccentTeal,
    );
    state.kDataTableIdBoxDecoration = BoxDecoration(
      border: Border(
        bottom: BorderSide(color: kColorDataTableLine, width: state.kDataTableLineThickness),
      ),
      color: kColorAccentTeal,
    );
    state.kDataTableEmptyIdBoxDecoration = BoxDecoration(
      border: Border(
        bottom: BorderSide(color: kColorDataTableLine, width: state.kDataTableLineThickness),
      ),
      color: kColorAccentTealDark,
    );
    state.kDataTableCellListBoxDecoration = BoxDecoration(
      border: Border(
        right: BorderSide(color: kColorDataTableLine, width: state.kDataTableInlineListLineThickness),
        bottom: BorderSide(color: kColorDataTableLine, width: state.kDataTableInlineListLineThickness),
        top: BorderSide(color: kColorDataTableLine, width: state.kDataTableInlineListLineThickness),
        left: BorderSide(color: kColorDataTableLine, width: state.kDataTableInlineListLineThickness),
      ),
      color: kColorDataTableBackground,
    );

    state.wrapCheckbox = (checkbox) {
      return SizedBox(
        width: 30 * state.globalScale,
        height: 30 * state.globalScale,
        child: FittedBox(
          alignment: Alignment.center,
          fit: BoxFit.contain,
          child: checkbox,
        ),
      );
    };

    state.dropDownSelectorHeight = 380 * kScale;
    state.kLabelPadding = 5 * kScale;

    notifyListeners();
  }

  Color? scrollbarThumbColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.dragged)) //
      return const Color.fromARGB(200, 0, 0, 0);
    if (states.contains(WidgetState.hovered)) //
      return const Color.fromARGB(110, 0, 0, 0);
    return const Color.fromARGB(50, 0, 0, 0);
  }
}
