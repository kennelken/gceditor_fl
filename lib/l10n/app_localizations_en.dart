// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get runGenerators => 'Run all';

  @override
  String get delete => 'Delete';

  @override
  String get deselect => 'Deselect';

  @override
  String get copy => 'Copy';

  @override
  String get fromClipboard => 'Try to copy from clipboard';

  @override
  String get cut => 'Cut';

  @override
  String get paste => 'Paste';

  @override
  String get after => 'After';

  @override
  String get before => 'Before';

  @override
  String get replace => 'Replace';

  @override
  String get fieldOwnerClass => 'defined in:';

  @override
  String historyDialogTitle(String name) {
    return '#$name history';
  }

  @override
  String historySelectedItems(int selected, int total) {
    return 'Selected items: $selected/$total';
  }

  @override
  String get historyItemCurrent => 'current';

  @override
  String gitItemGenerator(String type, int index) {
    return 'gen$index: $type';
  }

  @override
  String gitItemHistory(String name, int index) {
    return 'his$index: #$name';
  }

  @override
  String get gitItemProject => 'project';

  @override
  String get gitItemAuthList => 'auth list';

  @override
  String get gitItemOutput => 'output';

  @override
  String get pinnedPanelTitle => 'Pinned items';

  @override
  String get findTypeClassDeclaration => 'class declaration';

  @override
  String get findTypeTableDeclaration => 'table declaration';

  @override
  String get findTypeEnumDeclaration => 'enum declaration';

  @override
  String get findTypeFieldDeclaration => 'column declaration';

  @override
  String get classParentClassReference => 'parent class';

  @override
  String get classParentInterfaceClassReference => 'implements';

  @override
  String get tableParentClassReference => 'uses class';

  @override
  String get referenceValue => 'reference value';

  @override
  String get findTypeReference => 'reference';

  @override
  String get findTypeValue => 'value';

  @override
  String get findTypeDeclaration => 'item declaration';

  @override
  String get labelFind => 'Find';

  @override
  String get hintFind => 'Enter a search query';

  @override
  String get namespaceLabel => 'namespace';

  @override
  String get prefixLabel => 'prefix';

  @override
  String get prefixInterfaceLabel => 'prefix interface';

  @override
  String get postfixLabel => 'postfix';

  @override
  String get indentationLabel => 'indent';

  @override
  String get generatorFileNameLabel => 'file name';

  @override
  String get generatorFileExtensionLabel => 'extension';

  @override
  String get projectSettingsTimezoneTitle => 'timezone';

  @override
  String get projectSettingsSaveDelay => 'save delay (seconds)';

  @override
  String get projectSettingsGeneratorsTitle => 'generators';

  @override
  String get projectSettingsTitle => 'Project Settings';

  @override
  String get keyboardShortcutsTitle => 'Keyboard shortcuts';

  @override
  String get problemRepeatingDictionaryKey => 'Repeating dictionary key';

  @override
  String get problemRepeatingSetValue => 'Repeating set value';

  @override
  String get problemValueIsNotUnique => 'Non unique value';

  @override
  String get problemInvalidValue => 'Invalid value';

  @override
  String get problemInvalidReference => 'Invalid reference';

  @override
  String get problemsTitle => 'Problems';

  @override
  String cellListSize(int size) {
    return 'size: $size';
  }

  @override
  String findResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'no matches',
    );
    return '$_temp0';
  }

  @override
  String dataSelectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Selected $count items',
      one: 'Selected 1 item',
      zero: 'No items selected',
    );
    return '$_temp0';
  }

  @override
  String dataCopiedCount(int count, String table) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count items from \'$table\'',
      one: 'Copied 1 item from $table',
      zero: 'No items copied',
    );
    return '$_temp0';
  }

  @override
  String dataCopiedExternalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count items from Clipboard',
      one: 'Copied 1 item from Clipboard',
      zero: 'No items copied',
    );
    return '$_temp0';
  }

  @override
  String dataCutCount(int count, String table) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cut $count items from \'$table\'',
      one: 'Cut 1 item from $table',
      zero: 'No items copied',
    );
    return '$_temp0';
  }

  @override
  String get emptyDropDownList => 'Nothing is found';

  @override
  String get noClass => 'no class';

  @override
  String get tableIsNotSelected => 'No table is selected';

  @override
  String get tableHasNoClass => 'Class is not specified';

  @override
  String selectedTableSize(int columns, int rows) {
    return '$columns x $rows';
  }

  @override
  String selectedTableTitle(String name, String className) {
    return '$name : $className';
  }

  @override
  String get noTableSelected => 'No table selected';

  @override
  String get defaultFieldInfo =>
      'format:\n    int, float, string, text - <String>\n    reference - <String> of entity id\n    list, set - [\"String\", ..., \"String\"]\n    dictionary - [[\"String\",\"String\"], ..., [\"String\",\"String\"]]\n    date - <yyyy.mm.dd hh:mm:ss>\n    duration - <nnnd nnnh nnnm nnns>';

  @override
  String get defaultValueTitle => 'default value';

  @override
  String get classReference => 'class';

  @override
  String get fieldType => 'type';

  @override
  String get fieldKeyType => 'key type';

  @override
  String get fieldValueType => 'value type';

  @override
  String get fieldReferenceClass => 'class';

  @override
  String get fieldReferenceEnum => 'enum';

  @override
  String get exportFieldTitle => 'export column';

  @override
  String get exportFieldTooltip =>
      'If enabled, the column values will be exported when generators are run';

  @override
  String get exportElementsList => 'generate items references';

  @override
  String get rowHeightMultiplier => 'row height multiplier';

  @override
  String get isUniqueValueTitle => 'unique values';

  @override
  String get isUniqueValueTooltip =>
      'If enabled, duplicating value of this column will be warned about';

  @override
  String get dropDownSearchHint => 'Search';

  @override
  String get nullValue => '<null>';

  @override
  String get parentClass => 'parent class';

  @override
  String get parentInterfaces => 'parent interfaces';

  @override
  String get classType => 'class type';

  @override
  String get addNewItem => 'New Element';

  @override
  String get enumsListTitle => 'values';

  @override
  String get classFieldsListTitle => 'columns';

  @override
  String get interfacesListTitle => 'interfaces';

  @override
  String get requestModelFromServer => 'Reinitialize Model';

  @override
  String get longTapToDelete =>
      'Please hold the \'delete\' button to delete the element';

  @override
  String get contextMenuFolder => 'Folder';

  @override
  String get contextMenuEnum => 'Enum';

  @override
  String get contextMenuClass => 'Class';

  @override
  String get contextMenuTable => 'Table';

  @override
  String get menubarFile => 'File';

  @override
  String get menubarRunGenerators => 'Run Generators';

  @override
  String get menubarProjectSettings => 'Project Settings';

  @override
  String get menubarEdit => 'Edit';

  @override
  String get menubarUndo => 'Undo';

  @override
  String get menubarRedo => 'Redo';

  @override
  String get menubarSearch => 'Search';

  @override
  String get menubarFind => 'Find';

  @override
  String get menubarNextProblem => 'Next Problem';

  @override
  String get closeSelectedItem => 'Close Selected Item';

  @override
  String get menubarView => 'View';

  @override
  String get expandedViewMenu => 'Toggle Actions';

  @override
  String get menubarConsole => 'Console';

  @override
  String get menubarZoomIn => 'Zoom in';

  @override
  String get menubarZoomOut => 'Zoom out';

  @override
  String get menubarShowShortcuts => 'Shortcuts';

  @override
  String get classMetaPropertyId => 'id';

  @override
  String get classMetaPropertyDescription => 'description';

  @override
  String get statusOnline => 'online';

  @override
  String get statusOffline => 'offline';

  @override
  String connectedClientsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients',
      one: '1 client',
      zero: 'no clients',
    );
    return '$_temp0';
  }

  @override
  String clientStatus(Object status) {
    return 'client: $status';
  }

  @override
  String serverStatus(Object status) {
    return 'server: $status';
  }

  @override
  String get typeClassField => 'Column';

  @override
  String get typeTableGroup => 'Group';

  @override
  String get typeTableEntry => 'Table';

  @override
  String get typeClassGroup => 'Group';

  @override
  String get typeClass => 'Class';

  @override
  String get typeEnum => 'Enum';

  @override
  String get propertyNothingSelected => 'Nothing is selected';

  @override
  String get selectProjectFile => 'Select project file';

  @override
  String get selectProjectDirectory => 'Select project directory';

  @override
  String get clientModeButton => 'Client only';

  @override
  String get standaloneModeButton => 'Standalone';

  @override
  String get serverModeButton => 'Server only';

  @override
  String get ipAddressInputTitle => 'ip address';

  @override
  String get portInputTitle => 'server port';

  @override
  String errorStartServer(Object error) {
    return 'Could not start the server: \'$error\'';
  }

  @override
  String errorStartClient(Object error) {
    return 'Could not connect to the server: \'$error\'';
  }

  @override
  String get newLoginLabel => 'new login';

  @override
  String get newSecretLabel => 'new secret';

  @override
  String get buttonUnregisterLogin => 'Remove';

  @override
  String get buttonRegisterNewLogin => 'Register';

  @override
  String get clientLoginHint => 'your login';

  @override
  String get clientLoginLabel => 'login';

  @override
  String get clientSecretHint => 'a secret received from an administrator';

  @override
  String get clientSecretLabel => 'secret';

  @override
  String get clientPasswordHint => 'your password';

  @override
  String get clientPasswordLabel => 'password';

  @override
  String get rememberPassword => 'remember password';

  @override
  String get historyTagLabel => 'history tag';

  @override
  String get historyTagHint => 'file to store commands history';

  @override
  String get newLoginHint => 'any login to register';

  @override
  String get newSecretHint => 'any secret to register';

  @override
  String get projectPathTitle => 'Project path:';

  @override
  String get authListPathTitle => 'Auth list:';

  @override
  String get projectPath => 'project path';

  @override
  String get outputPath => 'output path';

  @override
  String get authListPath => 'auth list path';

  @override
  String get historyPath => 'history folder path';

  @override
  String get classesTitle => 'Classes';

  @override
  String get gitTitle => 'Git';

  @override
  String get historyTitle => 'History';

  @override
  String historyItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'empty',
    );
    return '$_temp0';
  }

  @override
  String gitSelected(int selected, int total) {
    return '$selected/$total';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tablesTitle => 'Tables';

  @override
  String get buttonApply => 'Apply';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonExecute => 'Execute';

  @override
  String get buttonFillColumnTooltip => 'Fill the column with a value';

  @override
  String get keyboardShortcutTooltip => 'Keyboard shortcuts';

  @override
  String get createNewTableTooltip => 'Create a new table';

  @override
  String get createNewClassTooltip => 'Create a new class';

  @override
  String get nextProblemTooltip => 'Show the next problem';

  @override
  String get gitRefreshTooltip => 'Refresh git items';

  @override
  String get gitCommitTooltip => 'git: Commit selected items';

  @override
  String get gitPushTooltip => 'git: Push changes';

  @override
  String get gitPullTooltip => 'git: Pull';

  @override
  String get historyRefreshTooltip => 'Refresh the history';

  @override
  String get crateNewTableItem => 'Create a new table item';

  @override
  String get deleteTableItemTooltip => 'Remove the table item';

  @override
  String get findReferencesTooltip => 'Find references';

  @override
  String get pinItemTooltip => 'Pin the item';

  @override
  String get unpinItemTooltip => 'Unpin the item';

  @override
  String get createNewGeneratorTooltip => 'Create a new generator';

  @override
  String get findTooltip => 'Search';

  @override
  String get findIdTooltip => 'Toggle setting: id only';

  @override
  String get findCaseSensitiveTooltip => 'Toggle setting: case-sensitive';

  @override
  String get findFullWordsTooltip => 'Toggle setting: full word only';

  @override
  String get findRegexTooltip => 'Toggle setting: regex mode';

  @override
  String get findCloseTooltip => 'Close';

  @override
  String get closePinnedItemsTooltip => 'Close';

  @override
  String get deleteTableTooltip => 'Delete the table';

  @override
  String get deleteClassTooltip => 'Delete the class';

  @override
  String get deleteGroupTooltip => 'Delete the folder';

  @override
  String get deleteEnumTooltip => 'Delete the enum';

  @override
  String get deleteFieldTooltip => 'Delete the column';

  @override
  String get closeTooltip => 'Close';

  @override
  String get generateTableItemsTooltip =>
      'Whether the code generators should generate a class containg all items of the table';

  @override
  String get generateClassItemsTooltip =>
      'Whether the code generators should generate a class containg all items of the tables utilizing this class';

  @override
  String fillColumnLabel(String column) {
    return 'Fill column \'$column\' with';
  }
}
