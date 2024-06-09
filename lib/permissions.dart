import 'package:permission_handler/permission_handler.dart';

class PermissionsUtils {
  Future<bool>? fetchingPermission;

  static Future<PermissionStatus?> _getPermission(
      Permission permissionType) async {
    final PermissionStatus permission = await permissionType.request();

    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.denied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [permissionType].request();
      return permissionStatus[permissionType];
    } else {
      return permission;
    }
  }

  Future<bool> isMissingPermission(Permission permissionType) async {
    if (fetchingPermission != null) {
      return fetchingPermission!;
    }
    final PermissionStatus? permissionStatus =
        await _getPermission(permissionType);
    fetchingPermission = null;
    if (permissionStatus == PermissionStatus.granted) {
      return false;
    } else {
      return true;
    }
  }
}
