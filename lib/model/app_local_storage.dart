import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/utils/utils.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppLocalStorage {
  static const storageName = 'gceditor_main';

  LocalStorage? _storage;
  bool _ready = false;
  final _mutex = Mutex();
  static AppLocalStorage? _instance;

  // ignore: prefer_constructors_over_static_methods
  static AppLocalStorage get instance {
    _instance ??= AppLocalStorage.constructor();
    return _instance!;
  }

  AppLocalStorage.constructor() {
    initStorage();
  }

  void initStorage() async {
    String? documentsPath;
    if (!kIsWeb) {
      final directory = await getApplicationDocumentsDirectory();

      documentsPath = directory.path;
      documentsPath = path.join(documentsPath, Config.appName);
      await Directory(documentsPath).create(recursive: true);
    }

    _storage = LocalStorage(
      storageName,
      documentsPath,
    );
    _ready = await _storage!.ready;
    providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.debug, 'LocalStorage is ready at $documentsPath'));
  }

  Future<bool> isReady() async {
    await Utils.waitWhile(() => _storage == null);
    return _storage!.ready;
  }

  bool get isReadySync => _ready;

  String? get ipAddress {
    return _storage?.getItem('ipAddress') as String?;
  }

  set ipAddress(String? value) {
    saveProperty('ipAddress', value);
  }

  int? get port {
    return _storage?.getItem('port') as int?;
  }

  set port(int? value) {
    saveProperty('port', value);
  }

  String? get projectPath {
    return _storage?.getItem('projectPath') as String?;
  }

  set projectPath(String? value) {
    saveProperty('projectPath', value);
  }

  String? get outputPath {
    return _storage?.getItem('outputPath') as String?;
  }

  set outputPath(String? value) {
    saveProperty('outputPath', value);
  }

  String? get authListPath {
    return _storage?.getItem('authListPath') as String?;
  }

  set authListPath(String? value) {
    saveProperty('authListPath', value);
  }

  String? get historyPath {
    return _storage?.getItem('historyPath') as String?;
  }

  set historyPath(String? value) {
    saveProperty('historyPath', value);
  }

  String? get historyTag {
    return _storage?.getItem('historyTag') as String?;
  }

  set historyTag(String? value) {
    saveProperty('historyTag', value);
  }

  String? get clientLogin {
    return _storage?.getItem('clientLogin') as String?;
  }

  set clientLogin(String? value) {
    saveProperty('clientLogin', value);
  }

  String? get clientSecret {
    return _storage?.getItem('clientSecret') as String?;
  }

  set clientSecret(String? value) {
    saveProperty('clientSecret', value);
  }

  String? get clientPassword {
    return _storage?.getItem('clientPassword') as String?;
  }

  set clientPassword(String? value) {
    saveProperty('clientPassword', value);
  }

  bool? get rememberClientPassword {
    return _storage?.getItem('rememberClientPassword') as bool?;
  }

  set rememberClientPassword(bool? value) {
    saveProperty('rememberClientPassword', value);
  }

  String? get newLogin {
    return _storage?.getItem('newLogin') as String?;
  }

  set newLogin(String? value) {
    saveProperty('newLogin', value);
  }

  String? get newSecret {
    return _storage?.getItem('newSecret') as String?;
  }

  set newSecret(String? value) {
    saveProperty('newSecret', value);
  }

  double? get classesWidth {
    return _storage?.getItem('classesWidth') as double?;
  }

  set classesWidth(double? value) {
    saveProperty('classesWidth', value);
  }

  double? get tablesHeight {
    return _storage?.getItem('tablesHeight') as double?;
  }

  set tablesHeight(double? value) {
    saveProperty('tablesHeight', value);
  }

  double? get classesHeight {
    return _storage?.getItem('classesHeight') as double?;
  }

  set classesHeight(double? value) {
    saveProperty('classesHeight', value);
  }

  double? get problemsHeight {
    return _storage?.getItem('problemsHeight') as double?;
  }

  set problemsHeight(double? value) {
    saveProperty('problemsHeight', value);
  }

  double? get gitHeight {
    return _storage?.getItem('gitHeight') as double?;
  }

  set gitHeight(double? value) {
    saveProperty('gitHeight', value);
  }

  double? get historyHeight {
    return _storage?.getItem('historyHeight') as double?;
  }

  set historyHeight(double? value) {
    saveProperty('historyHeight', value);
  }

  bool? get tablesExpanded {
    return _storage?.getItem('tablesExpanded') as bool?;
  }

  set tablesExpanded(bool? value) {
    saveProperty('tablesExpanded', value);
  }

  bool? get classesExpanded {
    return _storage?.getItem('classesExpanded') as bool?;
  }

  set classesExpanded(bool? value) {
    saveProperty('classesExpanded', value);
  }

  bool? get problemsExpanded {
    return _storage?.getItem('problemsExpanded') as bool?;
  }

  set problemsExpanded(bool? value) {
    saveProperty('problemsExpanded', value);
  }

  bool? get gitExpanded {
    return _storage?.getItem('gitExpanded') as bool?;
  }

  set gitExpanded(bool? value) {
    saveProperty('gitExpanded', value);
  }

  bool? get historyExpanded {
    return _storage?.getItem('historyExpanded') as bool?;
  }

  set historyExpanded(bool? value) {
    saveProperty('historyExpanded', value);
  }

  double? get propertiesWidth {
    return _storage?.getItem('propertiesWidth') as double?;
  }

  set propertiesWidth(double? value) {
    saveProperty('propertiesWidth', value);
  }

  double? get findHeight {
    return _storage?.getItem('findHeight') as double?;
  }

  set findHeight(double? value) {
    saveProperty('findHeight', value);
  }

  double? get pinnedPanelHeight {
    return _storage?.getItem('pinnedPanelHeight') as double?;
  }

  set pinnedPanelHeight(double? value) {
    saveProperty('pinnedPanelHeight', value);
  }

  bool? get expandedMode {
    return _storage?.getItem('expandedMode') as bool?;
  }

  set expandedMode(bool? value) {
    saveProperty('expandedMode', value);
  }

  double? get globalScale {
    return _storage?.getItem('globalScale') as double?;
  }

  set globalScale(double? value) {
    saveProperty('globalScale', value);
  }

  Rect? get windowRect {
    final jsonText = _storage?.getItem('windowRect') as String?;
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
        await _storage!.setItem(name, value);
      } catch (e, callstack) {
        providerContainer
            .read(logStateProvider)
            .addMessage(LogEntry(LogLevel.warning, 'Error saving property "$name": {$e}.\nclasstack: $callstack'));
      }
    });
  }
}
