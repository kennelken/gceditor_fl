import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  ///
  ///
  /// In en, this message translates to:
  /// **'Run all'**
  String get runGenerators;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  ///
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  ///
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  ///
  ///
  /// In en, this message translates to:
  /// **'Try to copy from clipboard'**
  String get fromClipboard;

  ///
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  ///
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  ///
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  ///
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  ///
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  ///
  ///
  /// In en, this message translates to:
  /// **'defined in:'**
  String get fieldOwnerClass;

  ///
  ///
  /// In en, this message translates to:
  /// **'#{name} history'**
  String historyDialogTitle(String name);

  ///
  ///
  /// In en, this message translates to:
  /// **'Selected items: {selected}/{total}'**
  String historySelectedItems(int selected, int total);

  ///
  ///
  /// In en, this message translates to:
  /// **'current'**
  String get historyItemCurrent;

  ///
  ///
  /// In en, this message translates to:
  /// **'gen{index}: {type}'**
  String gitItemGenerator(String type, int index);

  ///
  ///
  /// In en, this message translates to:
  /// **'his{index}: #{name}'**
  String gitItemHistory(String name, int index);

  ///
  ///
  /// In en, this message translates to:
  /// **'project'**
  String get gitItemProject;

  ///
  ///
  /// In en, this message translates to:
  /// **'auth list'**
  String get gitItemAuthList;

  ///
  ///
  /// In en, this message translates to:
  /// **'output'**
  String get gitItemOutput;

  ///
  ///
  /// In en, this message translates to:
  /// **'Pinned items'**
  String get pinnedPanelTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'class declaration'**
  String get findTypeClassDeclaration;

  ///
  ///
  /// In en, this message translates to:
  /// **'table declaration'**
  String get findTypeTableDeclaration;

  ///
  ///
  /// In en, this message translates to:
  /// **'enum declaration'**
  String get findTypeEnumDeclaration;

  ///
  ///
  /// In en, this message translates to:
  /// **'column declaration'**
  String get findTypeFieldDeclaration;

  ///
  ///
  /// In en, this message translates to:
  /// **'parent class'**
  String get classParentClassReference;

  ///
  ///
  /// In en, this message translates to:
  /// **'implements'**
  String get classParentInterfaceClassReference;

  ///
  ///
  /// In en, this message translates to:
  /// **'uses class'**
  String get tableParentClassReference;

  ///
  ///
  /// In en, this message translates to:
  /// **'reference value'**
  String get referenceValue;

  ///
  ///
  /// In en, this message translates to:
  /// **'reference'**
  String get findTypeReference;

  ///
  ///
  /// In en, this message translates to:
  /// **'value'**
  String get findTypeValue;

  ///
  ///
  /// In en, this message translates to:
  /// **'item declaration'**
  String get findTypeDeclaration;

  ///
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get labelFind;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enter a search query'**
  String get hintFind;

  ///
  ///
  /// In en, this message translates to:
  /// **'namespace'**
  String get namespaceLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'prefix'**
  String get prefixLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'prefix interface'**
  String get prefixInterfaceLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'postfix'**
  String get postfixLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'indent'**
  String get indentationLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'file name'**
  String get generatorFileNameLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'extension'**
  String get generatorFileExtensionLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'timezone'**
  String get projectSettingsTimezoneTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'save delay (seconds)'**
  String get projectSettingsSaveDelay;

  ///
  ///
  /// In en, this message translates to:
  /// **'generators'**
  String get projectSettingsGeneratorsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Project Settings'**
  String get projectSettingsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcutsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Repeating dictionary key'**
  String get problemRepeatingDictionaryKey;

  ///
  ///
  /// In en, this message translates to:
  /// **'Repeating set value'**
  String get problemRepeatingSetValue;

  ///
  ///
  /// In en, this message translates to:
  /// **'Non unique value'**
  String get problemValueIsNotUnique;

  ///
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get problemInvalidValue;

  ///
  ///
  /// In en, this message translates to:
  /// **'Invalid reference'**
  String get problemInvalidReference;

  ///
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get problemsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'size: {size}'**
  String cellListSize(int size);

  ///
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no matches} =1{1 match} other{{count} matches}}'**
  String findResultsCount(int count);

  ///
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items selected} =1{Selected 1 item} other{Selected {count} items}}'**
  String dataSelectionCount(int count);

  ///
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items copied} =1{Copied 1 item from {table}} other{Copied {count} items from \'\'{table}\'\'}}'**
  String dataCopiedCount(int count, String table);

  ///
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items copied} =1{Copied 1 item from Clipboard} other{Copied {count} items from Clipboard}}'**
  String dataCopiedExternalCount(int count);

  ///
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items copied} =1{Cut 1 item from {table}} other{Cut {count} items from \'\'{table}\'\'}}'**
  String dataCutCount(int count, String table);

  ///
  ///
  /// In en, this message translates to:
  /// **'Nothing is found'**
  String get emptyDropDownList;

  ///
  ///
  /// In en, this message translates to:
  /// **'no class'**
  String get noClass;

  ///
  ///
  /// In en, this message translates to:
  /// **'No table is selected'**
  String get tableIsNotSelected;

  ///
  ///
  /// In en, this message translates to:
  /// **'Class is not specified'**
  String get tableHasNoClass;

  ///
  ///
  /// In en, this message translates to:
  /// **'{columns} x {rows}'**
  String selectedTableSize(int columns, int rows);

  ///
  ///
  /// In en, this message translates to:
  /// **'{name} : {className}'**
  String selectedTableTitle(String name, String className);

  ///
  ///
  /// In en, this message translates to:
  /// **'No table selected'**
  String get noTableSelected;

  ///
  ///
  /// In en, this message translates to:
  /// **'format:\n    int, float, string, text - <String>\n    reference - <String> of entity id\n    list, set - [\"String\", ..., \"String\"]\n    dictionary - [[\"String\",\"String\"], ..., [\"String\",\"String\"]]\n    date - <yyyy.mm.dd hh:mm:ss>\n    duration - <nnnd nnnh nnnm nnns>'**
  String get defaultFieldInfo;

  ///
  ///
  /// In en, this message translates to:
  /// **'default value'**
  String get defaultValueTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'class'**
  String get classReference;

  ///
  ///
  /// In en, this message translates to:
  /// **'type'**
  String get fieldType;

  ///
  ///
  /// In en, this message translates to:
  /// **'key type'**
  String get fieldKeyType;

  ///
  ///
  /// In en, this message translates to:
  /// **'value type'**
  String get fieldValueType;

  ///
  ///
  /// In en, this message translates to:
  /// **'class'**
  String get fieldReferenceClass;

  ///
  ///
  /// In en, this message translates to:
  /// **'enum'**
  String get fieldReferenceEnum;

  ///
  ///
  /// In en, this message translates to:
  /// **'export column'**
  String get exportFieldTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'If enabled, the column values will be exported when generators are run'**
  String get exportFieldTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'generate items references'**
  String get exportElementsList;

  ///
  ///
  /// In en, this message translates to:
  /// **'row height multiplier'**
  String get rowHeightMultiplier;

  ///
  ///
  /// In en, this message translates to:
  /// **'unique values'**
  String get isUniqueValueTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'If enabled, duplicating value of this column will be warned about'**
  String get isUniqueValueTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get dropDownSearchHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'<null>'**
  String get nullValue;

  ///
  ///
  /// In en, this message translates to:
  /// **'parent class'**
  String get parentClass;

  ///
  ///
  /// In en, this message translates to:
  /// **'parent interfaces'**
  String get parentInterfaces;

  ///
  ///
  /// In en, this message translates to:
  /// **'class type'**
  String get classType;

  ///
  ///
  /// In en, this message translates to:
  /// **'New Element'**
  String get addNewItem;

  ///
  ///
  /// In en, this message translates to:
  /// **'values'**
  String get enumsListTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'columns'**
  String get classFieldsListTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'interfaces'**
  String get interfacesListTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Reinitialize Model'**
  String get requestModelFromServer;

  ///
  ///
  /// In en, this message translates to:
  /// **'Please hold the \'\'delete\'\' button to delete the element'**
  String get longTapToDelete;

  ///
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get contextMenuFolder;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enum'**
  String get contextMenuEnum;

  ///
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get contextMenuClass;

  ///
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get contextMenuTable;

  ///
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get menubarFile;

  ///
  ///
  /// In en, this message translates to:
  /// **'Run Generators'**
  String get menubarRunGenerators;

  ///
  ///
  /// In en, this message translates to:
  /// **'Project Settings'**
  String get menubarProjectSettings;

  ///
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menubarEdit;

  ///
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get menubarUndo;

  ///
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get menubarRedo;

  ///
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get menubarSearch;

  ///
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get menubarFind;

  ///
  ///
  /// In en, this message translates to:
  /// **'Next Problem'**
  String get menubarNextProblem;

  ///
  ///
  /// In en, this message translates to:
  /// **'Close Selected Item'**
  String get closeSelectedItem;

  ///
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menubarView;

  ///
  ///
  /// In en, this message translates to:
  /// **'Toggle Actions'**
  String get expandedViewMenu;

  ///
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get menubarConsole;

  ///
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get menubarZoomIn;

  ///
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get menubarZoomOut;

  ///
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get menubarShowShortcuts;

  ///
  ///
  /// In en, this message translates to:
  /// **'id'**
  String get classMetaPropertyId;

  ///
  ///
  /// In en, this message translates to:
  /// **'description'**
  String get classMetaPropertyDescription;

  ///
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get statusOnline;

  ///
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get statusOffline;

  ///
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no clients} =1{1 client} other{{count} clients}}'**
  String connectedClientsCount(num count);

  ///
  ///
  /// In en, this message translates to:
  /// **'client: {status}'**
  String clientStatus(Object status);

  ///
  ///
  /// In en, this message translates to:
  /// **'server: {status}'**
  String serverStatus(Object status);

  ///
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get typeClassField;

  ///
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get typeTableGroup;

  ///
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get typeTableEntry;

  ///
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get typeClassGroup;

  ///
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get typeClass;

  ///
  ///
  /// In en, this message translates to:
  /// **'Enum'**
  String get typeEnum;

  /// title in the file explorer
  ///
  /// In en, this message translates to:
  /// **'Nothing is selected'**
  String get propertyNothingSelected;

  /// title in the file explorer
  ///
  /// In en, this message translates to:
  /// **'Select project file'**
  String get selectProjectFile;

  /// title in the file explorer
  ///
  /// In en, this message translates to:
  /// **'Select project directory'**
  String get selectProjectDirectory;

  ///
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientModeButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'Standalone'**
  String get standaloneModeButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverModeButton;

  ///
  ///
  /// In en, this message translates to:
  /// **'ip address'**
  String get ipAddressInputTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'server port'**
  String get portInputTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not start the server: \'\'{error}\'\''**
  String errorStartServer(Object error);

  ///
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server: \'\'{error}\'\''**
  String errorStartClient(Object error);

  ///
  ///
  /// In en, this message translates to:
  /// **'new login'**
  String get newLoginLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'new secret'**
  String get newSecretLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get buttonUnregisterLogin;

  ///
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get buttonRegisterNewLogin;

  ///
  ///
  /// In en, this message translates to:
  /// **'your login'**
  String get clientLoginHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'login'**
  String get clientLoginLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'a secret received from an administrator'**
  String get clientSecretHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'secret'**
  String get clientSecretLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'your password'**
  String get clientPasswordHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get clientPasswordLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'remember password'**
  String get rememberPassword;

  ///
  ///
  /// In en, this message translates to:
  /// **'tag'**
  String get historyTagLabel;

  ///
  ///
  /// In en, this message translates to:
  /// **'file to store commands history'**
  String get historyTagHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'any login to register'**
  String get newLoginHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'any secret to register'**
  String get newSecretHint;

  ///
  ///
  /// In en, this message translates to:
  /// **'Project path:'**
  String get projectPathTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Auth list:'**
  String get authListPathTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'project path'**
  String get projectPath;

  ///
  ///
  /// In en, this message translates to:
  /// **'output path'**
  String get outputPath;

  ///
  ///
  /// In en, this message translates to:
  /// **'auth list path'**
  String get authListPath;

  ///
  ///
  /// In en, this message translates to:
  /// **'history folder path'**
  String get historyPath;

  ///
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classesTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get gitTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{empty} =1{1 item} other{{count} items}}'**
  String historyItemsCount(num count);

  ///
  ///
  /// In en, this message translates to:
  /// **'{selected}/{total}'**
  String gitSelected(int selected, int total);

  ///
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tablesTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get buttonApply;

  ///
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  ///
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get buttonExecute;

  ///
  ///
  /// In en, this message translates to:
  /// **'Fill the column with a value'**
  String get buttonFillColumnTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcutTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create a new table'**
  String get createNewTableTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create a new class'**
  String get createNewClassTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Show the next problem'**
  String get nextProblemTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Refresh git items'**
  String get gitRefreshTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'git: Commit selected items'**
  String get gitCommitTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'git: Push changes'**
  String get gitPushTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'git: Pull'**
  String get gitPullTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Refresh the history'**
  String get historyRefreshTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create a new table item'**
  String get crateNewTableItem;

  ///
  ///
  /// In en, this message translates to:
  /// **'Remove the table item'**
  String get deleteTableItemTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Find references'**
  String get findReferencesTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Pin the item'**
  String get pinItemTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Unpin the item'**
  String get unpinItemTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Create a new generator'**
  String get createNewGeneratorTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get findTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Toggle setting: id only'**
  String get findIdTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Toggle setting: case-sensitive'**
  String get findCaseSensitiveTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Toggle setting: full word only'**
  String get findFullWordsTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Toggle setting: regex mode'**
  String get findRegexTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get findCloseTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closePinnedItemsTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete the table'**
  String get deleteTableTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete the class'**
  String get deleteClassTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete the folder'**
  String get deleteGroupTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete the enum'**
  String get deleteEnumTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Delete the column'**
  String get deleteFieldTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Whether the code generators should generate a class containg all items of the table'**
  String get generateTableItemsTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Whether the code generators should generate a class containg all items of the tables utilizing this class'**
  String get generateClassItemsTooltip;

  ///
  ///
  /// In en, this message translates to:
  /// **'Fill column \'\'{column}\'\' with'**
  String fillColumnLabel(String column);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
