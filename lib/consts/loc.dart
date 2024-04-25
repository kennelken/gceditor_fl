import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gceditor/main.dart';

// guide here https://phrase.com/blog/posts/flutter-localization/

class Loc {
  static AppLocalizations get get {
    return AppLocalizations.of(rootContext)!;
  }
}
