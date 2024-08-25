import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/model/db/db_model.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';

final serverStateProvider = ChangeNotifierProvider((_) => ServerStateNotifier(ServerState()));

class ServerState {
  bool isInitialized = false;
  int version = 0;
  late DbModel model;
  BaseDbCmd? lastCommand;
}

class ServerStateNotifier extends ChangeNotifier {
  final ServerState state;
  ServerStateNotifier(this.state);

  @mustCallSuper
  void setModel(DbModel model) {
    state.isInitialized = true;
    state.model = model;
    state.lastCommand = null;
    state.version++;
    notifyListeners();
  }

  void incrementVersion() {
    state.version++;
    notifyListeners();
  }

  void onCommandExecuted(BaseDbCmd command) {
    state.lastCommand = command;
    notifyListeners();
  }

  void dispatchChange() {
    notifyListeners();
  }
}
