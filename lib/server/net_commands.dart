import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/db_network/authentication_data.dart';
import 'package:gceditor/model/db_network/command_error_response_payload.dart';
import 'package:gceditor/model/db_network/command_request_git_payload.dart';
import 'package:gceditor/model/db_network/command_request_git_response_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_execute_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_execute_response_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_payload.dart';
import 'package:gceditor/model/db_network/command_request_history_response_payload.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/log_state.dart';

enum CommandType {
  unknown,
  ok,
  error,
  requestAuthentication,
  requestDbModel,
  requestDbModelResponse,
  requestDbModelModification,
  requestRunGenerators,
  dbModelModificationBroadcast,
  requestGit,
  requestGitResponse,
  requestHistory,
  requestHistoryResponse,
  requestHistoryExecute,
  requestHistoryExecuteResponse,
}

class CommandFactory {
  static ParseCommandResult<T> fromStream<T extends BaseCommand>(Uint8List data) {
    const offset = kIsWeb ? 1 : 0;

    final type = CommandType.values[data[0 + offset]];
    final id = data[1 + offset];
    final payload = Uint8List.fromList(_decode(data.sublist(2 + offset)));

    BaseCommand? command;
    switch (type) {
      case CommandType.unknown:
        throw Exception("Unexpected command of type '$type'");

      case CommandType.ok:
        command = CommandOkResponse();
        break;

      case CommandType.error:
        command = CommandErrorResponse();
        break;

      case CommandType.requestAuthentication:
        command = CommandRequestAuthentication();
        break;

      case CommandType.requestDbModel:
        command = CommandRequestDbModel();
        break;

      case CommandType.requestDbModelResponse:
        command = CommandRequestDbModelResponse();
        break;

      case CommandType.requestDbModelModification:
        command = CommandRequestDbModelModification();
        break;

      case CommandType.requestRunGenerators:
        command = CommandRequestRunGenerators();
        break;

      case CommandType.dbModelModificationBroadcast:
        command = CommandDbModelModificationBroadcast();
        break;

      case CommandType.requestGit:
        command = CommandRequestGit();
        break;

      case CommandType.requestGitResponse:
        command = CommandRequestGitResponse();
        break;

      case CommandType.requestHistory:
        command = CommandRequestHistory();
        break;

      case CommandType.requestHistoryResponse:
        command = CommandRequestHistoryResponse();
        break;

      case CommandType.requestHistoryExecute:
        command = CommandRequestHistoryExecute();
        break;

      case CommandType.requestHistoryExecuteResponse:
        command = CommandRequestHistoryExecuteResponse();
        break;
    }

    command.id = id;
    final error = (command as IBaseCommand).parse(payload);

    return ParseCommandResult<T>(command as T, error);
  }

  static List<int> write(BaseCommand command) {
    final result = <int>[];
    result.add((command as IBaseCommand).type.index);
    result.add(command.id);
    try {
      result.addAll(_encode((command as IBaseCommand).getPayload()));
    } catch (error, callstack) {
      providerContainer.read(logStateProvider).addMessage(
          LogEntry(LogLevel.error, 'Could not encode command "${(command as IBaseCommand).type}". Error: "$error"\nclasstack: $callstack'));
      providerContainer.read(appStateProvider).needRestart();
      rethrow;
    }
    return result;
  }
}

List<int> _encode(List<int> src) {
  return src;
}

List<int> _decode(List<int> src) {
  return src;
}

class BaseCommand {
  late int id;
}

abstract class IBaseCommand {
  CommandType get type;

  String? parse(Uint8List data);
  List<int> getPayload();
}

abstract class BaseResponse {
  BaseCommand? sourceCommand;
}

class CommandOkResponse extends BaseCommand implements IBaseCommand, BaseResponse {
  @override
  BaseCommand? sourceCommand;

  CommandOkResponse({this.sourceCommand});

  @override
  CommandType get type => CommandType.ok;

  @override
  String? parse(Uint8List data) {
    return null;
  }

  @override
  List<int> getPayload() {
    return List.empty();
  }
}

class CommandErrorResponse extends BaseCommand implements IBaseCommand, BaseResponse {
  late String? message;
  DbModel? model;

  @override
  BaseCommand? sourceCommand;

  CommandErrorResponse({this.sourceCommand, this.message, this.model});

  @override
  CommandType get type => CommandType.error;

  @override
  String? parse(Uint8List data) {
    final jsonText = utf8.decode(data);
    final payload = CommandErrorResponsePayload.fromJson(jsonDecode(jsonText));
    message = payload.message;
    model = payload.model;
    return null;
  }

  @override
  List<int> getPayload() {
    final payload = CommandErrorResponsePayload.values(message, model);
    final jsonText = Config.streamJsonOptions.convert(payload.toJson());
    return utf8.encode(jsonText);
  }
}

class CommandRequestAuthentication extends BaseCommand implements IBaseCommand {
  late AuthenticationData? authData;

  CommandRequestAuthentication();

  @override
  CommandType get type => CommandType.requestAuthentication;

  @override
  String? parse(Uint8List data) {
    try {
      final jsonText = utf8.decode(data);
      authData = AuthenticationData.fromJson(jsonDecode(jsonText));
    } catch (error, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Error: $error\nclasstack: $callstack'));
      return error.toString();
    }
    return null;
  }

  @override
  List<int> getPayload() {
    final jsonText = authData != null ? Config.streamJsonOptions.convert(authData!.toJson()) : '';
    return utf8.encode(jsonText);
  }
}

class CommandRequestDbModel extends BaseCommand implements IBaseCommand {
  CommandRequestDbModel();

  @override
  CommandType get type => CommandType.requestDbModel;

  @override
  String? parse(Uint8List data) {
    return null;
  }

  @override
  List<int> getPayload() {
    return <int>[];
  }
}

class CommandRequestDbModelResponse extends BaseCommandResponse<DbModel> {
  @override
  CommandType get type => CommandType.requestDbModelResponse;

  @override
  DbModel fromJson(jsonObject) {
    return DbModel.fromJson(jsonObject);
  }

  @override
  dynamic toJson(DbModel object) {
    return object.toJson();
  }
}

class CommandRequestDbModelModification extends BaseCommandRequest<BaseDbCmd> {
  @override
  CommandType get type => CommandType.requestDbModelModification;

  @override
  BaseDbCmd fromJson(jsonObject) {
    return BaseDbCmd.decode(jsonObject);
  }

  @override
  dynamic toJson(BaseDbCmd object) {
    return BaseDbCmd.encode(object);
  }
}

class CommandRequestRunGenerators extends BaseCommand implements IBaseCommand {
  @override
  CommandType get type => CommandType.requestRunGenerators;

  @override
  String? parse(Uint8List data) {
    return null;
  }

  @override
  List<int> getPayload() {
    return <int>[];
  }
}

class CommandDbModelModificationBroadcast extends BaseCommandRequest<BaseDbCmd> {
  @override
  CommandType get type => CommandType.dbModelModificationBroadcast;

  @override
  BaseDbCmd fromJson(jsonObject) {
    return BaseDbCmd.decode(jsonObject);
  }

  @override
  dynamic toJson(BaseDbCmd object) {
    return BaseDbCmd.encode(object);
  }
}

abstract class BaseCommandRequest<T> extends BaseCommand implements IBaseCommand {
  T? payload;

  BaseCommandRequest({
    this.payload,
  });

  @override
  String? parse(Uint8List data) {
    try {
      final jsonText = utf8.decode(data);
      payload = fromJson(jsonDecode(jsonText));
    } catch (error, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Error: $error\nclasstack: $callstack'));
      return error.toString();
    }
    return null;
  }

  @override
  List<int> getPayload() {
    final jsonText = Config.streamJsonOptions.convert(payload == null ? '' : toJson(payload!));
    return utf8.encode(jsonText);
  }

  T fromJson(dynamic jsonObject);
  dynamic toJson(T object);
}

abstract class BaseCommandResponse<T> extends BaseCommand implements IBaseCommand, BaseResponse {
  T? payload;
  @override
  BaseCommand? sourceCommand;

  BaseCommandResponse({
    this.sourceCommand,
    this.payload,
  });

  @override
  String? parse(Uint8List data) {
    try {
      final jsonText = utf8.decode(data);
      payload = fromJson(jsonDecode(jsonText));
    } catch (error, callstack) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Error: $error\nclasstack: $callstack'));
      return error.toString();
    }
    return null;
  }

  @override
  List<int> getPayload() {
    final jsonText = Config.streamJsonOptions.convert(payload == null ? '' : toJson(payload!));
    return utf8.encode(jsonText);
  }

  T fromJson(dynamic jsonObject);
  dynamic toJson(T object);
}

class CommandRequestGit extends BaseCommandRequest<CommandRequestGitPayload> {
  @override
  CommandType get type => CommandType.requestGit;

  @override
  CommandRequestGitPayload fromJson(jsonObject) {
    return CommandRequestGitPayload.fromJson(jsonObject);
  }

  @override
  toJson(CommandRequestGitPayload object) {
    return object.toJson();
  }
}

class CommandRequestGitResponse extends BaseCommandResponse<CommandRequestGitResponsePayload> {
  @override
  CommandType get type => CommandType.requestGitResponse;

  @override
  CommandRequestGitResponsePayload fromJson(jsonObject) {
    return CommandRequestGitResponsePayload.fromJson(jsonObject);
  }

  @override
  dynamic toJson(CommandRequestGitResponsePayload object) {
    return object.toJson();
  }
}

class CommandRequestHistory extends BaseCommandRequest<CommandRequestHistoryPayload> {
  @override
  CommandType get type => CommandType.requestHistory;

  @override
  CommandRequestHistoryPayload fromJson(jsonObject) {
    return CommandRequestHistoryPayload.fromJson(jsonObject);
  }

  @override
  dynamic toJson(CommandRequestHistoryPayload object) {
    return object.toJson();
  }
}

class CommandRequestHistoryResponse extends BaseCommandResponse<CommandRequestHistoryResponsePayload> {
  @override
  CommandType get type => CommandType.requestHistoryResponse;

  @override
  CommandRequestHistoryResponsePayload fromJson(jsonObject) {
    return CommandRequestHistoryResponsePayload.fromJson(jsonObject);
  }

  @override
  dynamic toJson(CommandRequestHistoryResponsePayload object) {
    return object.toJson();
  }
}

class CommandRequestHistoryExecute extends BaseCommandRequest<CommandRequestHistoryExecutePayload> {
  @override
  CommandType get type => CommandType.requestHistoryExecute;

  @override
  CommandRequestHistoryExecutePayload fromJson(jsonObject) {
    return CommandRequestHistoryExecutePayload.fromJson(jsonObject);
  }

  @override
  dynamic toJson(CommandRequestHistoryExecutePayload object) {
    return object.toJson();
  }
}

class CommandRequestHistoryExecuteResponse extends BaseCommandResponse<CommandRequestHistoryExecuteResponsePayload> {
  @override
  CommandType get type => CommandType.requestHistoryExecuteResponse;

  @override
  CommandRequestHistoryExecuteResponsePayload fromJson(jsonObject) {
    return CommandRequestHistoryExecuteResponsePayload.fromJson(jsonObject);
  }

  @override
  dynamic toJson(CommandRequestHistoryExecuteResponsePayload object) {
    return object.toJson();
  }
}

class ParseCommandResult<T extends BaseCommand?> {
  T command;
  String? error;

  ParseCommandResult(this.command, this.error);
}

class PartialAuthenticationData {
  String? login;
  String? secret;
  String? password;

  PartialAuthenticationData.values({
    this.login,
    this.secret,
    this.password,
  });
}
