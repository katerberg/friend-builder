import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:friend_builder/services/app_shortcuts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String siriShortcutsTipSeenKey = 'siri_shortcuts_tip_seen';

/// One-time / Settings help for enabling Friend Builder Siri App Shortcuts.
class SiriShortcutsTip {
  static Future<bool> hasSeenTip() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(siriShortcutsTipSeenKey) ?? false;
  }

  static Future<void> markTipSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(siriShortcutsTipSeenKey, true);
  }

  /// Shows the tip once on iOS after the main app is visible, if not yet seen.
  static Future<void> maybeShowAfterOnboarding(BuildContext context) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    if (await hasSeenTip()) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await show(context);
  }

  static Future<void> show(BuildContext context) async {
    await markTipSeen();
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Talk to Siri'),
        content: const Text(
          'Friend Builder can log hangouts and tell you who you are overdue to see.\n\n'
          'Try phrases like:\n'
          '• “Log a hangout in Friend Builder”\n'
          '• “I hung out with Alex in Friend Builder”\n'
          '• “Who should I hang out with in Friend Builder”\n\n'
          'First, open Shortcuts → Friend Builder → turn on Siri. '
          'That switch is off by default.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AppShortcutsService.openShortcuts();
            },
            child: const Text('Open Shortcuts'),
          ),
        ],
      ),
    );
  }
}
