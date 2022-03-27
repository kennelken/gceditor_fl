import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_cmd/db_cmd_result.dart';
import 'package:gceditor/model/db_network/command_request_git_response_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_execute_response_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_response_payload.dart';
import 'package:gceditor/model/db_network/get_item_data.dart';
import 'package:gceditor/model/db_network/history_item_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/auth_list_state.dart';
import 'package:gceditor/model/state/db_model_factory.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/server_git_state.dart';
import 'package:gceditor/model/state/server_history_state.dart';
import 'package:gceditor/model/state/server_state.dart';
import 'package:gceditor/server/generators/generators_job.dart';
import 'package:gceditor/server/net_commands.dart';
import 'package:socket_io/socket_io.dart';

import 'commands_processor.dart';

class ServerApp {
  final int port;
  final File projectFile;

  Server? server;
  final List<Socket> _clients = <Socket>[];
  final Map<Socket, String> _authorizedClients = <Socket, String>{};
  final _commandProcessorByClient = <Socket, CommandsProcessor>{};
  bool _waitingForSave = false;

  ServerApp({
    required this.port,
    required this.projectFile,
  });

  Future<String?> init() async {
    server = Server();

    dispatchServerStatusChange(false);
    _clients.clear();

    try {
      final errorOpeningProjectFile = await _buildDbModel();
      if (errorOpeningProjectFile != null) {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Error opening config file: "$errorOpeningProjectFile"'));
        return errorOpeningProjectFile;
      }

      await server!.listen(port);

      dispatchServerStatusChange(true);
    } catch (error, callstack) {
      providerContainer.read(logStateProvider).addMessage(
          LogEntry(LogLevel.error, 'ServerApp: Could not start server at: "${Config.defaultIp}:$port" because "$error"\nclasstack: $callstack'));
      return error.toString();
    }

    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ServerApp: Started server at port:${server!.port}'));
    server!.on(_EventType.connection, _handleConnection);

    return null;
  }

  void _handleConnection(dynamic result) {
    final client = result as Socket;
    //server.onconnection(result);

    _clients.add(client);
    dispatchServerStatusChange(true);
    _commandProcessorByClient[client] = CommandsProcessor(
      'Client',
      (c) => _sendCommand(client, c),
      (error) => _handleResponseError(error),
    );

    client.on(_EventType.msg, (data) => _handleMessage(client, data));
    client.on(_EventType.error, (data) => _handleError(client, data));
    client.on(_EventType.disconnect, (data) => _handleDisconnect(client, data));
  }

  void _handleMessage(Socket client, dynamic data) {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ServerApp: received message'));

    final commandResult = CommandFactory.fromStream(data);
    if (commandResult.error != null) {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.error, 'ServerApp: Error parsing command "${commandResult.command.runtimeType}" "${commandResult.error}"'));

      _commandProcessorByClient[client]!.sendCommand(
        CommandErrorResponse(
            sourceCommand: commandResult.command, message: commandResult.error, model: providerContainer.read(serverStateProvider).state.model),
        commandResult.command,
      );
    }

    final command = commandResult.command;
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ServerApp: parsed command: "$command"'));

    if (_commandProcessorByClient[client]!.handleResponse(command)) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ServerApp: incoming message was treated as a response'));
      return;
    }

    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ServerApp: incoming message was treated as a request'));
    _handleClientRequest(client, command);
  }

  Future<String?> _buildDbModel() async {
    DbModel? dbModel;
    if (await projectFile.exists()) {
      final jsonText = await projectFile.readAsString();
      if (jsonText.isNotEmpty) {
        try {
          dbModel = DbModel.fromJson(jsonDecode(jsonText));
        } catch (error, callstack) {
          providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Error: $error\nclasstack: $callstack'));
          return error.toString();
        }
      }
    }

    if (dbModel == null) {
      await projectFile.create(recursive: true);

      final modelFactory = DbModelFactory();
      dbModel = modelFactory.createDefaultDbModel();

      final jsonText = Config.fileJsonOptions.convert(dbModel.toJson());
      projectFile.writeAsString(jsonText);
    }

    providerContainer.read(serverStateProvider).setModel(dbModel);
    return null;
  }

  void _handleClientRequest(Socket client, BaseCommand command) async {
    final waitingResult = await _commandProcessorByClient[client]!.waitForIncomingCommandOrder(command);
    if (!waitingResult) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ServerApp: could not handle incoming request'));
      return;
    }

    if (!_authorizedClients.containsKey(client)) {
      if (command is CommandRequestAuthentication) {
        if (command.authData == null) {
          _commandProcessorByClient[client]!.sendCommand(CommandErrorResponse(message: 'Invalid auth credentials'), command);
          providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ServerApp: Invalid auth credentials'));
        } else {
          final isValid = await providerContainer.read(authListStateProvider).isValidAuth(command.authData);
          if (isValid) {
            _authorizedClients[client] = command.authData!.login;
            _commandProcessorByClient[client]!.sendCommand(CommandOkResponse(), command);
          } else {
            _commandProcessorByClient[client]!.sendCommand(CommandErrorResponse(message: 'Invalid auth credentials'), command);
            providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ServerApp: Invalid auth credentials'));
          }
        }
      } else {
        _commandProcessorByClient[client]!.sendCommand(CommandErrorResponse(message: 'Not authorized'), command);
      }
      return;
    }

    if (command is CommandRequestDbModel) {
      _commandProcessorByClient[client]!.sendCommand(
        CommandRequestDbModelResponse()..payload = providerContainer.read(serverStateProvider).state.model,
        command,
      );
    } else if (command is CommandRequestDbModelModification) {
      final cmd = command.payload;
      _executeCommand(cmd, command, client);
    } else if (command is CommandRequestRunGenerators) {
      final results = await GeneratorsJob().start(providerContainer.read(serverStateProvider).state.model, _authorizedClients[client]!);
      var errorsMessage = '';
      var numErrors = 0;
      results.where((element) => !element.success).forEach((element) {
        numErrors++;
        errorsMessage += '\t${element.error!}\n';
      });
      if (errorsMessage.isNotEmpty) {
        errorsMessage = '$numErrors errors occured:\n' + errorsMessage;
        _commandProcessorByClient[client]!.sendCommand(
          CommandErrorResponse(sourceCommand: command, message: errorsMessage, model: providerContainer.read(serverStateProvider).state.model),
          command,
        );
      } else {
        _commandProcessorByClient[client]!.sendCommand(
          CommandOkResponse(sourceCommand: command),
          command,
        );
      }
    } else if (command is CommandRequestGit) {
      if (command.payload!.refresh == true) {
        final error = await providerContainer.read(serverGitStateProvider).refresh();
        if (error != null) {
          _commandProcessorByClient[client]!.sendCommand(
            CommandErrorResponse(
              sourceCommand: command,
              message: 'ServerApp: Failed to refresh git: $error',
            ),
            command,
          );
          return;
        }
      }
      if (command.payload!.commit == true && command.payload!.items != null) {
        final error = await providerContainer.read(serverGitStateProvider).doCommit(command.payload!.items!, _authorizedClients[client]!);
        if (error != null) {
          _commandProcessorByClient[client]!.sendCommand(
            CommandErrorResponse(
              sourceCommand: command,
              message: 'ServerApp: Failed to commit: $error',
            ),
            command,
          );
          return;
        }
      }
      if (command.payload!.push == true && command.payload!.items != null) {
        final error = await providerContainer.read(serverGitStateProvider).doPush(command.payload!.items!);
        if (error != null) {
          _commandProcessorByClient[client]!.sendCommand(
            CommandErrorResponse(
              sourceCommand: command,
              message: 'ServerApp: Failed to push: $error',
            ),
            command,
          );
          return;
        }
      }
      if (command.payload!.pull == true && command.payload!.items != null) {
        final error = await providerContainer.read(serverGitStateProvider).doPull(command.payload!.items!);
        if (error != null) {
          _commandProcessorByClient[client]!.sendCommand(
            CommandErrorResponse(
              sourceCommand: command,
              message: 'ServerApp: Failed to pull: $error',
            ),
            command,
          );
          return;
        }
      }
      _commandProcessorByClient[client]!.sendCommand(
        CommandRequestGitResponse()
          ..sourceCommand = command
          ..payload = CommandRequestGitResponsePayload.values(
            items: providerContainer
                .read(serverGitStateProvider)
                .state
                .items
                .map(
                  (e) => GitItemData.values(
                    id: e.id,
                    name: e.name,
                    branchName: e.branchName,
                    type: e.type,
                  ),
                )
                .toList(),
          ),
        command,
      );
    } else if (command is CommandRequestHistory) {
      if (command.payload!.refresh == true) {
        final error = await providerContainer.read(serverHistoryStateProvider).refresh(command.payload!.items?.toSet());
        if (error != null) {
          _commandProcessorByClient[client]!.sendCommand(
            CommandErrorResponse(
              sourceCommand: command,
              message: 'ServerApp: Failed to refresh history: $error',
            ),
            command,
          );
          return;
        }
      }

      final serverHistoryState = providerContainer.read(serverHistoryStateProvider).state;

      final payload = CommandRequestHistoryResponsePayload.values(
        items: serverHistoryState.items.toList(),
        currentTag: serverHistoryState.currentTag,
      );

      for (var i = 0; i < payload.items!.length; i++) {
        if (!(command.payload!.items?.contains(payload.items![i].id) ?? false)) {
          payload.items![i] = HistoryItemData.values(id: payload.items![i].id, items: null);
        }
      }

      _commandProcessorByClient[client]!.sendCommand(
        CommandRequestHistoryResponse()
          ..sourceCommand = command
          ..payload = payload,
        command,
      );
    } else if (command is CommandRequestHistoryExecute) {
      final results = <bool>[];
      final errors = <String>[];

      for (var i = 0; i < command.payload!.items!.length; i++) {
        final result = _executeCommand(command.payload!.items![i].command, null, client);

        final isSuccess = result?.success ?? false;
        results.add(isSuccess);
        errors.add(result?.error ?? '');

        if (!isSuccess) //
          break;
      }

      final payload = CommandRequestHistoryExecuteResponsePayload.values(
        results: results,
        errors: errors,
      );

      _commandProcessorByClient[client]!.sendCommand(
        CommandRequestHistoryExecuteResponse()
          ..sourceCommand = command
          ..payload = payload,
        command,
      );
    } else {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ServerApp: received unexpected command ${command.runtimeType}'));
    }
  }

  void _sendCommand(Socket client, Uint8List rawCommand) {
    client.emitWithBinary(_EventType.msg, rawCommand);
  }

  void _handleResponseError(CommandErrorResponse error) {
    providerContainer
        .read(logStateProvider)
        .addMessage(LogEntry(LogLevel.error, 'ServerApp: received error from client: "$error" for request "${error.sourceCommand.runtimeType}"'));
  }

  void _handleError(Socket client, dynamic data) {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ServerApp: client error "$data"'));
    //client.close();
    _clients.remove(client);
    dispatchServerStatusChange(true);
  }

  void _handleDisconnect(Socket client, dynamic data) {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'ServerApp: client disconnected: "$data"'));
    //client.close();
    _clients.remove(client);
    dispatchServerStatusChange(true);
  }

  void dispatchServerStatusChange(bool value) {
    providerContainer.read(appStateProvider).onServerStatusChanged(value, _clients.length);
  }

  void _broadcast(BaseCommand command) {
    for (var client in _clients) {
      _commandProcessorByClient[client]!.sendCommand(command);
    }
  }

  void _scheduleSave() async {
    if (_waitingForSave) //
      return;

    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ServerApp: scheduling model saving'));

    _waitingForSave = true;
    await Future.delayed(
      Duration(
        microseconds: (providerContainer.read(serverStateProvider).state.model.settings.saveDelay * 1000 * 1000).round(),
      ),
    );
    if (!_waitingForSave) //
      return;

    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ServerApp: encoding the model for save'));
    _waitingForSave = false;

    final dbmodel = providerContainer.read(serverStateProvider).state.model;
    final jsonText = Config.fileJsonOptions.convert(dbmodel.toJson());

    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ServerApp: saving the model'));
    try {
      await projectFile.writeAsString(jsonText);
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ServerApp: the model has been saved successfully'));
    } catch (error, callstack) {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.critical, 'ServerApp: error occured during saving the model. Error: "$error"\nclasstack: $callstack'));
    }
  }

  DbCmdResult? _executeCommand(BaseDbCmd? cmd, BaseCommand? commandToSendResponseTo, Socket requestor) {
    final cmdExecutionResult = cmd?.execute(providerContainer.read(serverStateProvider).state.model);

    if (cmdExecutionResult?.success ?? false) {
      providerContainer.read(serverStateProvider).onCommandExecuted(cmd!);
      providerContainer.read(serverHistoryStateProvider).putIntoHistory(cmd, _authorizedClients[requestor]!);

      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.debug, 'ServerApp: succesfully executed db model modification command "${cmd.$type}:${cmd.id}"'));

      if (commandToSendResponseTo != null) //
        _commandProcessorByClient[requestor]!.sendCommand(CommandOkResponse(), commandToSendResponseTo);
      _scheduleSave();

      _broadcast(CommandDbModelModificationBroadcast()..payload = cmd);
    } else {
      String? error;
      if (cmd == null) {
        error = 'cmd is null';
        providerContainer
            .read(logStateProvider)
            .addMessage(LogEntry(LogLevel.error, 'ServerApp: failed to execute db model modification command "null". error: $error'));
      } else {
        error = cmdExecutionResult?.error;
        providerContainer //
            .read(logStateProvider)
            .addMessage(
                LogEntry(LogLevel.error, 'ServerApp: failed to execute db model modification command "${cmd.$type}:${cmd.id}". error: $error'));
      }

      if (commandToSendResponseTo != null) //
        _commandProcessorByClient[requestor]!.sendCommand(
          CommandErrorResponse(
              sourceCommand: commandToSendResponseTo, message: error, model: providerContainer.read(serverStateProvider).state.model),
          commandToSendResponseTo,
        );
    }

    return cmdExecutionResult;
  }
}

class _EventType {
  static const String connection = 'connection';
  static const String disconnect = 'disconnect';
  static const String msg = 'msg';
  static const String error = 'error';
}
