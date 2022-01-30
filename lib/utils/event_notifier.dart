import 'package:flutter/material.dart';

class EventNotifier<T> extends ChangeNotifier {
  T? event;
  EventNotifier();

  void dispatchEvent([T? event]) {
    this.event = event;
    notifyListeners();
  }
}
