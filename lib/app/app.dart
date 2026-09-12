import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class VyaparMitraApp extends StatelessWidget {
  const VyaparMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.onboarding,
      onGenerateRoute: AppRouter.generateRoute,
      supportedLocales: const [
        Locale('hi', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
    );
  }
}
