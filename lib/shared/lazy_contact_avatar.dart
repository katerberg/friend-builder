import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';

class LazyContactAvatar extends StatefulWidget {
  final Contact contact;
  final double? fontSize;
  final double? radius;

  const LazyContactAvatar({
    super.key,
    required this.contact,
    this.fontSize,
    this.radius,
  });

  @override
  State<LazyContactAvatar> createState() => _LazyContactAvatarState();
}

class _LazyContactAvatarState extends State<LazyContactAvatar> {
  Future<Uint8List?>? _photoFuture;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  void _loadPhoto() {
    if (widget.contact is EncodableContact) {
      final encodable = widget.contact as EncodableContact;
      if (encodable.avatar != null) {
        _photoFuture = Future.value(encodable.avatar);
        return;
      }
    } else if (widget.contact.photo != null) {
      _photoFuture = Future.value(widget.contact.photo);
      return;
    }

    _photoFuture = ContactPermissionService.getContactPhoto(widget.contact.id);
  }

  @override
  void didUpdateWidget(LazyContactAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contact.id != widget.contact.id) {
      _loadPhoto();
    }
  }

  String _getInitials() {
    final encodable = EncodableContact.fromContact(widget.contact);
    return encodable.initials();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        final double effectiveRadius = widget.radius ?? 20;
        final double effectiveFontSize =
            widget.fontSize ?? (effectiveRadius * 0.7);

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return CircleAvatar(
            radius: effectiveRadius,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _getInitials(),
              style: TextStyle(
                fontSize: effectiveFontSize,
                color: Colors.white,
              ),
            ),
          );
        }

        return CircleAvatar(
          radius: effectiveRadius,
          backgroundImage: MemoryImage(snapshot.data!),
        );
      },
    );
  }
}
