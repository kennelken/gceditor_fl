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
typedef Action0 = void Function();
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

extension ListExtensionsT<T> on List<T> {
  bool has(T element) {
    return indexOf(element) > -1;
  }
}

extension ListExtensions on List<double> {
  void normalize() {
    final sum = fold(0.0, (previousValue, element) => previousValue + element.abs());
    if (sum == 0) {
      return;
    }
    for (var i = 0; i < length; i++) {
      this[i] = this[i] / sum;
    }
  }
}

extension StringToEnum on String {
  T? toEnum<T>(List<T> values) => values.firstOrNullWhere((e) => e.toString() == this);
}

extension CloneJson on Map<String, dynamic> {
  Map<String, dynamic> clone() => jsonDecode(jsonEncode(this));
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

  T given(Action1<T> func) {
    func(this);
    return this;
  }
}

extension MapExtensions<TKey, TValue> on Map<TKey, TValue> {
  void addIfMissing(TKey key, Func1<TKey, TValue> value) {
    if (containsKey(key)) //
      return;
    this[key] = value(key);
  }
}

class ValueWrapper<T> {
  late T value;
  ValueWrapper({required this.value});
}
