import 'package:flutter/material.dart';
import 'l10n/generated/localizations.dart';

class I18n {
  static MyLocalizations? of(BuildContext context) {
    return MyLocalizations.of(context);
  }

  static MyLocalizations lookupLocalizations(Locale locale) {
    return lookupMyLocalizations(locale);
  }

  static const LocalizationsDelegate<MyLocalizations> delegate =
      MyLocalizations.delegate;

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      MyLocalizations.localizationsDelegates;

  static const List<Locale> supportedLocales =
      MyLocalizations.supportedLocales;
}
