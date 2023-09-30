import 'dart:convert';
import 'dart:math';

import 'package:dartx/dartx_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class Utils {
  static bool isIOs(BuildContext context) => Theme.of(context).platform == TargetPlatform.iOS;

  static int enumToInt<T extends dynamic>(T enumValue) {
    return enumValue._index as int;
  }

  static T intToEnum<T extends dynamic>(List<T> values, int? enumIndex, T defaultValue) {
    if (enumIndex == null) return defaultValue;
    if (enumIndex >= values.length) return defaultValue;
    return values[enumIndex];
  }

  static void exit() {
    SystemNavigator.pop(animated: true);
  }

  static Color randomColor() {
    return Color(0xFF000000 + (Random().nextInt(0x00FFFFFF)));
  }

  static Color randomMaterialColor() {
    return Color(allMateralColors[Random().nextInt(allMateralColors.length)]);
  }

  static String randomEmoji() {
    return allEmoji[Random().nextInt(allEmoji.length)];
  }

  static Future waitWhile(ReturnBool predicate, [Duration? duration]) {
    duration ??= const Duration(milliseconds: 16);
    return Future.doWhile(() => Future.delayed(duration!).then((_) => predicate()));
  }

  static Widget rowDivider([double height = 10]) {
    return SizedBox(
      height: height,
    );
  }

  static double round(double val, int? decimalDigits) {
    if (decimalDigits == null) return val;

    final mod = pow(10.0, decimalDigits);
    return (val * mod).roundToDouble() / mod;
  }

  static MaterialColor createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    for (var i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (final strength in strengths) {
      final ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  static final _uuidV4Regex = RegExp('[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}');
  static bool isUuidV4(String value) {
    return _uuidV4Regex.stringMatch(value) == value;
  }

  static List<T> copyAndReorder<T>(List<T> list, int oldIndex, int newIndex) {
    final listCopy = list.toList();
    listCopy.insert(newIndex, listCopy[oldIndex]);

    final modifiedIndexes = getModifiedIndexesAfterReordering(oldIndex, newIndex);
    listCopy.removeAt(modifiedIndexes.oldValue!);
    return listCopy;
  }

  static ValueChange<int> getModifiedIndexesAfterReordering(int oldIndex, int newIndex) {
    final result = ValueChange(oldIndex, newIndex);

    if (newIndex > oldIndex) //
      result.newValue = newIndex - 1;
    else if (newIndex < oldIndex) //
      result.oldValue = oldIndex + 1;

    return result;
  }

  static bool hasFlag(int mask, int flagMask) {
    return (mask & flagMask) > 0;
  }

  static int setFlag(int mask, int flagMask) {
    return mask | flagMask;
  }

  static int removeFlag(int mask, int flagMask) {
    return mask & ~flagMask;
  }

  static bool? tryParseBool(String value) {
    if (value == '1' || value == '1.0' || value.toLowerCase() == 'true') return true;
    if (value == '0' || value == '0.0' || value.toLowerCase() == 'false') return false;
    return null;
  }

  static String floatWithSign(double value) {
    if (value == -0.0) return '+0.0';
    return '${value >= 0 ? '+' : ''}$value';
  }

  static final parametersRegExp = RegExp(r'{(?<name>[^{}]+)}');
  static String pasteParameters(String input, Map<String, dynamic> params) {
    var result = input;

    final matches = parametersRegExp.allMatches(input).toList();
    for (var i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      result = result.replaceRange(match.start, match.end, params[match.group(1)]?.toString() ?? match.group(0)!);
    }

    return result;
  }

  static String escapeRegexSpecial(String input, bool addWordBounderies) {
    const regexSpecialSymbols = {'\\', '^', '\$', '.', '|', '?', '*', '+', '(', ')', '[', ']', '{', '}'};

    final regexBuffer = StringBuffer();

    if (addWordBounderies) //
      regexBuffer.write('\\b');
    for (var i = 0; i < input.length; i++) {
      if (regexSpecialSymbols.contains(input[i])) //
        regexBuffer.write('\\');
      regexBuffer.write(input[i]);
    }
    if (addWordBounderies) //
      regexBuffer.write('\\b');

    return regexBuffer.toString();
  }

  static void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }
}

class ValueChange<T> {
  T? oldValue;
  T? newValue;

  ValueChange(this.oldValue, this.newValue);
}

typedef ReturnBool = bool Function();
typedef Func0<TOut> = TOut Function();
typedef Func1<T1, TOut> = TOut Function(T1 param1);
typedef Func2<T1, T2, TOut> = TOut Function(T1 param1, T2 param2);
typedef Func3<T1, T2, T3, TOut> = TOut Function(T1 param1, T2 param2, T3 param3);
typedef Func4<T1, T2, T3, T4, TOut> = TOut Function(T1 param1, T2 param2, T3 param3, T4 param4);
typedef Action1<T1> = void Function(T1 param1);
typedef Action2<T1, T2> = void Function(T1 param1, T2 param2);
typedef Action3<T1, T2, T3> = void Function(T1 param1, T2 param2, T3 param3);
typedef Action4<T1, T2, T3, T4> = void Function(T1 param1, T2 param2, T3 param3, T4 param4);

extension StringFormatExtension on String {
  String format(Map<String, dynamic> parameters) => Utils.pasteParameters(this, parameters);
}

extension NumExtensions on num {
  num safeClamp(num min, num max) {
    if (min > max) return min;
    return clamp(min, max);
  }
}

extension SafeCasting on dynamic {
  T? safeAs<T>() {
    if (this == null) return null;
    if (this is T) return this as T;
    return null;
  }
}

extension ListExtensions<T> on List<T> {
  bool has(T element) {
    return indexOf(element) > -1;
  }
}

extension StringToEnum on String {
  T? toEnum<T>(List<T> values) => values.firstOrNullWhere((e) => e.toString() == this);
}

extension CloneJson on Map<String, dynamic> {
  Map<String, dynamic> clone() => jsonDecode(jsonEncode(this));
}

const allMateralColors = [
  0xFFF44336,
  0xFFFFEBEE,
  0xFFFFCDD2,
  0xFFEF9A9A,
  0xFFE57373,
  0xFFEF5350,
  0xFFF44336,
  0xFFE53935,
  0xFFD32F2F,
  0xFFC62828,
  0xFFB71C1C,
  0xFFFF8A80,
  0xFFFF5252,
  0xFFFF1744,
  0xFFD50000,
  0xFFE91E63,
  0xFFFCE4EC,
  0xFFF8BBD0,
  0xFFF48FB1,
  0xFFF06292,
  0xFFEC407A,
  0xFFE91E63,
  0xFFD81B60,
  0xFFC2185B,
  0xFFAD1457,
  0xFF880E4F,
  0xFFFF80AB,
  0xFFFF4081,
  0xFFF50057,
  0xFFC51162,
  0xFF9C27B0,
  0xFFF3E5F5,
  0xFFE1BEE7,
  0xFFCE93D8,
  0xFFBA68C8,
  0xFFAB47BC,
  0xFF9C27B0,
  0xFF8E24AA,
  0xFF7B1FA2,
  0xFF6A1B9A,
  0xFF4A148C,
  0xFFEA80FC,
  0xFFE040FB,
  0xFFD500F9,
  0xFFAA00FF,
  0xFF673AB7,
  0xFFEDE7F6,
  0xFFD1C4E9,
  0xFFB39DDB,
  0xFF9575CD,
  0xFF7E57C2,
  0xFF673AB7,
  0xFF5E35B1,
  0xFF512DA8,
  0xFF4527A0,
  0xFF311B92,
  0xFFB388FF,
  0xFF7C4DFF,
  0xFF651FFF,
  0xFF6200EA,
  0xFF3F51B5,
  0xFFE8EAF6,
  0xFFC5CAE9,
  0xFF9FA8DA,
  0xFF7986CB,
  0xFF5C6BC0,
  0xFF3F51B5,
  0xFF3949AB,
  0xFF303F9F,
  0xFF283593,
  0xFF1A237E,
  0xFF8C9EFF,
  0xFF536DFE,
  0xFF3D5AFE,
  0xFF304FFE,
  0xFF2196F3,
  0xFFE3F2FD,
  0xFFBBDEFB,
  0xFF90CAF9,
  0xFF64B5F6,
  0xFF42A5F5,
  0xFF2196F3,
  0xFF1E88E5,
  0xFF1976D2,
  0xFF1565C0,
  0xFF0D47A1,
  0xFF82B1FF,
  0xFF448AFF,
  0xFF2979FF,
  0xFF2962FF,
  0xFF03A9F4,
  0xFFE1F5FE,
  0xFFB3E5FC,
  0xFF81D4FA,
  0xFF4FC3F7,
  0xFF29B6F6,
  0xFF03A9F4,
  0xFF039BE5,
  0xFF0288D1,
  0xFF0277BD,
  0xFF01579B,
  0xFF80D8FF,
  0xFF40C4FF,
  0xFF00B0FF,
  0xFF0091EA,
  0xFF00BCD4,
  0xFFE0F7FA,
  0xFFB2EBF2,
  0xFF80DEEA,
  0xFF4DD0E1,
  0xFF26C6DA,
  0xFF00BCD4,
  0xFF00ACC1,
  0xFF0097A7,
  0xFF00838F,
  0xFF006064,
  0xFF84FFFF,
  0xFF18FFFF,
  0xFF00E5FF,
  0xFF00B8D4,
  0xFF009688,
  0xFFE0F2F1,
  0xFFB2DFDB,
  0xFF80CBC4,
  0xFF4DB6AC,
  0xFF26A69A,
  0xFF009688,
  0xFF00897B,
  0xFF00796B,
  0xFF00695C,
  0xFF004D40,
  0xFFA7FFEB,
  0xFF64FFDA,
  0xFF1DE9B6,
  0xFF00BFA5,
  0xFF4CAF50,
  0xFFE8F5E9,
  0xFFC8E6C9,
  0xFFA5D6A7,
  0xFF81C784,
  0xFF66BB6A,
  0xFF4CAF50,
  0xFF43A047,
  0xFF388E3C,
  0xFF2E7D32,
  0xFF1B5E20,
  0xFFB9F6CA,
  0xFF69F0AE,
  0xFF00E676,
  0xFF00C853,
  0xFF8BC34A,
  0xFFF1F8E9,
  0xFFDCEDC8,
  0xFFC5E1A5,
  0xFFAED581,
  0xFF9CCC65,
  0xFF8BC34A,
  0xFF7CB342,
  0xFF689F38,
  0xFF558B2F,
  0xFF33691E,
  0xFFCCFF90,
  0xFFB2FF59,
  0xFF76FF03,
  0xFF64DD17,
  0xFFCDDC39,
  0xFFF9FBE7,
  0xFFF0F4C3,
  0xFFE6EE9C,
  0xFFDCE775,
  0xFFD4E157,
  0xFFCDDC39,
  0xFFC0CA33,
  0xFFAFB42B,
  0xFF9E9D24,
  0xFF827717,
  0xFFF4FF81,
  0xFFEEFF41,
  0xFFC6FF00,
  0xFFAEEA00,
  0xFFFFEB3B,
  0xFFFFFDE7,
  0xFFFFF9C4,
  0xFFFFF59D,
  0xFFFFF176,
  0xFFFFEE58,
  0xFFFFEB3B,
  0xFFFDD835,
  0xFFFBC02D,
  0xFFF9A825,
  0xFFF57F17,
  0xFFFFFF8D,
  0xFFFFFF00,
  0xFFFFEA00,
  0xFFFFD600,
  0xFFFFC107,
  0xFFFFF8E1,
  0xFFFFECB3,
  0xFFFFE082,
  0xFFFFD54F,
  0xFFFFCA28,
  0xFFFFC107,
  0xFFFFB300,
  0xFFFFA000,
  0xFFFF8F00,
  0xFFFF6F00,
  0xFFFFE57F,
  0xFFFFD740,
  0xFFFFC400,
  0xFFFFAB00,
  0xFFFF9800,
  0xFFFFF3E0,
  0xFFFFE0B2,
  0xFFFFCC80,
  0xFFFFB74D,
  0xFFFFA726,
  0xFFFF9800,
  0xFFFB8C00,
  0xFFF57C00,
  0xFFEF6C00,
  0xFFE65100,
  0xFFFFD180,
  0xFFFFAB40,
  0xFFFF9100,
  0xFFFF6D00,
  0xFFFF5722,
  0xFFFBE9E7,
  0xFFFFCCBC,
  0xFFFFAB91,
  0xFFFF8A65,
  0xFFFF7043,
  0xFFFF5722,
  0xFFF4511E,
  0xFFE64A19,
  0xFFD84315,
  0xFFBF360C,
  0xFFFF9E80,
  0xFFFF6E40,
  0xFFFF3D00,
  0xFFDD2C00,
  0xFF795548,
  0xFFEFEBE9,
  0xFFD7CCC8,
  0xFFBCAAA4,
  0xFFA1887F,
  0xFF8D6E63,
  0xFF795548,
  0xFF6D4C41,
  0xFF5D4037,
  0xFF4E342E,
  0xFF3E2723,
  0xFF9E9E9E,
  0xFFFAFAFA,
  0xFFF5F5F5,
  0xFFEEEEEE,
  0xFFE0E0E0,
  0xFFBDBDBD,
  0xFF9E9E9E,
  0xFF757575,
  0xFF616161,
  0xFF424242,
  0xFF212121,
  0xFF607D8B,
  0xFFECEFF1,
  0xFFCFD8DC,
  0xFFB0BEC5,
  0xFF90A4AE,
  0xFF78909C,
  0xFF607D8B,
  0xFF546E7A,
  0xFF455A64,
  0xFF37474F,
  0xFF263238,
];

List<String>? _allEmoji;
List<String> get allEmoji {
  if (_allEmoji == null) {
    final ranges = [
/*       [0x00A9, 0],
      [0x00AE, 0],
      [0x203C, 0],
      [0x2049, 0],
      [0x20E3, 0],
      [0x2122, 0],
      [0x2139, 0],
      [0x231A, 0],
      [0x231B, 0],
      [0x2328, 0],
      [0x23CF, 0],
      [0x24C2, 0],
      [0x25AA, 0],
      [0x25AB, 0],
      [0x25B6, 0],
      [0x2934, 0],
      [0x2935, 0],
      [0x3030, 0],
      [0x303D, 0],
      [0x3297, 0],
      [0x3299, 0],
      [0x2194, 0x2199],
      [0x21A9, 0x21AA],
      [0x23F8, 0x23FA],
      [0x23E9, 0x23F3],
      [0x25FB, 0x25FE],
      [0x2600, 0x27EF],
      [0x2B00, 0x2BFF],
      [0x1F000, 0x1F02F],
      [0x1F0A0, 0x1F0FF],
      [0x1F100, 0x1F64F],
      [0x1F680, 0x1F6FF],
      [0x1F910, 0x1F96B],
      [0x1F980, 0x1F9E0], */
      [0x1F600, 0x1F64F]
    ];
    _allEmoji = ranges.expand((e) => e[1] == 0 ? e.take(1) : IntRange(e[0], e[1] + 1)).map((n) => String.fromCharCode(n)).toList();
  }

  return _allEmoji!;
}

extension Chaining on Object {
  T? safeAs<T>() {
    if (this is T) {
      return this as T;
    }
    return null;
  }
}

extension ChainingT<T> on T {
  TOut as<TOut>(Func1<T, TOut> func) {
    return func(this);
  }
}
