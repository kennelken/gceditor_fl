import 'dart:io';

import 'package:args/args.dart';
import 'package:gceditor/model/db_network/authentification_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/server_history_state.dart';

ArgsManager argsManager = ArgsManager();

class ArgsManager {
  static const _aClient = 'client';
  static const _aServer = 'server';
  static const _aProjectPath = 'project_path';
  static const _aOutputPath = 'output_path';
  static const _aAuthPath = 'auth_path';
  static const _aHistoryPath = 'history_path';
  static const _aLogin = 'login';
  static const _aSecret = 'secret';
  static const _aPassword = 'password';
  static const _aHost = 'host';
  static const _aPort = 'port';
  static const _aHistoryTag = 'history_tag';
  static const _aHelp = 'help';
  static const _aRegisterLogin = 'register_login';
  static const _aRegisterSecret = 'register_secret';
  static const _aUnregisterLogin = 'unregister_login';
  static const _aQuit = 'quit';

  Future parseArgs(List<String> args) async {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ArgsManager.parseArgs(${args.join(', ')})'));
    final parser = _buildParser();
    final argResults = parser.parse(args);

    try {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(argResults[_aHelp] == true ? LogLevel.warning : LogLevel.log, 'List of supported arguments:\n${parser.usage}'));

      var runClient = false;
      var runServer = false;

      if (argResults.wasParsed(_aServer) && checkRequredParameters(argResults, [_aPort, _aProjectPath, _aOutputPath, _aAuthPath, _aHistoryPath])) {
        final port = int.parse(argResults[_aPort]);
        final projectPath = argResults[_aProjectPath];
        final outputPath = argResults[_aOutputPath];
        final authPath = argResults[_aAuthPath];

        providerContainer.read(appStateProvider).setServerParams(port, File(projectPath), Directory(outputPath));
        providerContainer.read(authListStateProvider).setPath(authPath);

        final historyTag = argResults[_aHistoryTag];
        providerContainer.read(serverHistoryStateProvider).setTag(historyTag);

        final historyPath = argResults[_aHistoryPath];
        providerContainer.read(serverHistoryStateProvider).setPath(historyPath);

        runServer = true;
      }

      if (argResults.wasParsed(_aClient) && checkRequredParameters(argResults, [_aPort, _aHost, _aLogin, _aSecret, _aPassword])) {
        final port = int.parse(argResults[_aPort]);
        final host = argResults[_aHost];
        final login = argResults[_aLogin];
        final secret = argResults[_aSecret];
        final password = argResults[_aPassword];

        providerContainer
            .read(appStateProvider)
            .setClientAppParams(host, port, AuthentificationData.values(login: login, secret: secret, password: password));

        runClient = true;
      }

      if ((argResults.wasParsed(_aRegisterLogin) || argResults.wasParsed(_aRegisterSecret)) && //
          checkRequredParameters(argResults, [_aRegisterLogin, _aRegisterSecret, _aAuthPath])) {
        final login = argResults[_aRegisterLogin];
        final secret = argResults[_aRegisterSecret];
        final authPath = argResults[_aAuthPath];

        providerContainer.read(authListStateProvider).setPath(authPath);
        await providerContainer.read(authListStateProvider).registerNewLogin(login, secret);
      }

      if ((argResults.wasParsed(_aUnregisterLogin)) && //
          checkRequredParameters(argResults, [_aUnregisterLogin, _aAuthPath])) {
        final login = argResults[_aUnregisterLogin];
        final authPath = argResults[_aAuthPath];

        providerContainer.read(authListStateProvider).setPath(authPath);
        await providerContainer.read(authListStateProvider).removeLogin(login);
      }

      if (argResults[_aQuit] == true) //
        exit(0);

      if (runClient && runServer) {
        providerContainer.read(authListStateProvider).resetPasswordOrRegister(
              providerContainer.read(appStateProvider).state.authData!.login,
              providerContainer.read(appStateProvider).state.authData!.secret,
            );
        providerContainer.read(appStateProvider).launchgApp(AppMode.standalone);
      } else if (runClient) {
        providerContainer.read(appStateProvider).launchgApp(AppMode.client);
      } else if (runServer) {
        providerContainer.read(appStateProvider).launchgApp(AppMode.server);
      }
    } catch (e, callStack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Invalid arguments: $e\n$callStack'));
    }
  }

  bool checkRequredParameters(ArgResults argResults, List<String> arguments) {
    final missingArgs = <String>[];
    for (var arg in arguments) {
      if (!argResults.wasParsed(arg)) //
        missingArgs.add(arg);
    }

    if (missingArgs.isNotEmpty) {
      final meessage = 'Missing required arguments: ${missingArgs.join(', ')}. Use --help for a list of supported command.';
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, meessage));
      closeApp();
    }

    return missingArgs.isEmpty;
  }

  void closeApp() {
    const message = 'Closing the application..';
    print(message);
    exit(0);
  }

  ArgParser _buildParser() {
    final parser = ArgParser();

    parser.addFlag(
      _aClient,
      abbr: 'c',
      help: 'set to launch a client',
    );
    parser.addFlag(
      _aServer,
      abbr: 's',
      help: 'set to launch a server',
    );
    parser.addOption(
      _aProjectPath,
      aliases: ['pp'],
      help: 'project path (for a server)',
    );
    parser.addOption(
      _aAuthPath,
      aliases: ['ap'],
      help: 'auth list path (for a server)',
    );
    parser.addOption(
      _aHistoryTag,
      aliases: ['ht'],
      help: 'file name to save commands history to',
    );
    parser.addOption(
      _aHistoryPath,
      aliases: ['hp'],
      help: 'folder path to save history files to',
    );
    parser.addOption(
      _aOutputPath,
      aliases: ['op'],
      help: 'generators output path (for a server)',
    );
    parser.addOption(
      _aLogin,
      aliases: ['l'],
      help: 'client login',
    );
    parser.addOption(
      _aSecret,
      aliases: ['sc'],
      help: 'client secret (should be specified in a registration)',
    );
    parser.addOption(
      _aPassword,
      aliases: ['pw'],
      help: 'client password',
    );
    parser.addOption(
      _aHost,
      aliases: ['hs'],
      help: 'server address',
    );
    parser.addOption(
      _aPort,
      aliases: ['p'],
      help: 'server port',
    );
    parser.addFlag(
      _aHelp,
      abbr: 'h',
      help: 'show a list of arguments',
    );
    parser.addOption(
      _aRegisterLogin,
      aliases: ['rl'],
      help: 'login of a new user to register',
    );
    parser.addOption(
      _aRegisterSecret,
      aliases: ['rs'],
      help: 'secret of a new user to register',
    );
    parser.addOption(
      _aUnregisterLogin,
      aliases: ['ul'],
      help: 'login of the user to delete',
    );
    parser.addFlag(
      _aQuit,
      abbr: 'q',
      help: 'quit after executing commands',
    );

    return parser;
  }
}
