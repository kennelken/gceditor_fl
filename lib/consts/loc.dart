import 'dart:ui';
import 'package:gceditor/l10n/app_localizations.dart';
import 'package:gceditor/main.dart';

// guide here https://phrase.com/blog/posts/flutter-localization/

class Loc {
  static AppLocalizations get get {
    try {
      return AppLocalizations.of(localizationContext)!;
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }
}
