import 'dart:collection';

import 'package:another_flushbar/flushbar.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/style_state.dart';

import '../../main.dart';

class PopupMessages {
  static PopupMessages? __instance;
  // ignore: prefer_constructors_over_static_methods
  static PopupMessages get _instance {
    __instance ??= PopupMessages();
    return __instance!;
  }

  final _messagesQueue = ListQueue<PopupMessageData>();
  final _slotsOffsets = <double>[0]; //<double>[0, 0.2, 0.4, 0.6]; // does not work with multiple messages :(
  final _occupiedSlots = <int>{};

  static void show(PopupMessageData message) {
    _instance._enqueue(message);
  }

  void _enqueue(PopupMessageData message) {
    _messagesQueue.add(message);
    _tryToShowNextMessage();
  }

  // ignore: avoid_void_async
  void _tryToShowNextMessage() async {
    if (_messagesQueue.isEmpty) //
      return;

    final slot = IntRange(0, _slotsOffsets.length - 1).firstOrNullWhere((i) => !_occupiedSlots.contains(i));
    if (slot == null) //
      return;

    final message = _messagesQueue.removeFirst();

    if (popupContext == null) {
      print('popupContext is null. Should not be a problem.');
      return;
    }

    _occupiedSlots.add(slot);

    await Flushbar(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      borderRadius: const BorderRadius.vertical(bottom: kCardRadius),
      endOffset: Offset(0, _slotsOffsets[slot]),
      flushbarPosition: FlushbarPosition.TOP,
      forwardAnimationCurve: Curves.easeOutExpo,
      reverseAnimationCurve: Curves.easeOut,
      messageText: Text(
        message.message,
        style: kStyle.kTextSmall.copyWith(color: message.color),
        maxLines: 6,
      ),
      duration: message.duration ?? const Duration(milliseconds: 1200),
      flushbarStyle: FlushbarStyle.FLOATING,
      backgroundColor: kColorPrimaryDarker.withAlpha(200),
      messageColor: message.color ?? kTextColorDark,
    ).show(popupContext!);

    _occupiedSlots.remove(slot);
    _tryToShowNextMessage();
  }
}

class PopupMessageData {
  String message;
  Color? color;
  Duration? duration;

  PopupMessageData({
    required this.message,
    this.color,
    this.duration,
  });
}
