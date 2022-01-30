import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/db_network/auth_list_entry.dart';
import 'package:gceditor/model/db_network/authentification_data.dart';
import 'package:gceditor/model/db_network/login_state_data.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/app_state.dart';
import 'package:gceditor/model/state/log_state.dart';

final authListStateProvider = ChangeNotifierProvider((_) => AuthListStateNotifier(AuthListState()));

class AuthListState {
  String? filePath;
  LoginListData? loginListData;
}

class AuthListStateNotifier extends ChangeNotifier {
  AuthListState state;

  AuthListStateNotifier(this.state);

  void setPath(String path) {
    state.filePath = path;
    notifyListeners();
  }

  Future readFromFile() async {
    if (state.filePath == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'Auth list file is not specified'));
    }
    if (state.loginListData != null) //
      return;

    final file = File(state.filePath!);
    final fileExists = await file.exists();
    if (!fileExists) {
      state.loginListData = LoginListData();
      return;
    }

    final fileContent = await file.readAsString();
    state.loginListData = fileContent.isEmpty ? null : LoginListData.fromJson(jsonDecode(fileContent));
    notifyListeners();
  }

  Future saveToFile() async {
    if (state.loginListData == null || state.filePath == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'The state is invalid'));
      return;
    }

    final file = File(state.filePath!);
    final fileExists = await file.exists();
    if (!fileExists) {
      await file.create(recursive: true);
    }

    await file.writeAsString(Config.fileJsonOptions.convert(state.loginListData!.toJson()));
  }

  Future<bool> isValidAuth(AuthentificationData? data) async {
    if (data == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Null auth data'));
      return false;
    }

    await readFromFile();
    final existingUser = state.loginListData!.users[data.login];

    if (existingUser == null) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'Unregistered user "${data.login}" login denied'));
      return false;
    }

    final passwordHash = sha512.convert(utf8.encode(data.login + existingUser.salt + data.password)).toString();

    if (existingUser.passwordHash == null) {
      if (data.password.length < Config.minPasswordLength) {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'User "${data.login}" login denied: password is too short.'));
        return false;
      }

      existingUser.passwordHash = passwordHash;
      await saveToFile();

      final appState = providerContainer.read(appStateProvider).state;
      if (appState.authData?.login != existingUser.login) {
        providerContainer.read(logStateProvider).addMessage(
              LogEntry(
                existingUser.login == Config.defaultNewLogin ? LogLevel.log : LogLevel.warning,
                'User "${data.login}" first time logged. Login information has been saved.',
              ),
            );
      }

      return true;
    } else {
      if (passwordHash != existingUser.passwordHash) {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'User "${data.login}" login denied: password is incorrect'));
        return false;
      }

      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.log, 'User "${data.login}" has been connected'));
      return true;
    }
  }

  Future registerNewLogin(String login, String secret) async {
    if (login.length < Config.minLoginLength || secret.length < Config.minSecretLength) {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.error, 'The specified credentials are too weak'));
      return;
    }

    await readFromFile();
    state.loginListData!.users.remove(login);
    state.loginListData!.users[login] = AuthListEntry.newUser(login: login, secret: secret);
    await saveToFile();
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'User "$login" has been registered'));
  }

  Future resetPasswordOrRegister(String login, String secret) async {
    await readFromFile();
    if (state.loginListData!.users.containsKey(login)) {
      state.loginListData!.users[login]!.passwordHash = null;
      await saveToFile();
      providerContainer.read(logStateProvider).addMessage(
            LogEntry(LogLevel.log, 'The password was reset for User "$login"'),
          );
    } else {
      await registerNewLogin(login, secret);
    }
  }

  Future removeLogin(String login) async {
    await readFromFile();

    final existingUser = state.loginListData!.users[login];
    if (existingUser != null) {
      state.loginListData!.users.remove(login);
      await saveToFile();
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'User "$login" has been removed'));
    } else {
      providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'User "$login" does not exist'));
    }
  }
}
