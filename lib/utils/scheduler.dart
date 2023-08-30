import 'package:flutter/scheduler.dart';

class Scheduler {
  static final Map<Object, FrameCallback> _callbacks = <Object, FrameCallback>{};
  static bool _scheduled = false;

  static void addPostFrameCallback(Object caller, FrameCallback callback) {
    _callbacks[caller] = callback;
    if (!_scheduled) {
      SchedulerBinding.instance.addPostFrameCallback(_handleNextFrame);
      _scheduled = true;
    }
  }

  static void _handleNextFrame(Duration timeStamp) {
    _scheduled = false;
    final values = _callbacks.values.toList();
    _callbacks.clear();
    for (final callback in values) {
      callback(timeStamp);
    }
  }
}
