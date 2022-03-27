import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/menubar_state.dart';
import 'package:gceditor/model/state/server_state.dart';
import 'package:gceditor/model/state/service/client_data_selection_state.dart';
import 'package:gceditor/server/net_commands.dart';
import 'package:gceditor/utils/event_notifier.dart';

DbModel get clientModel => providerContainer.read(clientStateProvider).state.model;
BaseDbCmd? get lastClientCommand => providerContainer.read(clientStateProvider).state.lastCommand;

final clientRestoredProvider = ChangeNotifierProvider((_) => EventNotifier());
final columnSizeChangedProvider = ChangeNotifierProvider((_) => EventNotifier());

final clientStateProvider = ChangeNotifierProvider((_) => ClientStateNotifier(ClientState()));

class ClientState extends ServerState {}

class ClientStateNotifier extends ServerStateNotifier {
  ClientStateNotifier(ClientState state) : super(state);

  @override
  void setModel(DbModel model) {
    super.setModel(model);
    providerContainer.read(clientRestoredProvider).dispatchEvent();
  }

  @override
  void incrementVersion() {
    super.incrementVersion();
    providerContainer.read(clientRestoredProvider).dispatchEvent();
  }

  @override
  void onCommandExecuted(BaseDbCmd command) {
    if (providerContainer.read(clientOwnCommandsStateProvider).state.latestDirectCommandId != command.id) //
      state.version++;

    switch (command.$type) {
      case null:
      case DbCmdType.unknown:
      case DbCmdType.addNewTable:
      case DbCmdType.addNewClass:
      case DbCmdType.addEnumValue:
      case DbCmdType.addClassField:
      case DbCmdType.addClassInterface:
      case DbCmdType.deleteClass:
      case DbCmdType.deleteEnumValue:
      case DbCmdType.deleteClassField:
      case DbCmdType.deleteClassInterface:
      case DbCmdType.editMetaEntityId:
      case DbCmdType.editMetaEntityDescription:
      case DbCmdType.editEnumValue:
      case DbCmdType.editClassField:
      case DbCmdType.editClassInterface:
      case DbCmdType.editClass:
      case DbCmdType.editTable:
      case DbCmdType.editTableRowId:
      case DbCmdType.editTableCellValue:
      case DbCmdType.editProjectSettings:
      case DbCmdType.reorderMetaEntity:
      case DbCmdType.reorderEnum:
      case DbCmdType.reorderClassField:
      case DbCmdType.reorderClassInterface:
      case DbCmdType.resizeColumn:
      case DbCmdType.resizeDictionaryKeyToValue:
      case DbCmdType.fillColumn:
        break;

      case DbCmdType.addDataRow:
      case DbCmdType.deleteDataRow:
      case DbCmdType.reorderDataRow:
      case DbCmdType.deleteTable:
      case DbCmdType.copypaste:
        providerContainer.read(clientDataSelectionStateProvider).clear(true);
        break;
    }

    super.onCommandExecuted(command);
  }
}

final clientOwnCommandsStateProvider = ChangeNotifierProvider((ref) {
  final notifier = ClientOwnCommandsStateNotifier(ClientOwnCommandsState());

  DbModel? oldModel;

  ref.read(clientStateProvider).addListener(() {
    final newModel = ref.read(clientStateProvider).state.model;
    if (oldModel != newModel) {
      notifier.clear();
      oldModel = newModel;
    }
  });

  return notifier;
});

class ClientOwnCommandsState {
  final _ownCommands = <BaseDbCmd>[];
  final _ownUndoCommands = <BaseDbCmd>[];
  int nextCommandIndex = 0;
  String? latestDirectCommandId;

  BaseDbCmd? get nextUndoCommand {
    return nextCommandIndex > 0 ? _ownCommands[nextCommandIndex - 1] : null;
  }

  BaseDbCmd? get nextRedoCommand {
    return _ownCommands.isNotEmpty && nextCommandIndex < _ownCommands.length ? _ownCommands[nextCommandIndex] : null;
  }
}

class ClientOwnCommandsStateNotifier extends ChangeNotifier {
  final ClientOwnCommandsState state;
  ClientOwnCommandsStateNotifier(this.state);

  bool addCommand(BaseDbCmd cmd, {VoidCallback? onSuccess}) {
    final clientModel = providerContainer.read(clientStateProvider).state.model;
    final validationResult = cmd.validate(clientModel);
    if (!validationResult.success) {
      providerContainer
          .read(logStateProvider)
          .addMessage(LogEntry(LogLevel.error, 'Can not add command "${describeEnum(cmd.$type!)}". Error: "${validationResult.error}"'));

      providerContainer.read(clientStateProvider).incrementVersion();
      return false;
    }

    state._ownCommands.length = state.nextCommandIndex;
    state._ownUndoCommands.length = state.nextCommandIndex;

    state._ownCommands.add(cmd);
    state._ownUndoCommands.add(cmd.createUndoCmd(clientModel));

    final countAboveBufferSize = state._ownCommands.length - Config.dbCmdBufferLength;
    if (countAboveBufferSize > 0) {
      state._ownCommands.removeRange(0, countAboveBufferSize);
      state._ownUndoCommands.removeRange(0, countAboveBufferSize);
      state.nextCommandIndex -= countAboveBufferSize;
    }

    _proceedNextCommand(true).then(
      (result) async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (result is CommandOkResponse) {
          onSuccess?.call();
        }
      },
    );

    state.latestDirectCommandId = cmd.id;
    notifyListeners();

    providerContainer.read(menubarStateProvider).refresh();
    return true;
  }

  void undo() {
    if (state.nextUndoCommand == null) //
      return;

    _proceedNextCommand(false);
  }

  void redo() {
    if (state.nextRedoCommand == null) //
      return;

    _proceedNextCommand(true);
  }

  Future<BaseCommand> _proceedNextCommand(bool redo) async {
    BaseDbCmd commandToExecute;
    if (redo) {
      commandToExecute = state._ownCommands[state.nextCommandIndex++];
    } else {
      commandToExecute = state._ownUndoCommands[--state.nextCommandIndex];
    }

    state.latestDirectCommandId = null;

    final result = await providerContainer.read(appStateProvider).state.clientApp!.sendDbCommand(commandToExecute);
    notifyListeners();
    return result;
  }

  void clear() {
    state._ownCommands.clear();
    state._ownUndoCommands.clear();
    state.nextCommandIndex = 0;
    notifyListeners();
  }
}
