import 'dart:typed_data';

import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_network/authentication_data.dart';
import 'package:gceditor/model/db_network/command_request_git_payload.dart';
import 'package:gceditor/model/db_network/command_request_git_response_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_execute_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_execute_response_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_response_payload.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/waiting_state.dart';
import 'package:gceditor/server/commands_processor.dart';
import 'package:gceditor/server/net_commands.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';

class ClientApp {
  late final String ipAddress;
  late final int port;
  late final AuthenticationData authData;

  io.Socket? _socket;
  CommandsProcessor? _commandsProcessor;
  bool _isAuthorized = false;

  ClientApp({
    required this.ipAddress,
    required this.port,
    required this.authData,
  });

  Future<String?> init() async {
    if (_socket != null) throw Exception('socket connection is already established');
    dispatchClientStatusChange(false);

    try {
      _socket = io.io(
        'http://$ipAddress:$port',
        OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
      );

      bool? isConnected;
      dynamic connectionError;
      _socket!.onConnect((_) {
        dispatchClientStatusChange(true);
        isConnected = true;
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ClientApp: connection established'));
      });
      _socket!.onConnectError((error) {
        dispatchClientStatusChange(false);
        isConnected = false;
        connectionError = error;
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ClientApp: could not establish connection: $error'));
        _closeSocket(true);
      });
      _socket!.onConnectTimeout((error) {
        dispatchClientStatusChange(false);
        isConnected = false;
        connectionError = error;
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ClientApp: timeout establishing connection: $error'));
        _closeSocket(true);
      });

      _socket!.connect();

      await Utils.waitWhile(() => isConnected == null, Config.asyncPollInterval);

      _commandsProcessor = CommandsProcessor(
        'Client',
        _sendCommand,
        _handleResponseError,
      );

      if (isConnected != true) {
        return connectionError?.toString();
      }

      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ClientApp: Connected to: $ipAddress:$port'));
      _socket!.on(_EventType.msg, _handleMessage);
      _socket!.on(_EventType.error, _handleError);
      _socket!.on(_EventType.disconnect, _handleDisconnect);

      return _requestDbModel(false);
    } catch (error, callstack) {
      _commandsProcessor = null;
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.error, 'ClientApp: Could not connect to: $ipAddress:$port.\nclasstack: $callstack'));
      return error.toString();
    }
  }

  void _handleError(dynamic error) {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'ClientApp: server error $error'));
    _closeSocket(true);
  }

  void _handleDisconnect(dynamic _) {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'ClientApp: Server disconnected.'));
    _closeSocket(true);
  }

  void _closeSocket(bool needRestart) {
    if (needRestart) {
      providerContainer.read(appStateProvider).needRestart();
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.critical, 'ClientApp: restart is required.'));
    }

    dispatchClientStatusChange(false);
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.close();
      _socket!.destroy();
      _socket!.dispose();
      _socket = null;
    }
  }

  void _handleMessage(dynamic rawMessage) {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ClientApp: received message'));

    final commandResult = CommandFactory.fromStream(rawMessage);
    if (commandResult.error != null) {
      providerContainer.read(logStateProvider).addMessage(
          LogEntry(LogLevel.critical, 'ClientApp: Error parsing command "${commandResult.command.runtimeType}" "${commandResult.error}"'));
      _requestDbModel(true);
    }

    final command = commandResult.command;
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ClientApp: parsed command: "$command"'));

    if (_commandsProcessor!.handleResponse(command)) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ClientApp: incoming message was treated as a response'));
      return;
    }

    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'ClientApp: incoming message was treated as a request'));
    _handleServerRequest(command);
  }

  void _handleServerRequest(BaseCommand command) async {
    final waitingResult = await _commandsProcessor!.waitForIncomingCommandOrder(command);
    if (!waitingResult) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.critical, 'ClientApp: could not handle incoming request'));
      _closeSocket(true);
    }

    if (command is CommandDbModelModificationBroadcast) {
      final cmd = command.payload;
      final cmdExecutionResult = cmd!.execute(providerContainer.read(clientStateProvider).state.model);

      if (cmdExecutionResult.success) {
        providerContainer.read(clientStateProvider).onCommandExecuted(cmd);
        providerContainer.read(pinnedItemsStateProvider).removeDeletedItemsIfRequired(clientModel);

        providerContainer
            .read(logStateProvider)
            .addMessage(LogEntry(LogLevel.debug, 'ClientApp: successfully executed db model modification command "${cmd.$type}:${cmd.id}"'));
        _commandsProcessor!.sendCommand(CommandOkResponse(), command);
      } else {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug,
            'ClientApp: failed to execute db model modification command "${cmd.$type}:${cmd.id}". error: ${cmdExecutionResult.error}'));
        _commandsProcessor!.sendCommand(CommandErrorResponse(sourceCommand: command, message: cmdExecutionResult.error));

        _closeSocket(true);
      }
    } else {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.critical, 'ClientApp: received unexpected command ${command.runtimeType}'));
      _closeSocket(true);
    }
  }

  Future<String?> _requestDbModel(bool warning) async {
    if (!_isAuthorized) {
      final authResponse = await _commandsProcessor!.sendCommand<CommandOkResponse>(CommandRequestAuthentication()..authData = authData);
      if (authResponse != null) {
        _isAuthorized = true;
      } else {
        return 'Invalid credentials';
      }
    }

    final response = await _commandsProcessor!.sendCommand<CommandRequestDbModelResponse>(CommandRequestDbModel());

    if (response?.payload != null) {
      _applyServerModel(response!.payload!, warning: warning);
    } else {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.critical, 'ClientApp: error getting the model'));
      _closeSocket(true);
    }

    return null;
  }

  void _sendCommand(Uint8List rawCommand) {
    _socket!.compress(true).emitWithBinary(_EventType.msg, rawCommand);
  }

  void _handleResponseError(CommandErrorResponse error) {
    final severity = error.model != null ? LogLevel.error : LogLevel.critical;

    providerContainer.read(logStateProvider).addMessage(
        LogEntry(severity, 'ClientApp: received error from server: "${error.message}" for request "${error.sourceCommand?.runtimeType}"'));

    if (error.model != null) {
      _applyServerModel(error.model!, warning: true);
    } else if (error.sourceCommand is CommandRequestGit) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Please refresh the git state to continue working with git'));
    } else {
      _closeSocket(error.sourceCommand is! CommandRequestAuthentication || providerContainer.read(appStateProvider).state.appMode != AppMode.client);
    }
  }

  void dispatchClientStatusChange(bool value) {
    providerContainer.read(appStateProvider).onClientStatusChanged(value);
  }

  Future<BaseCommand> sendDbCommand(BaseDbCmd cmd) async {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'client sends command "${cmd.$type}"'));
    final response = await _commandsProcessor!.sendCommand(CommandRequestDbModelModification()..payload = cmd);
    return response!;
  }

  Future requestRunGenerators() async {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ClientApp: send run generators request'));
    providerContainer.read(waitingStateProvider).toggleWaiting(this, true);
    final response = await _commandsProcessor!.sendCommand<BaseCommand>(CommandRequestRunGenerators());
    if (response is CommandOkResponse) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Generators job finished without errors'));
    } else if (response is CommandErrorResponse) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Generators job caused error "${response.message}"'));
    } else {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Server responded with unexpected response "$response"'));
    }
    providerContainer.read(waitingStateProvider).toggleWaiting(this, false);
  }

  Future<CommandRequestGitResponsePayload?> requestGit(CommandRequestGitPayload payload) async {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ClientApp: send git request'));
    final response = await _commandsProcessor!.sendCommand<CommandRequestGitResponse>(CommandRequestGit()..payload = payload);
    return response?.payload;
  }

  Future<CommandRequestHistoryResponsePayload?> requestHistory(CommandRequestHistoryPayload payload) async {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ClientApp: send history request'));
    final response = await _commandsProcessor!.sendCommand<CommandRequestHistoryResponse>(CommandRequestHistory()..payload = payload);
    return response?.payload;
  }

  Future<CommandRequestHistoryExecuteResponsePayload?> requestHistoryExecute(CommandRequestHistoryExecutePayload payload) async {
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'ClientApp: send history execute request'));
    final response = await _commandsProcessor!.sendCommand<CommandRequestHistoryExecuteResponse>(CommandRequestHistoryExecute()..payload = payload);
    return response?.payload;
  }

  void _applyServerModel(DbModel model, {bool warning = false}) {
    providerContainer
        .read(logStateProvider)
        .addMessage(LogEntry(warning ? LogLevel.warning : LogLevel.log, 'Initialized client state by server state'));
    providerContainer.read(clientStateProvider).setModel(model);
  }

  void reInitModel() {
    _requestDbModel(true);
  }
}

class _EventType {
  static const String disconnect = 'disconnect';
  static const String msg = 'msg';
  static const String error = 'error';
}
