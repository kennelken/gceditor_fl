import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/app_local_storage.dart';

final settingsStateProvider = ChangeNotifierProvider((_) => SettingsStateNotifier(SettingsState()));

class SettingsState {
  double propertiesWidth = AppLocalStorage.instance.propertiesWidth ?? Config.defaultColumnWidth;
  double classesWidth = AppLocalStorage.instance.classesWidth ?? Config.defaultColumnWidth;
  double findHeight = AppLocalStorage.instance.findHeight ?? Config.defaultFindHeight;
  double pinnedPanelHeight = AppLocalStorage.instance.pinnedPanelHeight ?? Config.defaultPinnedPanelHeight;

  double tablesHeight = AppLocalStorage.instance.tablesHeight ?? Config.defaultTablesHeightRatio;
  double classesHeight = AppLocalStorage.instance.classesHeight ?? Config.defaultClassesHeightRatio;
  double problemsHeight = AppLocalStorage.instance.problemsHeight ?? Config.defaultProblemsHeightRatio;
  double gitHeight = AppLocalStorage.instance.gitHeight ?? Config.defaultGitHeightRatio;
  double historyHeight = AppLocalStorage.instance.historyHeight ?? Config.defaultHistoryHeightRatio;

  bool tablesExpanded = AppLocalStorage.instance.tablesExpanded ?? Config.defaultTablesExpanded;
  bool classesExpanded = AppLocalStorage.instance.classesExpanded ?? Config.defaultClassesExpanded;
  bool problemsExpanded = AppLocalStorage.instance.problemsExpanded ?? Config.defaultProblemsExpanded;
  bool gitExpanded = AppLocalStorage.instance.gitExpanded ?? Config.defaultGitExpanded;
  bool historyExpanded = AppLocalStorage.instance.historyExpanded ?? Config.defaultHistoryExpanded;

  SettingsState();
}

class SettingsStateNotifier extends ChangeNotifier {
  late SettingsState state;
  SettingsStateNotifier(this.state);

  void setClassesWidth(double value) {
    AppLocalStorage.instance.classesWidth = value;
    state.classesWidth = value;
    notifyListeners();
  }

  void setTablesHeight(double value) {
    AppLocalStorage.instance.tablesHeight = value;
    state.tablesHeight = value;
    notifyListeners();
  }

  void setClassesHeight(double value) {
    AppLocalStorage.instance.classesHeight = value;
    state.classesHeight = value;
    notifyListeners();
  }

  void setProblemsHeight(double value) {
    AppLocalStorage.instance.problemsHeight = value;
    state.problemsHeight = value;
    notifyListeners();
  }

  void setGitHeight(double value) {
    AppLocalStorage.instance.gitHeight = value;
    state.gitHeight = value;
    notifyListeners();
  }

  void setPanelHeightByIndex(int index, double heigth) {
    switch (index) {
      case 0:
        setTablesHeight(heigth);
        break;
      case 1:
        setClassesHeight(heigth);
        break;
      case 2:
        setProblemsHeight(heigth);
        break;
      case 3:
        setGitHeight(heigth);
        break;
    }
  }

  void setPropertiesWidth(double value) {
    AppLocalStorage.instance.propertiesWidth = value;
    state.propertiesWidth = value;
    notifyListeners();
  }

  void setFindHeight(double value) {
    AppLocalStorage.instance.findHeight = value;
    state.findHeight = value;
    notifyListeners();
  }

  void setPinnedPanelHeight(double value) {
    AppLocalStorage.instance.pinnedPanelHeight = value;
    state.pinnedPanelHeight = value;
    notifyListeners();
  }

  void toggleTablesExpanded({bool? value}) {
    final newValue = value ?? !state.tablesExpanded;
    AppLocalStorage.instance.tablesExpanded = newValue;
    state.tablesExpanded = newValue;
    notifyListeners();
  }

  void toggleClassesExpanded({bool? value}) {
    final newValue = value ?? !state.classesExpanded;
    AppLocalStorage.instance.classesExpanded = newValue;
    state.classesExpanded = newValue;
    notifyListeners();
  }

  void toggleProblemsExpanded({bool? value}) {
    final newValue = value ?? !state.problemsExpanded;
    AppLocalStorage.instance.problemsExpanded = newValue;
    state.problemsExpanded = newValue;
    notifyListeners();
  }

  void toggleGitExpanded({bool? value}) {
    final newValue = value ?? !state.gitExpanded;
    AppLocalStorage.instance.gitExpanded = newValue;
    state.gitExpanded = newValue;
    notifyListeners();
  }

  void toggleHistoryExpanded({bool? value}) {
    final newValue = value ?? !state.historyExpanded;
    AppLocalStorage.instance.historyExpanded = newValue;
    state.historyExpanded = newValue;
    notifyListeners();
  }
}
