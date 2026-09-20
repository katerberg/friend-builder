import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS App Shortcuts bridge: refresh parameterized phrases and open Shortcuts.
class AppShortcutsService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.friend_builder/app_shortcuts',
  );

  /// Asks App Intents to re-index parameterized App Shortcut phrases.
  static Future<void> updateParameters() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('updateParameters');
    } on MissingPluginException {
      // Channel may be unavailable in tests or before SceneDelegate wires it.
    } catch (error) {
      if (kDebugMode) {
        print('AppShortcutsService.updateParameters failed: $error');
      }
    }
  }

  /// Opens the system Shortcuts app so the user can enable Siri for this app.
  static Future<bool> openShortcuts() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('openShortcuts') ?? false;
    } on MissingPluginException {
      return false;
    } catch (error) {
      if (kDebugMode) {
        print('AppShortcutsService.openShortcuts failed: $error');
      }
      return false;
    }
  }
}
