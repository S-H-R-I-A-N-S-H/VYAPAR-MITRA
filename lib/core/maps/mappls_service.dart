import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:mappls_gl/mappls_gl.dart';

/// Centralized service for configuring Mappls Maps in Vyapar Mitra.
class MapplsService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Default locality coordinates for Sanwer Block, Indore, MP
  static const LatLng defaultCenter = LatLng(22.9772, 75.8078);

  /// Checks if the current runtime environment supports native Mappls GL rendering.
  /// (Native MapLibre / Mappls binaries run on Android and iOS devices/emulators)
  static bool get isNativeMapSupported {
    if (kIsWeb) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Initializes Mappls SDK configuration flags.
  /// Gracefully catches MissingPluginException on desktop / test environments.
  static Future<void> initialize() async {
    if (_initialized) return;

    if (!isNativeMapSupported) {
      debugPrint('[MapplsService] Non-mobile or test environment detected. Native Mappls GL will use interactive tactile fallback.');
      _initialized = true;
      return;
    }

    try {
      await MapplsMapConfiguration.setShowLastSelectedStyle(true);
      await MapplsMapConfiguration.setDeveloperShowingSplash(false);
      debugPrint('[MapplsService] Mappls GL configuration initialized successfully.');
      _initialized = true;
    } catch (e) {
      debugPrint('[MapplsService] Warning: Mappls configuration skipped ($e)');
      _initialized = true;
    }
  }
}
