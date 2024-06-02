import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MissingContactsPermission extends StatelessWidget {
  final bool isWhite;
  const MissingContactsPermission({super.key, required this.isWhite});

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
              child: const Text(
                'Missing contacts permission',
              )),
          OutlinedButton(
            style: isWhite
                ? null
                : OutlinedButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _handleContactPermissionRequest,
            child: const Text('Change Permissions'),
          )
        ],
      ),
    );
  }
}
