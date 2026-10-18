import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';
import 'application/app_locale_controller.dart';
import 'application/app_theme_controller.dart';
import 'router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/auth_controller.dart';

final _routerProvider = Provider((ref) {
  final locale = ref.watch(appLocaleControllerProvider);
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  final router = createAppRouter(
    locale: locale,
    onLocaleChanged: ref.read(appLocaleControllerProvider.notifier).setLocale,
    authState: () => ref.read(authControllerProvider),
    authRefresh: refresh,
  );
  ref.onDispose(router.dispose);
  ref.onDispose(refresh.dispose);
  return router;
});

class AthleteOSApp extends ConsumerWidget {
  const AthleteOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleControllerProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.app,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (context, child) {
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      themeMode:
          ref.watch(appThemeControllerProvider).asData?.value ??
          ThemeMode.system,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
