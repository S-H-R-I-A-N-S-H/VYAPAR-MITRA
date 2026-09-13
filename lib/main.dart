import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/maps/mappls_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MapplsService.initialize();
  runApp(
    const ProviderScope(
      child: VyaparMitraApp(),
    ),
  );
}
