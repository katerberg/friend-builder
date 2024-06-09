import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MissingPermission extends StatelessWidget {
  final bool isWhite;
  final String permissionType;
  const MissingPermission(
      {super.key, required this.isWhite, this.permissionType = 'contacts'});

  void _handleContactPermissionRequest() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                "Missing $permissionType permission",
              )),
          ElevatedButton(
            style: isWhite
                ? null
                : ElevatedButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _handleContactPermissionRequest,
            child: const Text('Change Permissions'),
          )
        ],
      ),
    );
  }
}
