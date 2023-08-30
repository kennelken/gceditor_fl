import 'dart:async';

import 'package:computer/computer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/assets.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/components/waiting_overlay.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/screens/logger_screen.dart';

import 'components/logger_panel.dart';
import 'consts/routes.dart';
import 'managers/startup/startup_manager.dart';
import 'model/model_root.dart';
import 'model/state/log_state.dart';

final computer = Computer.create();
List<String>? mainArgs;

late BuildContext rootContext;
final navigatorKey = GlobalKey<NavigatorState>();
BuildContext? get popupContext => navigatorKey.currentState?.overlay?.context;

Future<void> main([List<String>? args]) async {
  mainArgs = args;
  StartupManager.instance.createNewLoginFlowIfRequired(
    () {
      final logHandler = LogStateReportHandler();
      runZonedGuarded(() {
        FlutterError.onError = (FlutterErrorDetails errorDetails) {
          logHandler.handleError(errorDetails);
        };
        runApp(
          UncontrolledProviderScope(
            container: providerContainer,
            child: const MyApp(),
          ),
        );
      }, (error, stackTrace) {
        logHandler.handle(error.toString());
      });
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    precacheImage(AssetImage(Assets.images.icon1024PNG), context);

    return Consumer(builder: (context, ref, child) {
      ref.watch(styleStateProvider);
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
            return SlowerPageRoute(
              builder: (context) {
                rootContext = context;
                return Scaffold(
                  backgroundColor: kColorPrimaryLighter,
                  body: DefaultTextStyle(
                    style: kStyle.kTextBig,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final visible = ref.watch(logStateProvider).state.visible;
                                  return visible ? const LoggerScreen(key: ValueKey('LoggerScreen')) : WaitingOverlay(child: page);
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

class SlowerPageRoute extends MaterialPageRoute<dynamic> {
  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  SlowerPageRoute({builder, settings}) : super(builder: builder, settings: settings);
}

class ToggleConsole extends Intent {
  const ToggleConsole();
}
