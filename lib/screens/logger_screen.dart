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
      child: Theme(
        data: ThemeData(textSelectionTheme: TextSelectionThemeData(selectionColor: Colors.white.withAlpha(100))),
        child: ScrollConfiguration(
          //TODO! fix multiline as soon as https://github.com/flutter/flutter/issues/104548 is fixed
          behavior: kScrollDraggable,
          child: SelectionArea(
            child: ListView.builder(
              controller: ScrollController(),
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (c, i) {
                return Text(
                  '${kTimeFormat.format(messages[i].time)}: ${messages[i].message}',
                  style: textStyle.get(messages[i].level),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _getTextStyle(LogLevel logLevel) {
    return kStyle.kTextExtraSmall.copyWith(color: getColorByLogLevel(logLevel));
  }
}
