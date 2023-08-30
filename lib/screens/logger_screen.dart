import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/lazy_cache.dart';

import '../utils/scheduler.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  late final LazyCache<LogLevel, TextStyle> textStyle;
  late final ScrollController _scrollController;
  bool _stickToEnd = false;

  @override
  void initState() {
    super.initState();
    textStyle = LazyCache<LogLevel, TextStyle>(_getTextStyle);
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
    _stickToEnd = true;
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  TextStyle _getTextStyle(LogLevel logLevel) {
    return kStyle.kTextExtraSmall.copyWith(color: getColorByLogLevel(logLevel));
  }

  @override
  Widget build(context) {
    return Consumer(builder: (context, ref, child) {
      final messages = ref.watch(logStateProvider).state.messages.toList();

      if (_stickToEnd) {
        Scheduler.addPostFrameCallback(this, (_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }

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
                controller: _scrollController,
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
    });
  }

  double lastScrollPosition = 0;
  void _handleScroll() {
    if (_scrollController.position.pixels > 0 && _scrollController.position.atEdge) {
      _stickToEnd = true;
    } else if (lastScrollPosition > _scrollController.position.pixels) {
      _stickToEnd = false;
    }
    lastScrollPosition = _scrollController.position.pixels;
  }
}
