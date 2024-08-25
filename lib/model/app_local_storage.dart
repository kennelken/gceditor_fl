import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';

class AppLocalStorage {
  static const storageName = 'gceditor_main';

  LocalStorage? _storage;
  bool _ready = false;
  final _mutex = Mutex();
  static AppLocalStorage? _instance;

  // ignore: prefer_constructors_over_static_methods
  static AppLocalStorage get instance {
    _instance ??= AppLocalStorage();
    return _instance!;
  }

  Future initStorage() async {
    var documentsPath = '';
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();
      documentsPath = directory.path;
    }

    await initLocalStorage();

    _storage = localStorage;
    _ready = true;

    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'LocalStorage is ready at $documentsPath'));
  }

  bool get isReadySync => _ready;

  String? get ipAddress {
    return _readProperty<String>('ipAddress');
  }

  set ipAddress(String? value) {
    saveProperty('ipAddress', value);
  }

  int? get port {
    return _readProperty<int>('port');
  }

  set port(int? value) {
    saveProperty('port', value);
  }

  String? get projectPath {
    return _readProperty<String>('projectPath');
  }

  set projectPath(String? value) {
    saveProperty('projectPath', value);
  }

  String? get outputPath {
    return _readProperty<String>('outputPath');
  }

  set outputPath(String? value) {
    saveProperty('outputPath', value);
  }

  String? get authListPath {
    return _readProperty<String>('authListPath');
  }

  set authListPath(String? value) {
    saveProperty('authListPath', value);
  }

  String? get historyPath {
    return _readProperty<String>('historyPath');
  }

  set historyPath(String? value) {
    saveProperty('historyPath', value);
  }

  String? get historyTag {
    return _readProperty<String>('historyTag');
  }

  set historyTag(String? value) {
    saveProperty('historyTag', value);
  }

  String? get clientLogin {
    return _readProperty<String>('clientLogin');
  }

  set clientLogin(String? value) {
    saveProperty('clientLogin', value);
  }

  String? get clientSecret {
    return _readProperty<String>('clientSecret');
  }

  set clientSecret(String? value) {
    saveProperty('clientSecret', value);
  }

  String? get clientPassword {
    return _readProperty<String>('clientPassword');
  }

  set clientPassword(String? value) {
    saveProperty('clientPassword', value);
  }

  bool? get rememberClientPassword {
    return _readProperty<bool>('rememberClientPassword');
  }

  set rememberClientPassword(bool? value) {
    saveProperty('rememberClientPassword', value);
  }

  String? get newLogin {
    return _readProperty<String>('newLogin');
  }

  set newLogin(String? value) {
    saveProperty('newLogin', value);
  }

  String? get newSecret {
    return _readProperty<String>('newSecret');
  }

  set newSecret(String? value) {
    saveProperty('newSecret', value);
  }

  double? get classesWidth {
    return _readProperty<double>('classesWidth');
  }

  set classesWidth(double? value) {
    saveProperty('classesWidth', value);
  }

  double? get tablesHeight {
    return _readProperty<double>('tablesHeight');
  }

  set tablesHeight(double? value) {
    saveProperty('tablesHeight', value);
  }

  double? get classesHeight {
    return _readProperty<double>('classesHeight');
  }

  set classesHeight(double? value) {
    saveProperty('classesHeight', value);
  }

  double? get problemsHeight {
    return _readProperty<double>('problemsHeight');
  }

  set problemsHeight(double? value) {
    saveProperty('problemsHeight', value);
  }

  double? get gitHeight {
    return _readProperty<double>('gitHeight');
  }

  set gitHeight(double? value) {
    saveProperty('gitHeight', value);
  }

  double? get historyHeight {
    return _readProperty<double>('historyHeight');
  }

  set historyHeight(double? value) {
    saveProperty('historyHeight', value);
  }

  bool? get tablesExpanded {
    return _readProperty<bool>('tablesExpanded');
  }

  set tablesExpanded(bool? value) {
    saveProperty('tablesExpanded', value);
  }

  bool? get classesExpanded {
    return _readProperty<bool>('classesExpanded');
  }

  set classesExpanded(bool? value) {
    saveProperty('classesExpanded', value);
  }

  bool? get problemsExpanded {
    return _readProperty<bool>('problemsExpanded');
  }

  set problemsExpanded(bool? value) {
    saveProperty('problemsExpanded', value);
  }

  bool? get gitExpanded {
    return _readProperty<bool>('gitExpanded');
  }

  set gitExpanded(bool? value) {
    saveProperty('gitExpanded', value);
  }

  bool? get historyExpanded {
    return _readProperty<bool>('historyExpanded');
  }

  set historyExpanded(bool? value) {
    saveProperty('historyExpanded', value);
  }

  double? get propertiesWidth {
    return _readProperty<double>('propertiesWidth');
  }

  set propertiesWidth(double? value) {
    saveProperty('propertiesWidth', value);
  }

  double? get findHeight {
    return _readProperty<double>('findHeight');
  }

  set findHeight(double? value) {
    saveProperty('findHeight', value);
  }

  double? get pinnedPanelHeight {
    return _readProperty<double>('pinnedPanelHeight');
  }

  set pinnedPanelHeight(double? value) {
    saveProperty('pinnedPanelHeight', value);
  }

  bool? get expandedMode {
    return _readProperty<bool>('expandedMode');
  }

  set expandedMode(bool? value) {
    saveProperty('expandedMode', value);
  }

  double? get globalScale {
    return _readProperty<double>('globalScale');
  }

  set globalScale(double? value) {
    saveProperty('globalScale', value);
  }

  T? _readProperty<T>(String key) {
    final result = _storage?.getItem(key);
    if (result == null || result == 'null' || result.isEmpty) return null;

    if (T == String) {
      return result as T;
    }
    if (T == double) {
      return double.parse(result) as T;
    }
    if (T == bool) {
      return (result == 'true') as T;
    }
    if (T == int) {
      return int.parse(result) as T;
    }
    return null;
  }

  Rect? get windowRect {
    final jsonText = _readProperty<String>('windowRect');
    if (!(jsonText?.isEmpty ?? true)) {
      try {
        final ltrb = jsonDecode(jsonText!) as List<dynamic>;
        return Rect.fromLTRB(ltrb[0], ltrb[1], ltrb[2], ltrb[3]);
      } catch (e) {
        //
      }
    }

    return null;
  }

  set windowRect(Rect? value) {
    final jsonText = value == null ? '' : jsonEncode([value.left, value.top, value.right, value.bottom]);
    saveProperty('windowRect', jsonText);
  }

  void saveProperty(String name, dynamic value) {
    _mutex.protect(() async {
      try {
        _storage!.setItem(name, value?.toString() ?? '');
      } catch (e, callstack) {
        providerContainer
            .read(logStateProvider)
            .addMessage(LogEntry(LogLevel.warning, 'Error saving property "$name": {$e}.\nclasstack: $callstack'));
      }
    });
  }
}
