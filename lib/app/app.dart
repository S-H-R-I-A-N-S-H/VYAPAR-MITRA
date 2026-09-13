import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class VyaparMitraApp extends ConsumerWidget {
  const VyaparMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: currentLocale,
      initialRoute: AppRouter.welcome,
      onGenerateRoute: AppRouter.generateRoute,
      supportedLocales: const [
        Locale('hi', ''),
        Locale('en', ''),
        Locale('mr', ''),
        Locale('gu', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
    );
  }
}
