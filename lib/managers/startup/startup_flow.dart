import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/consts/routes.dart' as routes;
import 'package:gceditor/main.dart';
import 'package:gceditor/managers/startup/args_manager.dart';
import 'package:gceditor/model/app_local_storage.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_git_state.dart';
import 'package:gceditor/model/state/client_history_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/menubar_state.dart';
import 'package:gceditor/model/state/service/screen_size_service.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:listenable_stream/listenable_stream.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:statemachine/statemachine.dart';
import 'package:window_manager/window_manager.dart';

import '../../model/state/landing_page_state.dart';
import '../error_notifier_service.dart';

class StartupFlow {
  Machine<String>? machine;
  late final State<String> initialState;
  late final State<String> initializeSystemServices;
  late final State<String> initializeScreenService;
  late final State<String> runAppState;
  late final State<String> initResources;
  late final State<String> handleAppArguments;
  late final State<String> runModeFromArgs;
  late final State<String> userInputAppMode;
  late final State<String> clientStartup;
  late final State<String> serverStartup;
  late final State<String> clientReady;
  late final State<String> serverReady;
  late final State<String> readyState;

  StartupFlow(VoidCallback runApp) {
    final machine = Machine<String>();
    this.machine = machine;

    initialState = machine.newStartState('initialState')
      ..onEntry(
        () async {
          flutter.WidgetsFlutterBinding.ensureInitialized();
          await AppLocalStorage.instance.isReady();
          providerContainer.read(landingPageStateProvider).initialize();
          goToState(initializeSystemServices);
        },
      );

    initializeSystemServices = machine.newState('initializeSystemServices')
      ..onEntry(
        () async {
          providerContainer.read(errorNotifierProvider).start();

          await Future(
            () async {
              var documentsPath = '';
              if (!kIsWeb) {
                final documentsFolder = await getApplicationDocumentsDirectory();
                documentsPath = documentsFolder.path;
              }

              providerContainer.read(appStateProvider).setDefaultProjectFolder(Directory(path.join(documentsPath, Config.newProjectDefaultFolder)));
            },
          );

          goToState(handleAppArguments);
        },
      );

    handleAppArguments = machine.newState('handleAppArguments')
      ..onEntry(
        () async {
          if (mainArgs?.isNotEmpty ?? false) {
            await argsManager.parseArgs(mainArgs!);
          } else {
            // this is only for debugging from IDE
            final argsFromEnv = const String.fromEnvironment('args', defaultValue: '')
                .split(RegExp(r' +')) //
                .where((element) => element.isNotEmpty)
                .toList();
            if (argsFromEnv.isNotEmpty) {
              await argsManager.parseArgs(argsFromEnv);
            } else {
              await argsManager.parseArgs([]);
            }
          }

          goToState(initializeScreenService);
        },
      );

    initializeScreenService = machine.newState('initializeScreenService')
      ..onEntry(
        () async {
          providerContainer.read(styleStateProvider).init();
          await providerContainer.read(screenServiceProvider).state.init().then(
                (value) => goToState(runAppState),
              );
        },
      )
      ..onExit(() => _setTitle(AppMode.undefined, null));

    runAppState = machine.newState('runAppState')
      ..onEntry(
        () {
          runApp();
          goToState(initResources);
        },
      );

    initResources = machine.newState('initResources')
      ..onEntry(() async {
        //await NetworkManager.instance.refreshFreePorts();
        if (!kIsWeb) {
          await computer.turnOn(
            workersCount: (Platform.numberOfProcessors - 1).clamp(1, 4),
            verbose: false,
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        await Future.delayed(const Duration(milliseconds: 200));
        goToState(runModeFromArgs);
      })
      ..onExit(() {
        flutter.Navigator.of(rootContext).pushNamed(routes.Screen.landing);
      });

    bool runStateByAppState(AppState appState) {
      switch (appState.appMode) {
        case AppMode.client:
          goToState(clientStartup);
          return true;

        case AppMode.server:
        case AppMode.standalone:
          goToState(serverStartup);
          return true;

        default:
          break;
      }
      return false;
    }

    runModeFromArgs = machine.newState('runModeFromArgs')
      ..onEntry(
        () {
          final appState = providerContainer.read(appStateProvider.notifier).state;
          if (!runStateByAppState(appState)) //
            goToState(userInputAppMode);
        },
      );

    userInputAppMode = machine.newState('userInputAppMode') //
      ..addTransition(
        StreamTransition(
          () => providerContainer.read(appStateProvider.notifier).toStream().map((e) => e.state),
          (AppState s) {
            runStateByAppState(s);
          },
        ),
      );

    serverStartup = machine.newState('serverStartup')
      ..onEntry(() async {
        providerContainer.read(appStateProvider.notifier).initServerApp();
      })
      ..addTransition(
        StreamTransition(
          () => providerContainer.read(appStateProvider.notifier).toStream().map((e) => e.state),
          (AppState s) {
            if (s.appMode == AppMode.undefined) //
              return;

            if (s.serverApp != null) {
              if (s.appMode == AppMode.standalone) {
                goToState(clientStartup);
              } else {
                goToState(serverReady);
              }
            } else {
              providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, Loc.get.errorStartServer(s.error ?? '')));
              providerContainer.read(appStateProvider).resetClientState();
              goToState(userInputAppMode);
            }
          },
        ),
      );

    clientStartup = machine.newState('clientStartup')
      ..onEntry(() async {
        providerContainer.read(clientProblemsStateProvider); // instantiate
        providerContainer.read(appStateProvider.notifier).initClientApp();
      })
      ..addTransition(
        StreamTransition(
          () => providerContainer.read(appStateProvider.notifier).toStream().map((e) => e.state),
          (AppState s) {
            if (s.clientApp != null) {
              goToState(clientReady);
            } else if (s.error != null) {
              providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, Loc.get.errorStartClient(s.error ?? '')));
              providerContainer.read(appStateProvider).resetClientState();
              goToState(userInputAppMode);
            }
          },
        ),
      );

    clientReady = machine.newState('clientReady')
      ..onEntry(
        () async {
          providerContainer
              .read(clientHistoryStateProvider)
              .refresh(); // make sure history is refreshed before git because gir requires history data anyway
          providerContainer.read(clientGitStateProvider).refresh();
          providerContainer.read(menubarStateProvider).refresh();
          flutter.Navigator.of(rootContext).pushNamed(routes.Screen.client);
          //await Future.delayed(_delayMs);
          goToState(readyState);
        },
      );

    serverReady = machine.newState('serverReady')
      ..onEntry(
        () async {
          flutter.Navigator.of(rootContext).pushNamed(routes.Screen.server);
          //await Future.delayed(_delayMs);
          goToState(readyState);
        },
      );

    readyState = machine.newStopState('readyState')
      ..onEntry(
        () {
          final appState = providerContainer.read(appStateProvider).state;
          _setTitle(
            appState.appMode!,
            '${appState.ipAddress ?? 'localhost'}:${appState.port}${(appState.appMode != AppMode.client ? ' - ${appState.projectFile?.path}' : '')}',
          );
        },
      );
  }

  void start() {
    machine!.start();
  }

  void clear() {
    machine?.stop();
    machine = null;
  }

  bool isLoading() {
    return machine?.current == null || //
        machine!.current == initializeSystemServices ||
        machine!.current == initResources ||
        machine!.current == clientStartup ||
        machine!.current == serverStartup;
  }

  bool isReady() {
    return machine?.current != null && //
        machine!.current == readyState;
  }

  void _setTitle(AppMode mode, String? path) {
    if (!kIsWeb) {
      windowManager.setTitle('${Config.appName} - ${mode.name}${(path != null) ? ' - $path' : ''}');
    }
  }
}

void goToState(State<String> state) {
  try {
    state.enter();
    // ignore: unused_catch_stack
  } catch (e, stacktrace) {
    var listErrors = '';
    if (e is TransitionError) listErrors = e.errors.join(', ');
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Exception: $e\n$listErrors'));
    rethrow;
  }
}
