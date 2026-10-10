import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/shell/athlete_app_shell.dart';

class AthleteOSApp extends StatefulWidget {
  const AthleteOSApp({super.key});

  @override
  State<AthleteOSApp> createState() => _AthleteOSAppState();
}

class _AthleteOSAppState extends State<AthleteOSApp> {
  Locale _locale = const Locale('en');

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AthleteOS',
      theme: AppTheme.light,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AthleteAppShell(onLocaleChanged: _setLocale, locale: _locale),
    );
  }
}
