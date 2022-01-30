import 'package:flutter/material.dart';

class ValueChangeNotifier<T> extends ChangeNotifier {
  late T value;

  ValueChangeNotifier(this.value);

  void setValue(T value, [bool silent = false]) {
    this.value = value;
    if (!silent) notifyListeners();
  }
}
