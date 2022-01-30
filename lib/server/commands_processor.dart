import 'dart:typed_data';

import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/utils/utils.dart';

import 'net_commands.dart';

typedef SendCommand = void Function(Uint8List rawCommand);
typedef HandleErrorMessage = void Function(CommandErrorResponse error);

class CommandsProcessor {
  final String id;
  final SendCommand doSendCommand;
  final HandleErrorMessage doHandleError;

  int idCounter = 0;
  int? lastIncomingId;
  final responseByRequest = <BaseCommand, BaseCommand?>{};

  CommandsProcessor(this.id, this.doSendCommand, this.doHandleError);

  Future<T?> sendCommand<T extends BaseCommand>(BaseCommand command, [BaseCommand? inResponseTo]) async {
    if (inResponseTo != null) {
      providerContainer.read(logStateProvider).addMessage(
          LogEntry(LogLevel.debug, 'CommandsProcessor:$id: sending command "${command.runtimeType}" in response to "${inResponseTo.runtimeType}"'));
      (command as BaseResponse).sourceCommand = inResponseTo;
      command.id = inResponseTo.id;
    } else {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.debug, 'CommandsProcessor:$id: sending command "${command.runtimeType}"'));
      command.id = idCounter;
      idCounter++;
    }

    responseByRequest[command] = null;

    doSendCommand(Uint8List.fromList(CommandFactory.write(command)));

    await Utils.waitWhile(() => responseByRequest[command] == null, Config.asyncPollInterval);
    final result = responseByRequest[command] is T ? responseByRequest[command] as T? : null;

    responseByRequest.remove(command);

    return result;
  }

  bool handleResponse(BaseCommand response) {
    if (response is! BaseResponse) return false;

    final id = response.id;

    for (final source in responseByRequest.keys) {
      if (source.id == id) {
        responseByRequest[source] = response;
        (response as BaseResponse).sourceCommand = source;
        break;
      }
    }

    if (response is CommandErrorResponse) {
      doHandleError(response);
    }

    return true;
  }

  Future<bool> waitForIncomingCommandOrder(BaseCommand command) async {
    if (lastIncomingId != null && command.id <= (lastIncomingId ?? 0)) {
      return false;
    }

    lastIncomingId ??= command.id - 1;

    await Utils.waitWhile(() => lastIncomingId! < command.id - 1);
    lastIncomingId = lastIncomingId! + 1;
    return true;
  }
}
