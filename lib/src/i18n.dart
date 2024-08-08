import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/rpass_localizations.dart';



class I18n {
  static RpassLocalizations? of(BuildContext context) {
    return RpassLocalizations.of(context);
  }

  static RpassLocalizations lookupLocalizations(Locale locale) {
    return lookupRpassLocalizations(locale);
  }

  static const LocalizationsDelegate<RpassLocalizations> delegate =
      RpassLocalizations.delegate;

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      RpassLocalizations.localizationsDelegates;

  static const List<Locale> supportedLocales =
      RpassLocalizations.supportedLocales;
}
