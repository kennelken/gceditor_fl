import 'package:catcher/catcher.dart';
import 'package:computer/computer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/assets.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/components/waiting_overlay.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/screens/logger_screen.dart';
import 'package:gceditor/utils/utils.dart';

import 'components/logger_panel.dart';
import 'consts/routes.dart';
import 'managers/startup/startup_manager.dart';
import 'model/model_root.dart';
import 'model/state/log_state.dart';

final computer = Computer();
List<String>? mainArgs;

Future<void> main([List<String>? args]) async {
  mainArgs = args;
  final debugOptions = CatcherOptions(
    SilentReportMode(),
    [
      LogStateReportHandler(),
    ],
  );

  final releaseOptions = CatcherOptions(
    SilentReportMode(),
    [
      LogStateReportHandler(),
    ],
  );

  StartupManager.instance.createNewLoginFlowIfRequired(
    () => Catcher(
      debugConfig: debugOptions,
      releaseConfig: releaseOptions,
      runAppFunction: () {
        runApp(
          UncontrolledProviderScope(
            container: providerContainer,
            child: const MyApp(),
          ),
        );
      },
    ),
  );
}

BuildContext? get popupContext => navigatorKey.currentState?.overlay?.context;
late BuildContext rootContext;
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    precacheImage(AssetImage(Assets.images.icon1024PNG), context);

    return Consumer(builder: (context, watch, child) {
      watch(styleStateProvider);
      Utils.rebuildAllChildren(context);

      return RawKeyboardEvents(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          shortcuts: {
            ...WidgetsApp.defaultShortcuts,
            ...GlobalShortcuts.getIntents(),
          },
          navigatorObservers: [
            HeroController(),
          ],
          actions: {
            ...WidgetsApp.defaultActions,
            ...GlobalShortcuts.getActions(),
          },
          debugShowCheckedModeBanner: false,
          title: 'gceditor',
          theme: kStyle.kAppTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
          onGenerateRoute: (settings) {
            final page = getWidgetByScreen(settings.name!);
            return MaterialPageRoute<dynamic>(
              builder: (context) {
                rootContext = context;
                return Scaffold(
                  body: DefaultTextStyle(
                    style: kStyle.kTextBig,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Consumer(
                                builder: (context, watch, child) {
                                  final visible = watch(logStateProvider).state.visible;
                                  return visible ? LoggerScreen(key: const ValueKey('LoggerScreen')) : WaitingOverlay(child: page);
                                },
                              ),
                            ),
                            LoggerPanel(),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              settings: settings,
            );
          },
        ),
      );
    });
  }
}

class ToggleConsole extends Intent {
  const ToggleConsole();
}
