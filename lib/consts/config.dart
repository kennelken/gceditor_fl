import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gceditor/model/state/log_state.dart';

class Config {
  static const String appName = 'gceditor';
  static const String defaultIp = '127.0.0.1';
  static const int portMin = 7223;
  static const int portMax = 7323;
  static const LogLevel loggingLevel = LogLevel.debug;
  static const int portScanningStep = 5;
  static const String projectFileExtension = 'json';
  static const String newProjectDefaultFolder = 'gceditorProject';
  static const String newProjectDefaultName = 'project.$projectFileExtension';
  static const String newAuthListDefaultName = 'authlist.$projectFileExtension';
  static const String newHistoryDefaultFolder = 'history';
  static const String newHistoryDefaultTag = 'main';
  static const String historyFileExtension = 'hf';
  static const String defaultNewLogin = 'admin';
  static const String defaultNewSecret = 'admin';
  static const String defaultPassword = 'admin';
  static const String defaultGeneratorName = 'Model';
  static const String defaultGeneratorJsonFileExtension = 'json';
  static const String defaultGeneratorJsonIndentation = '\t';
  static const String defaultGeneratorCsharpFileExtension = 'cs';
  static const String defaultGeneratorCsharpNamespace = 'Fairfun.Gceditor.Model';
  static const String defaultGeneratorCsharpPrefix = 'Model';
  static const String defaultGeneratorCsharpPrefixInterface = 'IModel';
  static const String defaultGeneratorCsharpPostfix = '';
  static const String defaultGeneratorJavaFileExtension = 'java';
  static const String defaultGeneratorJavaNamespace = 'Fairfun.Gceditor.Model';
  static const String defaultGeneratorJavaPrefix = 'Model';
  static const String defaultGeneratorJavaPrefixInterface = 'IModel';
  static const String defaultGeneratorJavaPostfix = '';
  static const int generatorMinFileNameLength = 2;
  static const int generatorMinFileExtensionLength = 1;
  static const bool defaultRememberPassword = true;
  static const int minLoginLength = 4;
  static const int minSecretLength = 4;
  static const int minPasswordLength = 4;
  static const Duration asyncPollInterval = Duration(milliseconds: 50);
  static const double defaultTablesHeightRatio = 0.4;
  static const double defaultClassesHeightRatio = 0.4;
  static const double defaultProblemsHeightRatio = 0.2;
  static const double defaultGitHeightRatio = 0.2;
  static const double defaultHistoryHeightRatio = 0.2;
  static const double minMainColumnHeightRatio = 0.1;
  static const double defaultKeysToValues = 0.5;
  static const double minKeysToValuesRatio = 0.1;
  static const bool defaultTablesExpanded = true;
  static const bool defaultClassesExpanded = true;
  static const bool defaultProblemsExpanded = false;
  static const bool defaultGitExpanded = false;
  static const bool defaultHistoryExpanded = false;
  static const double defaultGlobalScale = 0.85;
  static const double globalScaleStep = 1.1;
  static final double minGlobalScale = pow(globalScaleStep, -5).toDouble();
  static final double maxGlobalScale = pow(globalScaleStep, 9).toDouble();
  static const int dbCmdBufferLength = 50; // must be >= 1
  static const double defaultSaveDelay = 2.0;
  static const double maxSaveDelay = 60.0;

  static JsonEncoder get fileJsonOptions => const JsonEncoder.withIndent('\t');
  static JsonEncoder get streamJsonOptions => const JsonEncoder();
  static JsonEncoder get historyViewJsonOptions => const JsonEncoder();

  static double enumColumnMinWidth = 50;
  static double enumColumnDefaultWidth = 100;
  static double enumColumnMaxWidth = 300;
  static double minColumnWidth = 100;
  static double minPanelsWidth = 200;
  static double defaultPinnedPanelHeight = 250;
  static double minFindHeight = 100;
  static double maxFindHeight = 700;
  static double minPinnedPanelHeight = 100;
  static double maxPinnedPanelHeight = 700;
  static double defaultColumnWidth = 300;
  static double defaultFindHeight = 250;
  static double minRowHeightMultiplier = 0.7;
  static double maxRowHeightMultiplier = 20;
  static String newEnumValueDefaultDescription = 'New value';
  static String newEnumDescription = 'New Enum';
  static String newFolderDescription = 'New Folder';
  static String newClassDescription = 'New Class';
  static String newTableDescription = 'New Table';
  static String newFieldDescription = 'New Field';

  static final DateTime defaultDateTime = DateTime(2000);
  static const Duration pollWindowPositionPeriod = Duration(seconds: 1);
  static const int dataTableTextMaxLines = 10;
  static const int multilinePropertyMaxLines = 10;
  static const int flexRatioMultiplier = 100000;
  static const int intMinValue = -2147483648;
  static const int intMaxValue = 2147483647;
  static final int colorMinValue = const Color.fromARGB(0, 0, 0, 0).value;
  static final int colorMaxValue = const Color.fromARGB(255, 255, 255, 255).value;
  static const double floatMinValue = -3.40282347E+38;
  static const double floatMaxValue = 3.40282347E+38;

  static const minWidowSize = Size(800, 600);

  static final RegExp validCharactersForCellTypeText = RegExp(r'(.|\s|\n|\t|\r)');
  static final List<FilteringTextInputFormatter> filterCellTypeText = [FilteringTextInputFormatter.allow(validCharactersForCellTypeText)];

  static final RegExp validCharactersForCellTypeInt = RegExp(r'[\-0-9]');
  static final List<FilteringTextInputFormatter> filterCellTypeInt = [FilteringTextInputFormatter.allow(validCharactersForCellTypeInt)];

  static final RegExp validCharactersForCellTypeFloat = RegExp(r'[\-0-9\.]');
  static final List<FilteringTextInputFormatter> filterCellTypeFloat = [FilteringTextInputFormatter.allow(validCharactersForCellTypeFloat)];

  static final dateFormatRegex = RegExp(r'^(?<y>\d{4})\.(?<m>\d{2})\.(?<d>\d{2}) (?<hh>\d{2}):(?<mm>\d{2})(:(?<ss>\d{2}))?$');
  static final RegExp validCharactersForDate = RegExp(r'[ 0-9\.:]');
  static final List<FilteringTextInputFormatter> filterCellTypeDate = [FilteringTextInputFormatter.allow(validCharactersForDate)];

  static final durationFormatRegex = RegExp(r'^(?:(?<d>\d+)d)?\ ?(?:(?<h>\d+)h)?\ ?(?:(?<m>\d+)m)?\ ?(?:(?<s>\d+)s)?$');
  static final RegExp validCharactersForDuration = RegExp(r'[ 0-9dmhs]');
  static final List<FilteringTextInputFormatter> filterCellTypeDuration = [FilteringTextInputFormatter.allow(validCharactersForDuration)];

  static final validTimezoneFormat = RegExp(r'^[-+]?[0-9]{0,2}(?:\.[05]?)?$');
  static final RegExp validCharactersForTimezone = RegExp(r'[\-+0-9\.]');
  static final List<FilteringTextInputFormatter> filterTimeZone = [FilteringTextInputFormatter.allow(validCharactersForTimezone)];

  static final RegExp validIndentationForJson = RegExp(r'[ \t\r\n]');
  static final List<FilteringTextInputFormatter> filterIndentationForJson = [FilteringTextInputFormatter.allow(validIndentationForJson)];

  static final defaultIdFormat = RegExp(r'^_[a-fA-F0-9]{8}_[a-fA-F0-9]{4}_[a-fA-F0-9]{4}_[a-fA-F0-9]{4}$');
  static final idFormatRegex = RegExp(r'^[a-zA-Z_][a-zA-Z_0-9]{1,}$');
  static final RegExp validCharactersForId = RegExp(r'[a-zA-Z_0-9]');
  static final List<FilteringTextInputFormatter> filterId = [FilteringTextInputFormatter.allow(validCharactersForId)];

  static final RegExp validCharactersForNamespace = RegExp(r'[a-zA-Z_0-9\.]');
  static final List<FilteringTextInputFormatter> filterNamespace = [FilteringTextInputFormatter.allow(validCharactersForNamespace)];

  static final RegExp newLinePattern = RegExp(r'[\n\r]+');
  static const String newLineSymbol = '\n';
}

final random = Random();
