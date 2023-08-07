import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/lazy_cache.dart';

class LoggerScreen extends ConsumerWidget {
  late final LazyCache<LogLevel, TextStyle> textStyle;

  LoggerScreen({Key? key}) : super(key: key) {
    textStyle = LazyCache<LogLevel, TextStyle>(_getTextStyle);
  }

  @override
  Widget build(context, ref) {
    final messages = ref.watch(logStateProvider).state.messages.reversed.toList();

    return Container(
      height: 99999,
      width: 99999,
      padding: EdgeInsets.all(8 * kScale),
      color: kColorPrimaryDarker,
      child: ScrollConfiguration(
        behavior: kScrollDraggable,
        child: ListView.builder(
          controller: ScrollController(),
          shrinkWrap: true,
          itemCount: messages.length,
          itemBuilder: (c, i) {
            return SelectableText(
              '${kTimeFormat.format(messages[i].time)}: ${messages[i].message}',
              style: textStyle.get(messages[i].level),
              textAlign: TextAlign.left,
            );
          },
        ),
      ),
    );
  }

  TextStyle _getTextStyle(LogLevel logLevel) {
    return kStyle.kTextExtraSmall.copyWith(color: getColorByLogLevel(logLevel));
  }
}
