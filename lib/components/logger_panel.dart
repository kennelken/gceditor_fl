import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/server_history_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/lazy_cache.dart';

class LoggerPanel extends ConsumerWidget {
  late final LazyCache<LogLevel, TextStyle> textStyle;

  LoggerPanel({Key? key}) : super(key: key) {
    textStyle = LazyCache<LogLevel, TextStyle>(_getTextStyle);
  }

  @override
  Widget build(context, watch) {
    final appState = watch(appStateProvider).state;
    final logState = watch(logStateProvider).state;
    final serverHistoryState = watch(serverHistoryStateProvider).state;

    return Material(
      color: kColorAccentOrange,
      child: InkWell(
        enableFeedback: true,
        splashColor: kColorAccentOrangeSplash,
        highlightColor: kColorAccentOrangeHover,
        hoverColor: kColorAccentOrangeHover,
        onTap: _toggleLoggerScreen,
        onLongPress: () {},
        child: SizedBox(
          width: 99999,
          height: 25 * kScale,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5 * kScale, vertical: 2 * kScale),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    logState.messages.lastOrNull?.message ?? '',
                    style: _getTextStyle(logState.messages.lastOrNull?.level),
                    textAlign: TextAlign.left,
                  ),
                ),
                Text(
                  Loc.get.clientStatus(watch(appStateProvider).state.clientConnected ?? false ? Loc.get.statusOnline : Loc.get.statusOffline),
                  style: kStyle.kTextExtraSmallLightest,
                  textAlign: TextAlign.left,
                ),
                SizedBox(width: 40 * kScale),
                Text(
                  Loc.get.serverStatus(
                    appState.serverWorking ?? false
                        ? (Loc.get.connectedClientsCount(appState.clientsCount ?? 0) +
                            ' ' +
                            (serverHistoryState.currentTag == null ? '' : '#${serverHistoryState.currentTag}'))
                        : Loc.get.statusOffline,
                  ),
                  style: kStyle.kTextExtraSmallLightest,
                  textAlign: TextAlign.left,
                ),
                SizedBox(width: 12 * kScale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle? _getTextStyle(LogLevel? logLevel) {
    if (logLevel == null) //
      return null;
    final style = kStyle.kTextExtraSmall;
    return style.copyWith(color: getColorByLogLevel(logLevel));
  }

  void _toggleLoggerScreen() {
    providerContainer.read(logStateProvider).toggleVisible(null);
  }
}
