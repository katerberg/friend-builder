import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Switches the home-screen app icon to match the selected theme color.
///
/// iOS uses alternate icons (`AppIcon-<name>` asset catalogs); Android uses
/// launcher `<activity-alias>` entries. A null [iconName] restores the
/// default icon.
class AppIconService {
  static const MethodChannel _channel =
      MethodChannel('com.example.friend_builder/app_icon');

  static Future<void> setIcon(String? iconName) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setIcon', {'iconName': iconName});
    } on PlatformException catch (e) {
      debugPrint('Failed to set app icon: ${e.message}');
    } on MissingPluginException {
      // Native side not available (e.g. tests).
    }
  }
}
