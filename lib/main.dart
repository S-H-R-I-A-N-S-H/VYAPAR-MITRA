import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/maps/mappls_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mappls SDK
  await MapplsService.initialize();

  // Initialize Supabase (configured with project defaults, overrideable via --dart-define)
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wjwaftgtujrqdrzjsrqe.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqd2FmdGd0dWpycWRyempzcnFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxNTAwNzMsImV4cCI6MjEwNDcyNjA3M30.wNLam3JN47Stdzmwpc5Sk7j-oSt12E89eCWve4rzkt0',
  );

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization notice: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: VyaparMitraApp(),
    ),
  );
}
